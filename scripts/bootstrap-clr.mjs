#!/usr/bin/env node

/**
 * CLR 自举验证脚本
 *
 * 执行 CLR 端的真实自举验收：
 *   1. 上一代编译器可用
 *   2. 源码 -> v1.clr
 *   3. v1.clr 本身可运行最小命令
 *   4. v1.clr -> v2.clr
 *   5. v1 / v2 可比较
 *
 * 流程：
 *   1. 用外部 seed 编译器编译 valkyrie.v/projects/legion.tools → v1
 *   2. 验证 v1 产物的 `--version` / `--help`
 *   3. 严格使用 `legion.tools` 产出的 `legion.exe` 再次编译同一份源码 → v2
 *   4. 比对 v1 与 v2 的产物
 *
 * 用法：
 *   node scripts/bootstrap-clr.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * seed 优先级：
 *   1. --legion / LEGION_PATH
 *   2. valkyrie.rs 构建的 legion.exe（target/release 或 target/debug）
 *   3. NyarVM.cs 自动构建的上一代 legion
 *
 * 当前状态：
 *   - 本脚本用于“诚实失败”的真实验收，不再把半完成状态记为成功
 *   - 只要任一门未通过、未执行或比对跳过，脚本都会返回非零退出码
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

import {
    BOOTSTRAP_PROJECT,
    REMOVED_MICRO_COMPILER_PROJECT,
    collectFiles,
    computeDirHash,
    computeFileHash,
    createGate,
    findLegion,
    printGateSummary,
    repoRootFrom,
    resolveLegionLauncher,
    shortenText,
    validateModuleSystem,
    writeReport,
} from './bootstrap-lib.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');
const LEVEL2_SKIPPED_REASON = '由于上游门禁未通过，`v1.clr -> v2.clr` 未执行。';

const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = 'clr-microsoft-unknown-managed';
const MODULE_GUARD_SKIPPED_REASON = '由于模块系统前置门未通过，`seed -> v1.clr` 未执行。';

// ─────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: options.silent ? 'pipe' : 'inherit',
            env: options.env ? { ...process.env, ...options.env } : process.env,
        });
        return { success: true, stdout: result || '' };
    } catch (error) {
        return {
            success: false,
            stdout: error.stdout || '',
            stderr: error.stderr || error.message || '',
        };
    }
}

function legionLauncherCandidates(baseDir) {
    return [
        path.join(baseDir, 'legion.exe'),
        path.join(baseDir, 'legion'),
        path.join(baseDir, 'legion.dll'),
    ];
}

function resolveLegionLauncher(baseDir) {
    for (const candidate of legionLauncherCandidates(baseDir)) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }

    return null;
}

/** seed 当前把产物直接写到 `-o` 目录；旧布局为 `{out}/{targetTriple}/legion.exe`。 */
function resolveClrArtifactDir(outputDir) {
    const legacyDir = path.join(outputDir, TARGET_TRIPLE);
    if (fs.existsSync(legacyDir)) {
        return legacyDir;
    }
    return outputDir;
}

/**
 * 解析自举 CLI 入口：优先 `legion.exe`，其次多分区命名 `legion__main_legion.exe`。
 */
function resolveBuiltLegionCli(artifactDir) {
    const preferred = ['legion.exe', 'legion__main_legion.exe', 'legion.dll', 'legion__main_legion.dll'];
    for (const name of preferred) {
        const candidate = path.join(artifactDir, name);
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }

    if (!fs.existsSync(artifactDir)) {
        return null;
    }

    const files = fs
        .readdirSync(artifactDir)
        .filter((name) => /^legion.+\.(exe|dll)$/i.test(name) && !/__(?:vcc|voa)/i.test(name))
        .sort();
    const mainEntry = files.find((name) => /main_legion/i.test(name));
    if (mainEntry) {
        return path.join(artifactDir, mainEntry);
    }
    return files[0] ? path.join(artifactDir, files[0]) : null;
}

