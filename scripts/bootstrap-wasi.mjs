#!/usr/bin/env node

/**
 * WASI（wasm32-unknown-wasi-wasi）L2 自举验证脚本
 *
 * 从 witness 轨升级为完整 L2 自举，与 CLR / JVM / Node 轨对齐：
 *   1. 模块系统前置门（共享）
 *   2. seed → v1.wasi（legion.wasi）
 *   3. wasmtime run -W gc v1.wasi --version
 *   4. wasmtime run -W gc v1.wasi --help
 *   5. v1.wasi → v2.wasi（v1 作为编译器构建源码）
 *   6. v1 / v2 比对（.wasi 哈希 + run-contract*.txt 语义字段）
 *
 * 运行口径：`wasmtime run -W gc <file>.wasi`
 * 产物命名：`.wasi`（由 `WasmBinaryBackend` 控制）
 *
 * 用法：
 *   node scripts/bootstrap-wasi.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * 当前状态：
 *   WASI CM lowering（`wasi_cm.rs`）目前仅支持最小 lowering（字符串输出 / witness
 *   分派 / 最小 `_start`），不走 MIR 路径。因此 v1.wasi 尚非功能完整的编译器，
 *   `--version` / `--help` / `v1 -> v2` 可能失败。脚本诚实报告每一门的状态，
 *   不跳过也不伪装通过。
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
    BOOTSTRAP_PROJECT,
    BOOTSTRAP_TRACKS,
    collectFiles,
    computeDirHash,
    computeFileHash,
    createGate,
    createL2ReportSkeleton,
    findLegion,
    printGateSummary,
    repoRootFrom,
    resolveArtifactDir,
    resolveWasiEntry,
    runCommand,
    seedLaunchCommand,
    shortenText,
    validateCanonicalRunContract,
    validateModuleSystem,
    writeReport,
} from './bootstrap-lib.mjs';

const TRACK = BOOTSTRAP_TRACKS.wasi;
const OUTPUT_SUBDIR = 'bootstrap-wasi';
const REPORT_FILE = 'bootstrap-report.json';

const WASI_L2_GATE_NAMES = [
    '模块系统前置门',
    '上一代编译器入口',
    '源码 -> v1.wasi',
    'v1 --version',
    'v1 --help',
    'v1 -> v2.wasi',
    'v1 / v2 比对',
];

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = TRACK.targetTriple;
const TARGET_ALIAS = TRACK.targetAlias;
const WASMTIME_GC_ARGS = ['run', '-W', 'gc', '-W', 'wmemcheck', '-W', 'max-memory-size=16777216', '-S', 'p3'];
const WASMTIME_GC_ARGS_NO_WMEMCHECK = ['run', '-W', 'gc', '-W', 'max-memory-size=16777216', '-S', 'p3'];
const MODULE_GUARD_SKIPPED_REASON = '由于模块系统前置门未通过，`seed -> v1.wasi` 未执行。';
const LEVEL2_SKIPPED_REASON = '由于上游门禁未通过，`v1.wasi -> v2.wasi` 未执行。';

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
        { cwd: NYARVM_DIR, silent: !verbose, timeout: 300000 },
    );

    if (!publishResult.success) {
        console.error('错误：自动构建上一代 legion 失败');
        if (publishResult.stderr) {
            console.error(publishResult.stderr.slice(0, 4000));
        }
        return null;
    }

    return findLegion(ROOT_DIR, VALKYRIE_RS_DIR, NYARVM_DIR) || path.join(toolOutputDir, 'legion');
}

function wasmtimeAvailable() {
    const result = runCommand('wasmtime --version', { silent: true, timeout: 5000 });
    return result.success;
}

function runWasmtime(wasmPath, extraArgs = []) {
    const runOnce = (gcArgs) => {
        const args = [...gcArgs, `"${wasmPath}"`, ...extraArgs].join(' ');
        return runCommand(`wasmtime ${args}`, { silent: true, timeout: 30000, cwd: path.dirname(wasmPath) });
    };
    const primary = runOnce(WASMTIME_GC_ARGS);
    if (primary.success) {
        return primary;
    }
    const err = `${primary.stderr || ''}\n${primary.stdout || ''}`;
    if (/wmemcheck.*not enabled in this build/i.test(err)) {
        return runOnce(WASMTIME_GC_ARGS_NO_WMEMCHECK);
    }
    return primary;
}

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.wasi');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`目标：${TARGET_ALIAS} (${TARGET_TRIPLE})`);
    console.log(`输出目录：${outputDir}\n`);

    const versionCheck = runCommand(`${seedLaunchCommand(legionPath)} --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        console.error('错误：上一代编译器不可用');
        console.error(versionCheck.stderr);
        return {
            success: false,
            stage: 'previous_compiler_check',
            error: shortenText(versionCheck.stderr || versionCheck.stdout || '上一代编译器不可用'),
            outputDir,
            entry: { legionWasm: null },
            artifacts: [],
            hash: null,
            runtime: { version: versionCheck, help: { success: false } },
        };
    }
    console.log(`上一代编译器版本：${versionCheck.stdout.trim()}`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    console.log('\n编译中...');
    const buildResult = runCommand(
        `${seedLaunchCommand(legionPath)} build "${BOOTSTRAP_PROJECT_DIR}" --target ${TARGET_ALIAS} -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000 },
    );

    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveWasiEntry(targetDir);

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
            entry,
            artifacts: [],
            hash: null,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    if (!entry.legionWasm) {
        console.error('错误：v1 未产出 legion.wasi');
        return {
            success: false,
            stage: 'v1_entry_contract',
            error: '未产出 legion.wasi',
            outputDir: targetDir,
            entry,
            artifacts: collectFiles(targetDir, ['.wasi', '.wasm', '.wit', '.txt']),
            hash: null,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    console.log('\n验证 v1 产物...');
    const v1VersionCheck = runWasmtime(entry.legionWasm, ['--version']);
    const v1HelpCheck = runWasmtime(entry.legionWasm, ['--help']);

    if (v1VersionCheck.success) {
        console.log(`  v1 --version：${v1VersionCheck.stdout.trim()}`);
    } else {
        console.error(`  v1 --version 失败：${shortenText(v1VersionCheck.stderr || v1VersionCheck.stdout, 300)}`);
    }
    if (v1HelpCheck.success) {
        console.log('  v1 --help：退出码 0');
    } else {
        console.error(`  v1 --help 失败：${shortenText(v1HelpCheck.stderr || v1HelpCheck.stdout, 300)}`);
    }

    const v1Artifacts = collectFiles(targetDir, ['.wasi', '.wasm', '.wit', '.txt', '.json']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: Boolean(entry.legionWasm),
        stage: 'source_to_v1',
        outputDir: targetDir,
        entry,
        artifacts: v1Artifacts,
        hash: computeDirHash(targetDir, ['.wasi']),
        runtime: { version: v1VersionCheck, help: v1HelpCheck },
    };
}

function compileV2(v1Result, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.wasi → v2.wasi');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`v1 编译器：${v1Result.entry.legionWasm}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildArgs = ['build', `"${BOOTSTRAP_PROJECT_DIR}"`, '--target', TARGET_ALIAS, '-o', `"${outputDir}"`];
    const buildResult = runWasmtime(v1Result.entry.legionWasm, buildArgs);

    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveWasiEntry(targetDir);

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
            entry,
            artifacts: [],
            hash: null,
        };
    }

    if (!entry.legionWasm) {
        console.error('错误：v2 未产出 legion.wasi');
        return {
            success: false,
            stage: 'v2_entry_contract',
            error: 'v2 未产出 legion.wasi',
            outputDir: targetDir,
            entry,
            artifacts: collectFiles(targetDir, ['.wasi', '.wasm', '.wit', '.txt']),
            hash: null,
        };
    }

    const v2Artifacts = collectFiles(targetDir, ['.wasi', '.wasm', '.wit', '.txt', '.json']);
    console.log(`v2 产物清单（${v2Artifacts.length} 个文件）：`);
    for (const artifact of v2Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'v1_to_v2',
        outputDir: targetDir,
        entry,
        artifacts: v2Artifacts,
        hash: computeDirHash(targetDir, ['.wasi']),
    };
}

function parseContractFields(filePath) {
    if (!fs.existsSync(filePath)) {
        return null;
    }
    const text = fs.readFileSync(filePath, 'utf8');
    const fields = {};
    const regex = /(\w+)\s*:\s*"([^"]*)"/g;
    let match;
    while ((match = regex.exec(text)) !== null) {
        fields[match[1]] = match[2];
    }
    return fields;
}

function compareArtifacts(v1Result, v2Result) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');

    if (!v1Result || !v2Result || !v2Result.success) {
        console.log('比对跳过：v1 或 v2 产物缺失');
        return { match: false, skipped: true };
    }

    const allExtensions = ['.wasi', '.wasm', '.wit', '.json', '.txt'];
    const contractFiles = ['run-contract.txt', 'run-contracts.txt'];

    console.log('比对规则：');
    console.log('  必须一致（哈希）：.wasi');
    console.log('  必须一致（语义字段）：run-contract*.txt');
    console.log('  文件清单必须一致：所有扩展名');
    console.log('');

    let allMatch = true;
    const details = [];

    const v1AllFiles = collectFiles(v1Result.outputDir, allExtensions);
    const v2AllFiles = collectFiles(v2Result.outputDir, allExtensions);
    const v1Names = new Set(v1AllFiles.map((file) => path.basename(file)));
    const v2Names = new Set(v2AllFiles.map((file) => path.basename(file)));

    const onlyInV1 = [...v1Names].filter((name) => !v2Names.has(name));
    const onlyInV2 = [...v2Names].filter((name) => !v1Names.has(name));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    const common = [...v1Names].filter((name) => v2Names.has(name));
    for (const name of common) {
        const v1File = v1AllFiles.find((file) => path.basename(file) === name);
        const v2File = v2AllFiles.find((file) => path.basename(file) === name);
        const ext = path.extname(name).toLowerCase();

        if (ext === '.wasi' || ext === '.wasm') {
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

    for (const fileName of contractFiles) {
        const v1File = path.join(v1Result.outputDir, fileName);
        const v2File = path.join(v2Result.outputDir, fileName);
        const v1Fields = parseContractFields(v1File);
        const v2Fields = parseContractFields(v2File);

        if (v1Fields && v2Fields) {
            const allKeys = new Set([...Object.keys(v1Fields), ...Object.keys(v2Fields)]);
            let fieldMatch = true;
            for (const key of allKeys) {
                const v1Value = v1Fields[key];
                const v2Value = v2Fields[key];
                if (v1Value !== v2Value) {
                    console.log(`  [阻断] ${fileName}：字段 ${key} 不一致`);
                    console.log(`    v1: ${v1Value ?? '(缺失)'}`);
                    console.log(`    v2: ${v2Value ?? '(缺失)'}`);
                    details.push({ type: 'contract_field_mismatch', file: fileName, field: key, v1: v1Value, v2: v2Value });
                    fieldMatch = false;
                    allMatch = false;
                }
            }
            if (fieldMatch) {
                console.log(`  [通过] ${fileName}：语义字段一致`);
            }
        }
    }

    return { match: allMatch, skipped: false, details };
}

function parseArgs() {
    const args = process.argv.slice(2);
    const options = { legion: null, output: null, verbose: false };

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
WASI（wasm32-unknown-wasi-wasi）L2 自举验证

用法：node scripts/bootstrap-wasi.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-wasi）
  --verbose, -v       详细输出
  --help, -h          显示帮助
`);
                process.exit(0);
            default:
                break;
        }
    }

    return options;
}

function main() {
    const options = parseArgs();
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', OUTPUT_SUBDIR));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║        WASI（Component Model）L2 自举验证               ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}`);
    console.log(`运行口径：wasmtime run -W gc <file>.wasi\n`);

    const moduleSystemResult = validateModuleSystem(ROOT_DIR, options.verbose);
    if (!moduleSystemResult.success) {
        const gates = WASI_L2_GATE_NAMES.map((name, index) => createGate(
            name,
            index === 0 ? '未通过' : '跳过',
            index === 0 ? shortenText(moduleSystemResult.errors.join('；'), 400) : MODULE_GUARD_SKIPPED_REASON,
        ));
        const reportPath = writeReport(outputRoot, {
            success: false,
            track: TRACK.track,
            profile: 'l2',
            targetTriple: TARGET_TRIPLE,
            gates,
            blockers: moduleSystemResult.errors.map((error) => `模块系统前置门失败：${error}`),
            previousLegion: null,
            moduleSystem: moduleSystemResult,
            matrix: { build: false, cli: false, runContract: false, runtime: false, v1ToV2: false, compared: false },
            v1: { success: false, outputDir: null, hash: null, runtime: { version: false, help: false } },
            v2: { attempted: false, success: false, outputDir: null, compared: false, match: false, reason: LEVEL2_SKIPPED_REASON },
        }, REPORT_FILE);
        printGateSummary(gates);
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath || !fs.existsSync(legionPath)) {
        const gates = [
            createGate('模块系统前置门', '通过', moduleSystemResult.detail),
            createGate('上一代编译器入口', '未通过', '未找到可用 `legion`'),
            ...WASI_L2_GATE_NAMES.slice(2).map((name) => createGate(name, '跳过', '上一代编译器入口未就绪')),
        ];
        const reportPath = writeReport(outputRoot, {
            success: false,
            track: TRACK.track,
            profile: 'l2',
            targetTriple: TARGET_TRIPLE,
            gates,
            blockers: ['上一代编译器入口未就绪'],
            previousLegion: null,
            moduleSystem: moduleSystemResult,
            matrix: { build: false, cli: false, runContract: false, runtime: false, v1ToV2: false, compared: false },
            v1: { success: false, outputDir: null, hash: null, runtime: { version: false, help: false } },
            v2: { attempted: false, success: false, outputDir: null, compared: false, match: false, reason: LEVEL2_SKIPPED_REASON },
        }, REPORT_FILE);
        printGateSummary(gates);
        console.error('\n错误：找不到上一代 legion CLI');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const wasmtimeReady = wasmtimeAvailable();
    if (!wasmtimeReady) {
        console.error('错误：wasmtime 不在 PATH');
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v1RuntimePassed = v1VersionPassed && v1HelpPassed;

    const contract = v1Result.success ? validateCanonicalRunContract(v1Result.outputDir) : { valid: false, errors: ['build 未产出 legion.wasi'] };
    const contractPassed = contract.valid;

    const v2Result = v1Result.success && v1RuntimePassed ? compileV2(v1Result, v2OutputDir, options.verbose) : null;
    const compareResult = compareArtifacts(v1Result, v2Result);

    const blockers = [];
    if (!v1Result.success) {
        blockers.push(`源码 -> v1.wasi 失败：${v1Result.error || '见构建日志'}`);
    }
    if (!wasmtimeReady) {
        blockers.push('wasmtime 不在 PATH');
    }
    if (wasmtimeReady && !v1VersionPassed) {
        blockers.push('v1 `wasmtime run -W gc legion.wasi --version` 失败');
    }
    if (wasmtimeReady && !v1HelpPassed) {
        blockers.push('v1 `wasmtime run -W gc legion.wasi --help` 失败');
    }
    if (!contractPassed) {
        blockers.push(...contract.errors);
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
        createGate('模块系统前置门', '通过', moduleSystemResult.detail),
        createGate('上一代编译器入口', '通过', legionPath),
        createGate('源码 -> v1.wasi', v1Result.success ? '通过' : '未通过', v1Result.success ? `产物：${v1Result.entry.legionWasm}` : v1Result.error),
        createGate('v1 --version', v1VersionPassed ? '通过' : '未通过', v1VersionPassed ? v1Result.runtime.version.stdout.trim() : '执行失败'),
        createGate('v1 --help', v1HelpPassed ? '通过' : '未通过', v1HelpPassed ? '退出码 0' : '执行失败'),
        createGate('v1 -> v2.wasi', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result?.success ? `产物：${v2Result.entry.legionWasm}` : v2Result?.error || LEVEL2_SKIPPED_REASON),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? 'v1->v2 未完成' : '`.wasi` 哈希 + `run-contract*.txt` 语义字段 + 全文件清单'),
    ];

    console.log('\n══════════════════════════════════════════════════');
    console.log('  自举验证总结');
    console.log('══════════════════════════════════════════════════\n');

    for (const gate of gates) {
        console.log(`${gate.name}：${gate.status}`);
    }

    const reportPath = writeReport(outputRoot, {
        success: blockers.length === 0,
        track: TRACK.track,
        profile: 'l2',
        targetTriple: TARGET_TRIPLE,
        gates,
        blockers,
        previousLegion: legionPath,
        moduleSystem: moduleSystemResult,
        matrix: {
            build: v1Result.success,
            cli: v1VersionPassed && v1HelpPassed,
            runContract: contractPassed,
            runtime: v1VersionPassed && v1HelpPassed,
            v1ToV2: Boolean(v2Result?.success),
            compared: compareResult.match,
        },
        v1: {
            success: v1Result.success,
            outputDir: v1Result.outputDir,
            hash: v1Result.hash,
            runtime: { version: v1VersionPassed, help: v1HelpPassed },
        },
        v2: {
            attempted: Boolean(v2Result),
            success: Boolean(v2Result?.success),
            outputDir: v2Result?.outputDir || null,
            compared: !compareResult.skipped,
            match: compareResult.match,
        },
        wasmtimeGcArgs: WASMTIME_GC_ARGS,
    }, REPORT_FILE);

    printGateSummary(gates);
    console.log(`\n报告已写入：${reportPath}`);

    if (blockers.length > 0) {
        console.log('\n当前仍未满足 WASI 轨真实 L2 自举验收，阻断项如下：');
        for (const blocker of blockers) {
            console.log(`  - ${blocker}`);
        }
        process.exit(1);
    }

    process.exit(0);
}

main();
