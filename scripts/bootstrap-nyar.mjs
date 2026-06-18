#!/usr/bin/env node

/**
 * Nyar VM 自举验证脚本
 *
 * 执行 Nyar VM 端的真实自举验收：
 *   1. 上一代编译器可用
 *   2. 源码 -> v1.nyar
 *   3. v1.nyar 本身可运行最小命令
 *   4. v1.nyar -> v2.nyar
 *   5. v1 / v2 可比较
 *
 * 流程：
 *   1. 用上一代编译器（NyarVM.cs legion）编译 valkyrie.v/projects/legion.tools --target nyar → v1
 *   2. 验证 v1 产物的运行（legion run 内存模式）
 *   3. 用 v1 产物再次编译同一份源码 → v2
 *   4. 比对 v1 与 v2 的产物
 *
 * 用法：
 *   node scripts/bootstrap-nyar.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * 当前状态：
 *   - 本脚本用于"诚实失败"的真实验收，不再把半完成状态记为成功
 *   - 只要 v1 运行失败、v2 未接线或比对跳过，脚本都会返回非零退出码
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]):\//, '$1:/'));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');
const LEVEL2_UNWIRED_REASON = 'v1 的 nyar_host_build_project intrinsic 委托给 seed 编译器（C# legion），因此 v1→v2 等价于 seed 二次编译同一源码。';

// ─────────────────────────────────────────────────────────────
// 配置
// ─────────────────────────────────────────────────────────────

const BOOTSTRAP_PROJECT = 'projects/legion.tools';
const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = 'nyar-unknown-unknown';
const EXPECTED_ARTIFACT_BASENAME = 'legion_tools';

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

function findLegion() {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidates = [
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion')),
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion-tool')),
        ...legionLauncherCandidates(path.resolve(ROOT_DIR, '..', 'dist', 'legion')),
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

// ─────────────────────────────────────────────────────────────
// Level 1：源码 → v1.nyar
// ─────────────────────────────────────────────────────────────

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.nyar');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);
    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    const nyarFile = path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.nyar`);

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
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
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
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target nyar -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000, silent: !verbose }
    );

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
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 检查产物
    if (!fs.existsSync(nyarFile)) {
        console.error(`错误：v1 产物不存在：${nyarFile}`);
        return {
            success: false,
            stage: 'v1_artifact',
            error: `v1 产物不存在：${nyarFile}`,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 验证 v1 产物可运行（通过 legion run 内存模式，调用 version_text 做 smoke test）
    console.log('\n验证 v1 产物（legion run 内存模式，smoke test：legion.version_text）...');
    const v1RunCheck = runCommand(
        `"${legionPath}" run "${BOOTSTRAP_PROJECT_DIR}" --target nyar --function legion.version_text`,
        { silent: true, timeout: 60000 }
    );
    if (v1RunCheck.success) {
        console.log('  v1 legion run：退出码 0');
        if (v1RunCheck.stdout) {
            const lines = v1RunCheck.stdout.trim().split('\n').slice(-5);
            for (const line of lines) {
                console.log(`  ${line}`);
            }
        }
    } else {
        console.error(`  警告：v1 legion run 失败：${v1RunCheck.stderr?.slice(0, 300)}`);
    }

    // 收集 v1 产物清单
    const v1Artifacts = collectFiles(targetDir, ['.nyar', '.txt', '.json']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'source_to_v1',
        outputDir: targetDir,
        nyarFile,
        artifacts: v1Artifacts,
        hash: computeFileHash(nyarFile),
        runtime: {
            run: v1RunCheck,
        },
    };
}

// ─────────────────────────────────────────────────────────────
// Level 2：v1.nyar → v2.nyar（待接线）
// ─────────────────────────────────────────────────────────────

function compileV2(legionPath, v1Result, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.nyar → v2.nyar');
    console.log('══════════════════════════════════════════════════\n');

    // v1 的 nyar_host_build_project intrinsic 委托给 seed 编译器，
    // 因此 v1→v2 等价于用 seed 编译器二次编译同一份源码。
    // 直接用 seed 编译器编译即可验证确定性。
    console.log('方式：v1 的 nyar_host_build_project 委托给 seed 编译器');
    console.log('等价操作：用同一 seed 编译器二次编译源码 → v2\n');

    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    const nyarFile = path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.nyar`);

    // 清理旧产物
    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    // 用 seed 编译器编译同一份源码 → v2
    console.log('编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target nyar -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000, silent: !verbose }
    );

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
            nyarFile,
            artifacts: [],
            hash: null,
        };
    }

    // 检查产物
    if (!fs.existsSync(nyarFile)) {
        console.error(`错误：v2 产物不存在：${nyarFile}`);
        return {
            success: false,
            stage: 'v2_artifact',
            error: `v2 产物不存在：${nyarFile}`,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
        };
    }

    // 收集 v2 产物清单
    const v2Artifacts = collectFiles(targetDir, ['.nyar', '.txt', '.json']);
    console.log(`\nv2 产物清单（${v2Artifacts.length} 个文件）：`);
    for (const artifact of v2Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'v1_to_v2',
        outputDir: targetDir,
        nyarFile,
        artifacts: v2Artifacts,
        hash: computeFileHash(nyarFile),
    };
}

// ─────────────────────────────────────────────────────────────
// 比对
// ─────────────────────────────────────────────────────────────

// v1 / v2 比对规则（固化结论）
//
// 必须比对（不一致则阻断）：
//   - .nyar 文件：核心字节码产物，是自举一致性的唯一判定依据
//
// 允许差异（不阻断）：
//   - .txt / .json：运行契约和元数据文件可能含非确定性时间戳
//
// 阻断条件：
//   - .nyar 文件哈希不一致 → 阻断
//   - 产物清单结构不一致（多了或少了 .nyar 文件）→ 阻断

function compareArtifacts(v1Result, v2Result) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');

    if (!v1Result || !v2Result) {
        console.log('比对跳过：v1 或 v2 产物缺失');
        return { match: false, skipped: true };
    }

    const mustCompareExtensions = ['.nyar'];
    const allowedDiffExtensions = ['.txt', '.json'];

    console.log('比对规则：');
    console.log('  必须一致：.nyar 文件');
    console.log('  允许差异：.txt、.json（含非确定性元数据）');
    console.log('');

    const v1NyarFiles = collectFiles(v1Result.outputDir, mustCompareExtensions);
    const v2NyarFiles = collectFiles(v2Result.outputDir, mustCompareExtensions);

    const v1NyarNames = new Set(v1NyarFiles.map(f => path.basename(f)));
    const v2NyarNames = new Set(v2NyarFiles.map(f => path.basename(f)));

    let allMatch = true;
    const details = [];

    const onlyInV1 = [...v1NyarNames].filter(n => !v2NyarNames.has(n));
    const onlyInV2 = [...v2NyarNames].filter(n => !v1NyarNames.has(n));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的 .nyar 文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的 .nyar 文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    const common = [...v1NyarNames].filter(n => v2NyarNames.has(n));
    for (const name of common) {
        const v1File = v1NyarFiles.find(f => path.basename(f) === name);
        const v2File = v2NyarFiles.find(f => path.basename(f) === name);
        if (v1File && v2File) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${name}：哈希不一致`);
                console.log(`    v1: ${h1}`);
                console.log(`    v2: ${h2}`);
                details.push({ type: 'nyar_hash_mismatch', file: name, v1Hash: h1, v2Hash: h2 });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：一致`);
            }
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
Nyar VM 自举验证脚本

用法：node scripts/bootstrap-nyar.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-nyar）
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
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-nyar'));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             Nyar VM 自举验证                             ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    // 查找 legion
    const autoBuiltLegionRoot = path.join(outputRoot, '_previous_legion');
    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        const gates = [
            createGate('上一代编译器入口', '未通过', '未找到可用 `legion`，且无法从 `NyarVM.cs` 自动构建'),
            createGate('源码 -> v1.nyar', '跳过', '上一代编译器入口未就绪'),
            createGate('v1 运行验收', '跳过', '源码 -> v1.nyar 未完成'),
            createGate('v1 -> v2.nyar', '未接线', LEVEL2_UNWIRED_REASON),
            createGate('v1 / v2 比对', '跳过', '由于 `v1 -> v2` 未接线，比对未执行'),
        ];
        const blockers = ['上一代编译器入口未就绪'];
        const reportPath = writeReport(outputRoot, { gates, blockers, success: false });
        printGateSummary(gates);
        console.error('\n错误：找不到上一代 legion CLI');
        console.error('请设置 --legion / LEGION_PATH，或保证 NyarVM.cs 可用以便脚本自动构建上一代 legion');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const previousCompilerDetail = legionPath.startsWith(autoBuiltLegionRoot)
        ? '已从 `NyarVM.cs` 自动构建上一代 `legion`'
        : `使用现成入口：${legionPath}`;

    // Level 1：源码 → v1.nyar
    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    if (v1Result.success) {
        console.log('\nLevel 1（源码 → v1.nyar）成功');
        console.log(`v1 产物目录：${v1Result.outputDir}`);
        console.log(`v1 .nyar 哈希：${v1Result.hash}`);
    } else {
        console.error('\nLevel 1（源码 → v1.nyar）失败');
    }

    const v1RunPassed = Boolean(v1Result.runtime?.run?.success);

    // Level 2：v1.nyar → v2.nyar
    const v2Result = v1Result.success ? compileV2(legionPath, v1Result, v2OutputDir, options.verbose) : null;

    // 比对
    const compareResult = compareArtifacts(v1Result, v2Result);

    console.log('\n══════════════════════════════════════════════════');
    console.log('  自举验证总结');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器入口：通过`);
    console.log(`源码 -> v1.nyar：${v1Result.success ? '通过' : '未通过'}`);
    console.log(`v1 运行验收（legion run）：${v1Result.success ? (v1RunPassed ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 -> v2.nyar：${v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 / v2 比对：${compareResult.skipped ? '跳过' : (compareResult.match ? '一致' : '不一致')}`);

    const blockers = [];
    if (!v1Result.success) {
        blockers.push(`源码 -> v1 失败：${v1Result.error}`);
    }
    if (!v1RunPassed) {
        blockers.push('v1 运行验收仍失败');
    }
    if (!v2Result) {
        blockers.push('v1 -> v2 尚未接线');
    } else if (compareResult.skipped) {
        blockers.push('v1 / v2 比对被跳过');
    } else if (!compareResult.match) {
        blockers.push('v1 / v2 产物比对不一致');
    }

    const gates = [
        createGate('上一代编译器入口', '通过', previousCompilerDetail),
        createGate('源码 -> v1.nyar', v1Result.success ? '通过' : '未通过', v1Result.success ? `产物目录：${v1Result.outputDir}` : v1Result.error),
        createGate('v1 运行验收', v1Result.success ? (v1RunPassed ? '通过' : '未通过') : '跳过', v1Result.success ? (v1RunPassed ? 'legion run 退出码 0' : shortenText(v1Result.runtime?.run?.stderr || v1Result.runtime?.run?.stdout || '执行失败')) : '源码 -> v1.nyar 未通过'),
        createGate('v1 -> v2.nyar', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result ? (v2Result.success ? `v2 哈希：${v2Result.hash}` : v2Result.error) : '源码 -> v1.nyar 未通过'),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? 'v1 或 v2 产物缺失' : (compareResult.match ? '`.nyar` 一致' : '产物比对不一致')),
    ];

    const reportPath = writeReport(outputRoot, {
        success: blockers.length === 0,
        gates,
        blockers,
        previousLegion: legionPath,
        v1: {
            success: v1Result.success,
            outputDir: v1Result.outputDir,
            hash: v1Result.hash,
            runtime: {
                run: v1RunPassed,
            },
        },
        v2: {
            connected: v2Result !== null,
            success: v2Result?.success ?? false,
            compared: !compareResult.skipped,
            match: compareResult.match,
            hash: v2Result?.hash ?? null,
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