function resolveBuiltLegionMsil(artifactDir, legionExe) {
    if (!legionExe) {
        return path.join(artifactDir, 'legion.msil');
    }
    const stem = path.basename(legionExe).replace(/\.(exe|dll)$/i, '');
    const preferred = [path.join(artifactDir, `${stem}.msil`), path.join(artifactDir, 'legion.msil')];
    for (const candidate of preferred) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return preferred[0];
}

function ensurePreviousLegion(outputRoot, verbose) {
    const existing = findLegion(ROOT_DIR, VALKYRIE_RS_DIR, NYARVM_DIR);
    if (existing) {
        return existing;
    }

    if (!fs.existsSync(NYARVM_DIR) || !fs.existsSync(LEGION_CSPROJ)) {
        return null;
    }

    const toolOutputDir = path.join(outputRoot, '_previous_legion');
    if (fs.existsSync(toolOutputDir)) {
        fs.rmSync(toolOutputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(toolOutputDir, { recursive: true });

    console.log('未找到现成的上一代 legion，正在从 NyarVM.cs 构建...');
    const publishResult = runCommand(
        `dotnet publish "${LEGION_CSPROJ}" -c Release --nologo -o "${toolOutputDir}" -p:UseAppHost=true`,
        { cwd: NYARVM_DIR, silent: !verbose, timeout: 300000 }
    );

    if (!publishResult.success) {
        console.error('错误：自动构建上一代 legion 失败');
        if (publishResult.stderr) {
            console.error(publishResult.stderr.slice(0, 4000));
        }
        return null;
    }

    return resolveLegionLauncher(toolOutputDir);
}

function collectFiles(dir, extensions) {
    const results = [];
    if (!fs.existsSync(dir)) {
        return results;
    }
    const extSet = new Set(extensions.map(e => e.toLowerCase()));
    for (const entry of fs.readdirSync(dir, { withFileTypes: true, recursive: true })) {
        if (!entry.isFile()) {
            continue;
        }
        const ext = path.extname(entry.name).toLowerCase();
        if (extSet.has(ext)) {
            results.push(path.join(entry.parentPath || entry.path, entry.name));
        }
    }
    return results.sort();
}

function computeFileHash(filePath) {
    const content = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(content).digest('hex');
}

function computeDirHash(dir, extensions) {
    const files = collectFiles(dir, extensions);
    if (files.length === 0) {
        return null;
    }
    const hash = crypto.createHash('sha256');
    for (const file of files) {
        hash.update(path.relative(dir, file));
        hash.update('\0');
        hash.update(computeFileHash(file));
        hash.update('\0');
    }
    return hash.digest('hex');
}

function shortenText(value, maxChars = 240) {
    const text = String(value || '').trim();
    if (text.length <= maxChars) {
        return text;
    }
    return `${text.slice(0, maxChars)}...`;
}

function createGate(name, status, detail) {
    return { name, status, detail };
}

function printGateSummary(gates) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  门级状态');
    console.log('══════════════════════════════════════════════════\n');

    for (const gate of gates) {
        console.log(`- ${gate.name}：${gate.status}`);
        if (gate.detail) {
            console.log(`  ${gate.detail}`);
        }
    }
}

function writeReport(outputRoot, payload) {
    fs.mkdirSync(outputRoot, { recursive: true });
    const reportPath = path.join(outputRoot, 'bootstrap-report.json');
    fs.writeFileSync(reportPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
    return reportPath;
}

function escapeRegex(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function hasWorkspaceDependency(manifestText, dependencyName) {
    const pattern = new RegExp(`"${escapeRegex(dependencyName)}"\\s*:\\s*\\{[\\s\\S]*?version\\s*:\\s*"workspace"`, 'm');
    return pattern.test(manifestText);
}

function workspaceIncludesMember(workspaceText, memberPath) {
    const pattern = new RegExp(`"${escapeRegex(memberPath)}"`);
    return pattern.test(workspaceText);
}

function validateModuleSystem(verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  模块系统前置门');
    console.log('══════════════════════════════════════════════════\n');

    const paths = {
        workspaceManifest: path.join(ROOT_DIR, 'legions.von'),
        legionToolsManifest: path.join(ROOT_DIR, 'projects', 'legion.tools', 'legion.von'),
        nyarManifest: path.join(ROOT_DIR, 'projects', 'nyar', 'legion.von'),
        stdManifest: path.join(ROOT_DIR, 'projects', 'std', 'legion.von'),
        buildContext: path.join(ROOT_DIR, 'projects', 'legion.tools', 'source', 'build_context.v'),
    };
    const removedMicroCompilerDir = path.join(ROOT_DIR, 'projects', 'micro_compiler');

    const errors = [];
    for (const [name, filePath] of Object.entries(paths)) {
        if (!fs.existsSync(filePath)) {
            errors.push(`缺少必要文件：${name} -> ${filePath}`);
        }
    }
    if (errors.length > 0) {
        return { success: false, errors };
    }

    const workspaceText = fs.readFileSync(paths.workspaceManifest, 'utf8');
    const legionToolsText = fs.readFileSync(paths.legionToolsManifest, 'utf8');
    const nyarText = fs.readFileSync(paths.nyarManifest, 'utf8');
    const stdText = fs.readFileSync(paths.stdManifest, 'utf8');
    const buildContextText = fs.readFileSync(paths.buildContext, 'utf8');

    if (!/name\s*:\s*"legion\.tools"/.test(legionToolsText)) {
        errors.push('`projects/legion.tools/legion.von` 的 `name` 不是 `legion.tools`');
    }
    if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*false[\s\S]*?\}/m.test(legionToolsText)) {
        errors.push('`legion.tools` 未保持 `auto_link: { core: true, std: false }`');
    }
    for (const dependencyName of ['nyar', 'std', 'std.data.text.von']) {
        if (!hasWorkspaceDependency(legionToolsText, dependencyName)) {
            errors.push(`` + '`legion.tools` 缺少显式 workspace 依赖：' + dependencyName);
        }
    }

    if (!/name\s*:\s*"nyar"/.test(nyarText)) {
        errors.push('`projects/nyar/legion.von` 的 `name` 不是 `nyar`');
    }
    if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*true[\s\S]*?\}/m.test(nyarText)) {
        errors.push('`nyar` 未保持 `auto_link: { core: true, std: true }`');
    }
    if (!/name\s*:\s*"std"/.test(stdText)) {
        errors.push('`projects/std/legion.von` 的 `name` 不是 `std`');
    }

    for (const memberPath of ['projects/legion.tools', 'projects/nyar', 'projects/std', 'examples/test.module_system']) {
        if (!workspaceIncludesMember(workspaceText, memberPath)) {
            errors.push(`workspace 未显式包含成员：${memberPath}`);
        }
    }
    if (workspaceIncludesMember(workspaceText, REMOVED_MICRO_COMPILER_PROJECT)) {
        errors.push(`workspace 仍包含已废弃项目：${REMOVED_MICRO_COMPILER_PROJECT}`);
    }
    if (fs.existsSync(removedMicroCompilerDir)) {
        errors.push(`已废弃作弊工程仍存在：${removedMicroCompilerDir}`);
    }

    if (!buildContextText.includes('using nyar;')) {
        errors.push('`build_context.v` 未显式 `using nyar;`');
    }
    for (const requiredSymbol of [
        'micro legion_parse_canonical_target(target: utf8) -> CanonicalTarget {',
        'return parse_target(canonical)',
        'return format_target(parsed)',
        'return default_target()',
    ]) {
        if (!buildContextText.includes(requiredSymbol)) {
            errors.push(`build_context 缺少模块系统契约片段：${requiredSymbol}`);
        }
    }

    if (verbose) {
        console.log(`workspace manifest: ${paths.workspaceManifest}`);
        console.log(`legion.tools manifest: ${paths.legionToolsManifest}`);
        console.log(`nyar manifest: ${paths.nyarManifest}`);
        console.log(`std manifest: ${paths.stdManifest}`);
        console.log(`build context: ${paths.buildContext}`);
    }

    if (errors.length > 0) {
        console.log('模块系统前置门失败：');
        for (const error of errors) {
            console.log(`  - ${error}`);
        }
        return { success: false, errors };
    }

    console.log('模块系统前置门通过：');
    console.log('  - `legion.tools` 已显式依赖 `nyar`、`std`、`std.data.text.von`');
    console.log('  - workspace 已显式包含 `legion.tools` / `nyar` / `std` / `test.module_system`');
    console.log('  - `micro_compiler` 已从 workspace 与源码树中移除');
    console.log('  - `build_context.v` 通过 `using nyar;` 显式导入跨模块类型与函数');
    return {
        success: true,
        errors: [],
        detail: '`legion.tools -> nyar/std` 模块依赖、workspace 成员、`micro_compiler` 清退与显式导入契约均已满足',
    };
}

