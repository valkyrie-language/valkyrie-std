#!/usr/bin/env node

/**
 * WASM 自举验证脚本
 *
 * 执行 WASM 端的真实自举验收：
 *   1. 上一代编译器可用
 *   2. 源码 -> v1.wasm
 *   3. v1 入口命名契约正确（`legion.mjs` / `legion.wasm`）
 *   4. v1 产物本身可运行最小命令
 *   5. v1.wasm -> v2.wasm
 *   6. v1 / v2 可比较
 *
 * 流程：
 *   1. 用上一代编译器（NyarVM.cs legion）编译 valkyrie.v/projects/legion.tools → v1
 *   2. 检查构建日志中是否仍复现旧的 `manifest.v` 解析错误
 *   3. 检查 v1 产物是否为正确入口名 `legion.*`
 *   4. 验证 v1 产物的 `--version` / `--help`
 *   5. 用 v1 产物再次编译同一份源码 → v2
 *   6. 比对 v1 与 v2 的产物
 *
 * 用法：
 *   node scripts/bootstrap-wasm.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * 当前状态：
 *   - 本脚本用于“诚实失败”的真实验收，不再把半完成状态记为成功
 *   - 当前正确产物名应为 `legion.mjs` / `legion.wasm`
 *   - 若实际仍输出 `legion_tools.*`，脚本会把它标记为已知错误产物，而不是误记为通过
 *   - 当前脚本仅用于实验性排查，不属于 `CLR / NuGet` 源头自举发布门
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]):\//, '$1:/'));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

// ─────────────────────────────────────────────────────────────
// 配置
// ─────────────────────────────────────────────────────────────

const BOOTSTRAP_PROJECT = 'projects/legion.tools';
const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = 'wasm32-unknown-web-webassembly';
const EXPECTED_ENTRY_BASENAME = 'legion';
const LEGACY_ENTRY_BASENAME = 'legion_tools';
const MANIFEST_PARSE_ERROR_PATTERN = /projects[\\/]+legion\.tools[\\/]+source[\\/]+manifest\.v/i;

// ─────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: 'pipe',
        });
        return { success: true, stdout: normalizeCommandText(result), stderr: '' };
    } catch (error) {
        return {
            success: false,
            stdout: normalizeCommandText(error.stdout),
            stderr: normalizeCommandText(error.stderr || error.message || ''),
        };
    }
}

function normalizeCommandText(value) {
    if (!value) {
        return '';
    }
    if (typeof value === 'string') {
        return value;
    }
    if (Buffer.isBuffer(value)) {
        return value.toString('utf8');
    }
    return String(value);
}

function combineCommandOutput(result) {
    return [normalizeCommandText(result?.stdout), normalizeCommandText(result?.stderr)]
        .filter(Boolean)
        .join('\n')
        .trim();
}

function shortenText(text, maxChars = 300) {
    const normalized = normalizeCommandText(text).trim();
    if (!normalized) {
        return '';
    }
    if (normalized.length <= maxChars) {
        return normalized;
    }
    return `${normalized.slice(0, maxChars)}...`;
}

function printVerboseExcerpt(title, text, verbose, maxChars = 4000) {
    if (!verbose) {
        return;
    }

    const normalized = normalizeCommandText(text).trim();
    if (!normalized) {
        return;
    }

    console.log(`\n${title}：`);
    if (normalized.length <= maxChars) {
        console.log(normalized);
        return;
    }

    console.log(`${normalized.slice(0, maxChars)}\n...<输出已截断>...`);
}

function hasManifestParseError(output) {
    return MANIFEST_PARSE_ERROR_PATTERN.test(output);
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

function findLegion() {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidates = [
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion')),
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion-tool')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Release', 'net10.0')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Debug', 'net10.0')),
    ];
    for (const c of candidates) {
        if (fs.existsSync(c)) {
            return c;
        }
    }
    return null;
}

function ensurePreviousLegion(outputRoot, verbose) {
    const existing = findLegion();
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

// ─────────────────────────────────────────────────────────────
// Level 1：源码 → v1.wasm
// ─────────────────────────────────────────────────────────────

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.wasm');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);

    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    const legionMjs = path.join(targetDir, `${EXPECTED_ENTRY_BASENAME}.mjs`);
    const legionWasm = path.join(targetDir, `${EXPECTED_ENTRY_BASENAME}.wasm`);
    const legacyLegionMjs = path.join(targetDir, `${LEGACY_ENTRY_BASENAME}.mjs`);
    const legacyLegionWasm = path.join(targetDir, `${LEGACY_ENTRY_BASENAME}.wasm`);

    const result = {
        success: false,
        outputDir: targetDir,
        legionMjs,
        legionWasm,
        legacyLegionMjs,
        legacyLegionWasm,
        artifacts: [],
        hash: null,
        blockers: [],
        build: {
            versionCheck: null,
            buildResult: null,
            output: '',
            manifestParseErrorFound: false,
        },
        runtime: {
            mode: null,
            entryPath: null,
            version: null,
            help: null,
        },
    };

    const versionCheck = runCommand(`"${legionPath}" --version`, { timeout: 10000 });
    result.build.versionCheck = versionCheck;
    if (!versionCheck.success) {
        console.error('错误：上一代编译器不可用');
        console.error(versionCheck.stderr);
        result.blockers.push('上一代编译器不可用');
        return result;
    }
    console.log(`上一代编译器版本：${versionCheck.stdout.trim()}`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    console.log('\n编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target wasm -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000 }
    );
    result.build.buildResult = buildResult;
    result.build.output = combineCommandOutput(buildResult);
    result.build.manifestParseErrorFound = hasManifestParseError(result.build.output);

    if (result.build.manifestParseErrorFound) {
        console.error('错误：本次构建日志仍复现 `projects/legion.tools/source/manifest.v` 相关错误');
        result.blockers.push('构建日志仍含 `projects/legion.tools/source/manifest.v` 相关错误');
    } else {
        console.log('构建日志检查：本次未发现 `projects/legion.tools/source/manifest.v` 解析错误');
    }

    printVerboseExcerpt('构建日志摘录', result.build.output, verbose);

    if (!buildResult.success) {
        console.error('错误：v1 编译失败');
        const failureOutput = shortenText(result.build.output, 2000);
        if (failureOutput) {
            console.error(failureOutput);
        }
        result.blockers.push('v1 编译失败');
        return result;
    }

    const v1Artifacts = collectFiles(targetDir, ['.wasm', '.mjs', '.txt']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    result.artifacts = v1Artifacts;
    result.hash = computeDirHash(targetDir, ['.wasm']);

    const hasExpectedMjs = fs.existsSync(legionMjs);
    const hasExpectedWasm = fs.existsSync(legionWasm);
    const hasLegacyMjs = fs.existsSync(legacyLegionMjs);
    const hasLegacyWasm = fs.existsSync(legacyLegionWasm);

    if (!hasExpectedMjs || !hasExpectedWasm) {
        console.error('\n错误：v1 入口命名契约未收口');
        if (!hasExpectedMjs) {
            console.error(`  缺少正确入口：${legionMjs}`);
        }
        if (!hasExpectedWasm) {
            console.error(`  缺少正确模块：${legionWasm}`);
        }
        if (hasLegacyMjs || hasLegacyWasm) {
            console.error('  当前实际仍输出已知错误产物：');
            if (hasLegacyMjs) {
                console.error(`    - ${legacyLegionMjs}`);
            }
            if (hasLegacyWasm) {
                console.error(`    - ${legacyLegionWasm}`);
            }
            result.blockers.push('当前仍输出 `legion_tools.*`，正确产物应为 `legion.mjs` / `legion.wasm`');
        } else {
            result.blockers.push('未产出 `legion.mjs` / `legion.wasm`');
        }

        if (hasLegacyMjs) {
            console.log('\n探测当前错误命名入口的最小运行...');
            const legacyHelpCheck = runCommand(`node "${legacyLegionMjs}" --help`, { timeout: 10000 });
            result.runtime.mode = 'legacy';
            result.runtime.entryPath = legacyLegionMjs;
            result.runtime.help = legacyHelpCheck;
            if (legacyHelpCheck.success) {
                console.log('  `legion_tools.mjs --help`：退出码 0');
            } else {
                const legacyError = shortenText(combineCommandOutput(legacyHelpCheck), 300);
                console.error(`  \`legion_tools.mjs --help\` 失败：${legacyError}`);
                result.blockers.push(`当前错误命名入口直接运行仍失败：${shortenText(legacyError, 160)}`);
            }
        }

        return result;
    }

    console.log('\n验证 v1 产物...');
    const v1VersionCheck = runCommand(`node "${legionMjs}" --version`, { timeout: 10000 });
    result.runtime.mode = 'expected';
    result.runtime.entryPath = legionMjs;
    result.runtime.version = v1VersionCheck;
    if (v1VersionCheck.success) {
        console.log(`  v1 --version：${v1VersionCheck.stdout.trim()}`);
    } else {
        console.error(`  警告：v1 --version 失败：${shortenText(combineCommandOutput(v1VersionCheck), 300)}`);
        result.blockers.push('v1 `legion.mjs --version` 仍失败');
    }

    const v1HelpCheck = runCommand(`node "${legionMjs}" --help`, { timeout: 10000 });
    result.runtime.help = v1HelpCheck;
    if (v1HelpCheck.success) {
        console.log('  v1 --help：退出码 0');
    } else {
        console.error(`  警告：v1 --help 失败：${shortenText(combineCommandOutput(v1HelpCheck), 300)}`);
        result.blockers.push('v1 `legion.mjs --help` 仍失败');
    }

    result.success = result.blockers.length === 0;
    return result;
}

// ─────────────────────────────────────────────────────────────
// Level 2：v1.wasm → v2.wasm（待接线）
// ─────────────────────────────────────────────────────────────

function compileV2(v1Result, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.wasm → v2.wasm');
    console.log('══════════════════════════════════════════════════\n');

    console.log('状态：未接线');
    console.log('原因：v1 产物（valkyrie.v legion）当前尚未形成可复用的 WASM 编译器入口，');
    console.log('      还不能稳定承担第二轮 `.v` 源码编译。');
    console.log('');
    console.log('待完成工作：');
    console.log('  1. 让 v1 WASM 产物具备真实可调用的编译器入口');
    console.log('  2. 用 v1 产物编译 valkyrie.v/projects/legion.tools → v2');
    console.log('  3. 比对 v1 与 v2 的 .wasm 产物');
    console.log('');
    console.log('命令（待 v1 编译器后端就绪后启用）：');
    console.log(`  node "${v1Result.legionMjs}" build "${BOOTSTRAP_PROJECT_DIR}" --target wasm -o "${outputDir}"`);

    return null;
}

// ─────────────────────────────────────────────────────────────
// 比对
// ─────────────────────────────────────────────────────────────

⍝ v1 / v2 比对规则（固化结论）
///
⍝ 必须比对（不一致则阻断）：
⍝   - .wasm 文件：核心 WASM 模块产物，是自举一致性的主要判定依据
⍝   - run-contract.txt：运行契约，必须完全一致
///
⍝ 允许差异（不阻断）：
⍝   - .mjs：胶水代码可能随宿主装配策略调整
///
⍝ 阻断条件：
⍝   - 任一 .wasm 文件哈希不一致 → 阻断
⍝   - run-contract.txt 不一致 → 阻断
⍝   - 产物清单结构不一致（多了或少了 .wasm 文件）→ 阻断

function compareArtifacts(v1Result, v2Result) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');

    if (!v1Result || !v2Result) {
        console.log('比对跳过：v1 或 v2 产物缺失');
        return { match: false, skipped: true };
    }

    const mustCompareExtensions = ['.wasm'];
    const mustCompareFiles = ['run-contract.txt'];
    const allowedDiffExtensions = ['.mjs'];

    console.log('比对规则：');
    console.log('  必须一致：.wasm 文件、run-contract.txt');
    console.log('  允许差异：.mjs');
    console.log('');

    const v1WasmFiles = collectFiles(v1Result.outputDir, mustCompareExtensions);
    const v2WasmFiles = collectFiles(v2Result.outputDir, mustCompareExtensions);

    const v1WasmNames = new Set(v1WasmFiles.map(f => path.basename(f)));
    const v2WasmNames = new Set(v2WasmFiles.map(f => path.basename(f)));

    let allMatch = true;
    const details = [];

    const onlyInV1 = [...v1WasmNames].filter(n => !v2WasmNames.has(n));
    const onlyInV2 = [...v2WasmNames].filter(n => !v1WasmNames.has(n));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的 .wasm 文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的 .wasm 文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    const common = [...v1WasmNames].filter(n => v2WasmNames.has(n));
    for (const name of common) {
        const v1File = v1WasmFiles.find(f => path.basename(f) === name);
        const v2File = v2WasmFiles.find(f => path.basename(f) === name);
        if (v1File && v2File) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${name}：哈希不一致`);
                console.log(`    v1: ${h1}`);
                console.log(`    v2: ${h2}`);
                details.push({ type: 'wasm_hash_mismatch', file: name, v1Hash: h1, v2Hash: h2 });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：一致`);
            }
        }
    }

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
WASM 自举验证脚本

用法：node scripts/bootstrap-wasm.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-wasm）
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
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-wasm'));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             WASM 自举验证                               ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');
    console.log('说明：当前发布门仅承认 `CLR / NuGet` 源头自举；本脚本只用于手工排查 WASM 后端现状。\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        console.error('错误：找不到上一代 legion CLI');
        console.error('请设置 --legion / LEGION_PATH，或保证 NyarVM.cs 可用以便脚本自动构建上一代 legion');
        process.exit(1);
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    const level1BuildPassed = Boolean(v1Result.build?.buildResult?.success);
    const expectedEntryReady = fs.existsSync(v1Result.legionMjs) && fs.existsSync(v1Result.legionWasm);
    const v1VersionPassed = Boolean(v1Result.runtime?.mode === 'expected' && v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v1RuntimePassed = v1VersionPassed && v1HelpPassed;

    if (level1BuildPassed) {
        console.log('\nLevel 1（源码 → v1.wasm）已完成构建');
        console.log(`v1 产物目录：${v1Result.outputDir}`);
        console.log(`v1 .wasm 哈希：${v1Result.hash}`);
    } else {
        console.error('\nLevel 1（源码 → v1.wasm）未通过');
    }

    const v2Result = expectedEntryReady && v1RuntimePassed
        ? compileV2(v1Result, v2OutputDir, options.verbose)
        : null;
    const compareResult = compareArtifacts(v1Result, v2Result);

    console.log('\n══════════════════════════════════════════════════');
    console.log('  自举验证总结');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`Level 1（源码 → v1.wasm）：${level1BuildPassed ? '已出包' : '未通过'}`);
    console.log(`Level 1 构建日志（旧 \`manifest.v\` 错误）：${v1Result.build?.manifestParseErrorFound ? '仍出现' : '本次未发现'}`);
    console.log(`Level 1 入口契约（legion.mjs / legion.wasm）：${expectedEntryReady ? '通过' : '未通过'}`);
    console.log(`Level 1 运行验收（${v1Result.runtime?.entryPath ? path.basename(v1Result.runtime.entryPath) : 'legion.mjs'} --help）：${v1Result.runtime?.help ? (v1Result.runtime.help.success ? '通过' : '未通过') : '未执行'}`);
    console.log(`Level 2（v1.wasm → v2.wasm）：${v2Result ? (compareResult.match ? '通过' : '未通过（产物不一致）') : '未进入'}`);
    console.log(`v1 / v2 比对：${compareResult.skipped ? '跳过' : (compareResult.match ? '一致' : '不一致')}`);

    const blockers = [...v1Result.blockers];
    if (!expectedEntryReady || !v1RuntimePassed) {
        blockers.push('未进入 `v1 -> v2`：Level 1 入口契约或运行验收未通过');
    } else if (!v2Result) {
        blockers.push('v1 -> v2 未执行或未产出有效结果');
    } else if (compareResult.skipped) {
        blockers.push('v1 / v2 比对被跳过');
    } else if (!compareResult.match) {
        blockers.push('v1 / v2 产物比对不一致');
    }

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