// ─────────────────────────────────────────────────────────────
// Level 1：源码 → v1.clr
// ─────────────────────────────────────────────────────────────

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.clr');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);
    let targetDir = resolveClrArtifactDir(outputDir);
    let legionExe = resolveBuiltLegionCli(targetDir);
    let legionMsil = resolveBuiltLegionMsil(targetDir, legionExe);

    // 验证上一代编译器可用
    const versionCheck = runCommand(`"${legionPath}" --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        console.error('错误：上一代编译器不可用');
        console.error(versionCheck.stderr);
        return {
            success: false,
            stage: 'previous_compiler_check',
            error: shortenText(versionCheck.stderr || versionCheck.stdout || '上一代编译器不可用'),
            outputDir: targetDir,
            legionExe: legionExe || path.join(targetDir, 'legion.exe'),
            legionMsil: legionMsil || path.join(targetDir, 'legion.msil'),
            artifacts: [],
            hash: null,
            runtime: {
                version: { success: false, stdout: '', stderr: '' },
                help: { success: false, stdout: '', stderr: '' },
            },
        };
    }
    console.log(`上一代编译器版本：${versionCheck.stdout.trim()}`);

    // 清理旧产物
    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    // 执行编译
    console.log('\n编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target clr -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000 }
    );

    targetDir = resolveClrArtifactDir(outputDir);
    legionExe = resolveBuiltLegionCli(targetDir);
    legionMsil = resolveBuiltLegionMsil(targetDir, legionExe);

    if (!buildResult.success) {
        console.error('错误：v1 编译失败');
        if (buildResult.stderr) {
            console.error(buildResult.stderr.slice(0, 2000));
        }
        return {
            success: false,
            stage: 'source_to_v1',
            error: shortenText(buildResult.stderr || buildResult.stdout || 'v1 编译失败'),
            outputDir: targetDir,
            legionExe: legionExe || path.join(targetDir, 'legion.exe'),
            legionMsil: legionMsil || path.join(targetDir, 'legion.msil'),
            artifacts: [],
            hash: null,
            runtime: {
                version: { success: false, stdout: '', stderr: '' },
                help: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 检查产物
    if (!legionExe || !fs.existsSync(legionExe)) {
        console.error(`错误：v1 产物不存在：${path.join(targetDir, 'legion.exe')}（或 legion__main_legion.exe）`);
        return {
            success: false,
            stage: 'v1_artifact',
            error: `v1 产物不存在：${path.join(targetDir, 'legion.exe')}`,
            outputDir: targetDir,
            legionExe: path.join(targetDir, 'legion.exe'),
            legionMsil: legionMsil || path.join(targetDir, 'legion.msil'),
            artifacts: [],
            hash: null,
            runtime: {
                version: { success: false, stdout: '', stderr: '' },
                help: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 验证 v1 产物可运行
    console.log('\n验证 v1 产物...');
    const v1VersionCheck = runCommand(`dotnet "${legionExe}" --version`, { silent: true, timeout: 10000 });
    if (v1VersionCheck.success) {
        console.log(`  v1 --version：${v1VersionCheck.stdout.trim()}`);
    } else {
        console.error(`  警告：v1 --version 失败：${v1VersionCheck.stderr?.slice(0, 300)}`);
    }

    const v1HelpCheck = runCommand(`dotnet "${legionExe}" --help`, { silent: true, timeout: 10000 });
    if (v1HelpCheck.success) {
        console.log('  v1 --help：退出码 0');
    } else {
        console.error(`  警告：v1 --help 失败`);
    }

    // 收集 v1 产物清单
    const v1Artifacts = collectFiles(targetDir, ['.exe', '.dll', '.msil', '.json', '.pdb', '.txt']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'source_to_v1',
        outputDir: targetDir,
        legionExe,
        legionMsil,
        artifacts: v1Artifacts,
        hash: computeDirHash(targetDir, ['.msil']),
        runtime: {
            version: v1VersionCheck,
            help: v1HelpCheck,
        },
    };
}

// ─────────────────────────────────────────────────────────────
// Level 2：v1.clr → v2.clr
// ─────────────────────────────────────────────────────────────

function compileV2(v1Result, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.clr → v2.clr');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`v1 编译器：${v1Result.legionExe}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildResult = runCommand(
        `dotnet "${v1Result.legionExe}" build "${BOOTSTRAP_PROJECT_DIR}" --target clr -o "${outputDir}"`,
        {
            cwd: ROOT_DIR,
            timeout: 300000,
        }
    );

    const targetDir = resolveClrArtifactDir(outputDir);
    const legionExe = resolveBuiltLegionCli(targetDir);
    const legionMsil = resolveBuiltLegionMsil(targetDir, legionExe);

    if (!buildResult.success) {
        console.error('错误：v2 编译失败');
        if (buildResult.stderr) {
            console.error(buildResult.stderr.slice(0, 2000));
        }
        return {
            success: false,
            stage: 'v1_to_v2',
            error: shortenText(buildResult.stderr || buildResult.stdout || 'v2 编译失败'),
            outputDir: targetDir,
            legionExe: legionExe || path.join(targetDir, 'legion.exe'),
            legionMsil: legionMsil || path.join(targetDir, 'legion.msil'),
            artifacts: [],
            hash: null,
        };
    }

    if (!legionExe || !fs.existsSync(legionExe)) {
        console.error(`错误：v2 产物不存在：${path.join(targetDir, 'legion.exe')}（或 legion__main_legion.exe）`);
        return {
            success: false,
            stage: 'v2_artifact',
            error: `v2 产物不存在：${path.join(targetDir, 'legion.exe')}`,
            outputDir: targetDir,
            legionExe: path.join(targetDir, 'legion.exe'),
            legionMsil: legionMsil || path.join(targetDir, 'legion.msil'),
            artifacts: [],
            hash: null,
        };
    }

    const v2Artifacts = collectFiles(targetDir, ['.exe', '.dll', '.msil', '.json', '.pdb', '.txt']);
    console.log(`v2 产物清单（${v2Artifacts.length} 个文件）：`);
    for (const artifact of v2Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'v1_to_v2',
        outputDir: targetDir,
        legionExe,
        legionMsil,
        artifacts: v2Artifacts,
        hash: computeDirHash(targetDir, ['.msil']),
    };
}

// ─────────────────────────────────────────────────────────────
// 比对
// ─────────────────────────────────────────────────────────────

// v1 / v2 比对规则（固化结论）
//
// 必须比对（不一致则阻断）：
//   - .msil 文件：核心 IL 产物，是自举一致性的唯一判定依据
//   - run-contract.txt：运行契约，必须完全一致
//
// 允许差异（不阻断）：
//   - .exe / .dll：PE 包装含非确定性 MVID、时间戳、GUID
//   - .pdb：调试符号含非确定性时间戳和源文件路径
//   - .runtimeconfig.json：框架版本字符串可能因 SDK 版本不同而变化
//   - .deps.json：依赖图结构可能因解析顺序不同而变化
//
// 阻断条件：
//   - 任一 .msil 文件哈希不一致 → 阻断
//   - run-contract.txt 不一致 → 阻断
//   - 产物清单结构不一致（多了或少了 .msil 文件）→ 阻断

function compareArtifacts(v1Result, v2Result) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');

    if (!v1Result || !v2Result || !v2Result.success) {
        console.log('比对跳过：v1 或 v2 产物缺失');
        return { match: false, skipped: true };
    }

    // 必须比对的扩展名
    const mustCompareExtensions = ['.msil'];
    // 必须比对的特定文件
    const mustCompareFiles = ['run-contract.txt'];
    // 允许差异的扩展名（不参与比对，但也不阻断）
    const allowedDiffExtensions = ['.exe', '.dll', '.pdb', '.json'];

    console.log('比对规则：');
    console.log('  必须一致：.msil 文件、run-contract.txt');
    console.log('  允许差异：.exe、.dll、.pdb、.json（含非确定性元数据）');
    console.log('');

    // 收集必须比对的 .msil 文件
    const v1MsilFiles = collectFiles(v1Result.outputDir, mustCompareExtensions);
    const v2MsilFiles = collectFiles(v2Result.outputDir, mustCompareExtensions);

    const v1MsilNames = new Set(v1MsilFiles.map(f => path.basename(f)));
    const v2MsilNames = new Set(v2MsilFiles.map(f => path.basename(f)));

    let allMatch = true;
    const details = [];

    // 检查 .msil 文件清单一致性
    const onlyInV1 = [...v1MsilNames].filter(n => !v2MsilNames.has(n));
    const onlyInV2 = [...v2MsilNames].filter(n => !v1MsilNames.has(n));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的 .msil 文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的 .msil 文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    // 逐文件比对 .msil 哈希
    const common = [...v1MsilNames].filter(n => v2MsilNames.has(n));
    for (const name of common) {
        const v1File = v1MsilFiles.find(f => path.basename(f) === name);
        const v2File = v2MsilFiles.find(f => path.basename(f) === name);
        if (v1File && v2File) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${name}：哈希不一致`);
                console.log(`    v1: ${h1}`);
                console.log(`    v2: ${h2}`);
                details.push({ type: 'msil_hash_mismatch', file: name, v1Hash: h1, v2Hash: h2 });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：一致`);
            }
        }
    }

    // 比对 run-contract.txt
    for (const fileName of mustCompareFiles) {
        const v1File = path.join(v1Result.outputDir, fileName);
        const v2File = path.join(v2Result.outputDir, fileName);

        const v1Exists = fs.existsSync(v1File);
        const v2Exists = fs.existsSync(v2File);

        if (v1Exists && v2Exists) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${fileName}：不一致`);
                details.push({ type: 'contract_mismatch', file: fileName });
                allMatch = false;
            } else {
                console.log(`  [通过] ${fileName}：一致`);
            }
        } else if (v1Exists !== v2Exists) {
            console.log(`  [阻断] ${fileName}：${v1Exists ? '仅 v1 存在' : '仅 v2 存在'}`);
            details.push({ type: 'contract_missing', file: fileName });
            allMatch = false;
        }
    }

    // 信息：列出允许差异的文件
    const allowedFiles = collectFiles(v1Result.outputDir, allowedDiffExtensions);
    if (allowedFiles.length > 0) {
        console.log(`\n允许差异的文件（${allowedFiles.length} 个，不参与比对）：`);
        for (const f of allowedFiles) {
            console.log(`  ${path.relative(v1Result.outputDir, f)}`);
        }
    }

    return { match: allMatch, skipped: false, details };
}

// ─────────────────────────────────────────────────────────────
// 主入口
// ─────────────────────────────────────────────────────────────

function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        legion: null,
        output: null,
        verbose: false,
    };

    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--legion':
                options.legion = args[++i];
                break;
            case '--output':
            case '-o':
                options.output = args[++i];
                break;
            case '--verbose':
            case '-v':
                options.verbose = true;
                break;
            case '--help':
            case '-h':
                console.log(`
CLR 自举验证脚本

用法：node scripts/bootstrap-clr.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-clr）
  --verbose, -v       详细输出
  --help, -h          显示帮助信息
`);
                process.exit(0);
        }
    }

    return options;
}

function main() {
    const options = parseArgs();
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-clr'));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             CLR 自举验证                                ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    const moduleSystemResult = validateModuleSystem(options.verbose);
    if (!moduleSystemResult.success) {
        const gates = [
            createGate('模块系统前置门', '未通过', shortenText(moduleSystemResult.errors.join('；'), 400)),
            createGate('上一代编译器入口', '跳过', '模块系统前置门未通过'),
            createGate('源码 -> v1.clr', '跳过', MODULE_GUARD_SKIPPED_REASON),
            createGate('v1 --version', '跳过', '源码 -> v1.clr 未执行'),
            createGate('v1 --help', '跳过', '源码 -> v1.clr 未执行'),
            createGate('v1 -> v2.clr', '跳过', LEVEL2_SKIPPED_REASON),
            createGate('v1 / v2 比对', '跳过', '由于上游门禁未通过，比对未执行'),
        ];
        const blockers = moduleSystemResult.errors.map(error => `模块系统前置门失败：${error}`);
        const reportPath = writeReport(outputRoot, {
            success: false,
            gates,
            blockers,
            previousLegion: null,
            moduleSystem: moduleSystemResult,
            v1: { success: false, outputDir: null, hash: null, runtime: { version: false, help: false } },
            v2: { attempted: false, success: false, outputDir: null, compared: false, match: false, reason: LEVEL2_SKIPPED_REASON },
        });
        printGateSummary(gates);
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    // 查找 legion
    const autoBuiltLegionRoot = path.join(outputRoot, '_previous_legion');
    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        const gates = [
            createGate('模块系统前置门', '通过', moduleSystemResult.detail),
            createGate('上一代编译器入口', '未通过', '未找到可用 `legion`，且无法从 `NyarVM.cs` 自动构建'),
            createGate('源码 -> v1.clr', '跳过', '上一代编译器入口未就绪'),
            createGate('v1 --version', '跳过', '源码 -> v1.clr 未完成'),
            createGate('v1 --help', '跳过', '源码 -> v1.clr 未完成'),
            createGate('v1 -> v2.clr', '跳过', LEVEL2_SKIPPED_REASON),
            createGate('v1 / v2 比对', '跳过', '由于上游门禁未通过，比对未执行'),
        ];
        const blockers = ['上一代编译器入口未就绪'];
        const reportPath = writeReport(outputRoot, { gates, blockers, success: false, previousLegion: null, moduleSystem: moduleSystemResult });
        printGateSummary(gates);
        console.error('\n错误：找不到上一代 legion CLI');
        console.error('请设置 --legion / LEGION_PATH，或保证 NyarVM.cs 可用以便脚本自动构建上一代 legion');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const previousCompilerDetail = legionPath.startsWith(autoBuiltLegionRoot)
        ? '已从 `NyarVM.cs` 自动构建上一代 `legion`'
        : `使用现成入口：${legionPath}`;

    // Level 1：源码 → v1.clr
    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    if (v1Result.success) {
        console.log('\nLevel 1（源码 → v1.clr）成功');
        console.log(`v1 产物目录：${v1Result.outputDir}`);
        console.log(`v1 .msil 哈希：${v1Result.hash}`);
    } else {
        console.error('\nLevel 1（源码 → v1.clr）失败');
    }

    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v1RuntimePassed = v1VersionPassed && v1HelpPassed;

    // Level 2：v1.clr → v2.clr
    const v2Result = v1RuntimePassed ? compileV2(v1Result, v2OutputDir, options.verbose) : null;

    // 比对
    const compareResult = compareArtifacts(v1Result, v2Result);

    console.log('\n══════════════════════════════════════════════════');
    console.log('  自举验证总结');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器入口：通过`);
    console.log(`模块系统前置门：${moduleSystemResult.success ? '通过' : '未通过'}`);
    console.log(`源码 -> v1.clr：${v1Result.success ? '通过' : '未通过'}`);
    console.log(`v1 --version：${v1Result.success ? (v1VersionPassed ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 --help：${v1Result.success ? (v1HelpPassed ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 -> v2.clr：${v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 / v2 比对：${compareResult.skipped ? '跳过' : (compareResult.match ? '一致' : '不一致')}`);

    const blockers = [];
    if (!v1Result.success) {
        blockers.push(`源码 -> v1 失败：${v1Result.error}`);
    }
    if (!v1VersionPassed) {
        blockers.push('v1 --version 仍失败');
    }
    if (!v1HelpPassed) {
        blockers.push('v1 --help 仍失败');
    }
    if (!v2Result) {
        blockers.push('v1 -> v2 未执行：上游门禁未通过');
    } else if (!v2Result.success) {
        blockers.push(`v1 -> v2 失败：${v2Result.error}`);
    } else if (compareResult.skipped) {
        blockers.push('v1 / v2 比对被跳过');
    } else if (!compareResult.match) {
        blockers.push('v1 / v2 产物比对不一致');
    }

    const gates = [
        createGate('模块系统前置门', moduleSystemResult.success ? '通过' : '未通过', moduleSystemResult.detail || shortenText(moduleSystemResult.errors.join('；'), 400)),
        createGate('上一代编译器入口', '通过', previousCompilerDetail),
        createGate('源码 -> v1.clr', v1Result.success ? '通过' : '未通过', v1Result.success ? `产物目录：${v1Result.outputDir}` : v1Result.error),
        createGate('v1 --version', v1Result.success ? (v1VersionPassed ? '通过' : '未通过') : '跳过', v1Result.success ? (v1VersionPassed ? '退出码 0' : shortenText(v1Result.runtime?.version?.stderr || v1Result.runtime?.version?.stdout || '执行失败')) : '源码 -> v1.clr 未通过'),
        createGate('v1 --help', v1Result.success ? (v1HelpPassed ? '通过' : '未通过') : '跳过', v1Result.success ? (v1HelpPassed ? '退出码 0' : shortenText(v1Result.runtime?.help?.stderr || v1Result.runtime?.help?.stdout || '执行失败')) : '源码 -> v1.clr 未通过'),
        createGate(
            'v1 -> v2.clr',
            v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过',
            v2Result ? (v2Result.success ? `产物目录：${v2Result.outputDir}` : v2Result.error) : '由于 `v1` 运行门未通过，第二轮编译未执行'
        ),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? '由于 `v1 -> v2` 未完成，比对未执行' : (compareResult.match ? '`.msil` 与 `run-contract.txt` 一致' : '产物比对不一致')),
    ];

    const reportPath = writeReport(outputRoot, {
        success: blockers.length === 0,
        gates,
        blockers,
        previousLegion: legionPath,
        moduleSystem: moduleSystemResult,
        v1: {
            success: v1Result.success,
            outputDir: v1Result.outputDir,
            hash: v1Result.hash,
            runtime: {
                version: v1VersionPassed,
                help: v1HelpPassed,
            },
        },
        v2: {
            attempted: Boolean(v2Result),
            success: Boolean(v2Result?.success),
            outputDir: v2Result?.outputDir || null,
            compared: !compareResult.skipped,
            match: compareResult.match,
            reason: v2Result ? (v2Result.success ? null : v2Result.error) : LEVEL2_SKIPPED_REASON,
        },
    });

    printGateSummary(gates);
    console.log(`\n报告已写入：${reportPath}`);

    if (blockers.length > 0) {
        console.log('\n当前仍未满足真实自举验收，阻断项如下：');
        for (const blocker of blockers) {
            console.log(`  - ${blocker}`);
        }
        process.exit(1);
    }

    process.exit(0);
}

main();
