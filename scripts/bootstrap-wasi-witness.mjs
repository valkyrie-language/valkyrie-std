#!/usr/bin/env node

/**
 * WASI（wasm32-unknown-wasi-wasi）自举验证脚本
 *
 * 完整 L2 七门：build / cli / runContract / runtime / v1ToV2 / compared。
 * 与 CLR / JVM / Node 轨共享 L2 gate schema。
 *
 * 用法：
 *   node scripts/bootstrap-wasi-witness.mjs [--legion <path>] [--output <dir>] [--verbose]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
    BOOTSTRAP_PROJECT,
    BOOTSTRAP_TRACKS,
    collectFiles,
    compareRunContractArtifacts,
    computeDirHash,
    computeFileHash,
    createGate,
    createL2ReportSkeleton,
    findLegion,
    l2GateNamesForTrack,
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
import { runWasiAntiCheatChecks } from './check-bootstrap-integrity.mjs';

const TRACK = BOOTSTRAP_TRACKS.wasi;
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = TRACK.targetTriple;
const TARGET_ALIAS = TRACK.targetAlias;
const WASMTIME_GC_ARGS = ['run', '-W', 'gc', '-W', 'wmemcheck', '-W', 'max-memory-size=16777216'];
const WASMTIME_GC_ARGS_NO_WMEMCHECK = ['run', '-W', 'gc', '-W', 'max-memory-size=16777216'];
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
        return null;
    }
    return findLegion(ROOT_DIR, VALKYRIE_RS_DIR, NYARVM_DIR) || path.join(toolOutputDir, 'legion');
}

function wasmtimeAvailable() {
    const result = runCommand('wasmtime --version', { silent: true, timeout: 5000 });
    return result.success;
}

function runWasiArtifact(wasmPath, extraArgs = []) {
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

    const versionCheck = runCommand(`${seedLaunchCommand(legionPath)} --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        return {
            success: false,
            error: shortenText(versionCheck.stderr || versionCheck.stdout || '上一代编译器不可用'),
            outputDir,
            entry: resolveWasiEntry(outputDir),
            runtime: { version: versionCheck, help: { success: false } },
        };
    }

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildResult = runCommand(
        `${seedLaunchCommand(legionPath)} build "${BOOTSTRAP_PROJECT_DIR}" --target ${TARGET_ALIAS} -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000 },
    );
    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveWasiEntry(targetDir);

    if (!buildResult.success) {
        return {
            success: false,
            error: shortenText(buildResult.stderr || buildResult.stdout || 'v1 编译失败'),
            outputDir: targetDir,
            entry,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    if (!entry.legionWasm || entry.legacy) {
        return {
            success: false,
            error: entry.legacy ? '仍输出 legacy .wasm' : '未产出 legion.wasi',
            outputDir: targetDir,
            entry,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    const contract = validateCanonicalRunContract(targetDir);
    if (!contract.valid) {
        return {
            success: false,
            error: contract.errors.join('；'),
            outputDir: targetDir,
            entry,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    const wasmtimeReady = wasmtimeAvailable();
    const v1VersionRun = wasmtimeReady ? runWasiArtifact(entry.legionWasm, ['--version']) : { success: false };
    const v1HelpRun = wasmtimeReady ? runWasiArtifact(entry.legionWasm, ['--help']) : { success: false };

    return {
        success: true,
        outputDir: targetDir,
        entry,
        hash: computeDirHash(targetDir, ['.wasi', '.wit', '.txt', '.json']),
        runtime: { version: v1VersionRun, help: v1HelpRun },
        wasmtimeReady,
    };
}

function compileV2(v1Result, outputDir) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.wasi → v2.wasi');
    console.log('══════════════════════════════════════════════════\n');

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildResult = runWasiArtifact(
        v1Result.entry.legionWasm,
        ['build', `"${BOOTSTRAP_PROJECT_DIR}"`, '--target', TARGET_ALIAS, '-o', `"${outputDir}"`],
    );
    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveWasiEntry(targetDir);

    if (!buildResult.success) {
        return { success: false, error: shortenText(buildResult.stderr || buildResult.stdout || 'v2 编译失败'), outputDir: targetDir, entry };
    }
    if (!entry.legionWasm) {
        return { success: false, error: 'v2 未产出 legion.wasi', outputDir: targetDir, entry };
    }
    return { success: true, outputDir: targetDir, entry, hash: computeDirHash(targetDir, ['.wasi', '.wit', '.txt', '.json']) };
}

function compareArtifacts(v1Result, v2Result) {
    if (!v1Result?.success || !v2Result?.success) {
        return { match: false, skipped: true, v1Hash: null, v2Hash: null, contractMatch: false };
    }

    const v1Hash = v1Result.hash || computeFileHash(v1Result.entry.legionWasm);
    const v2Hash = v2Result.hash || computeFileHash(v2Result.entry.legionWasm);
    const wasmMatch = v1Hash === v2Hash;
    const contract = compareRunContractArtifacts(v1Result.outputDir, v2Result.outputDir);
    const match = wasmMatch && contract.match;

    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');
    console.log(`  legion.wasi：${wasmMatch ? '一致' : '不一致'}`);
    console.log(`  run-contract*.txt：${contract.match ? '一致' : '不一致'}`);

    return { match, skipped: false, v1Hash, v2Hash, contractMatch: contract.match, details: contract.details };
}

function parseArgs() {
    const options = { legion: null, output: null, verbose: false };
    const argv = process.argv.slice(2);
    for (let index = 0; index < argv.length; index += 1) {
        const arg = argv[index];
        if (arg === '--legion' && argv[index + 1]) {
            options.legion = argv[++index];
        }
        else if (arg === '--output' && argv[index + 1]) {
            options.output = argv[++index];
        }
        else if (arg === '--verbose') {
            options.verbose = true;
        }
    }
    return options;
}

function main() {
    const options = parseArgs();
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', TRACK.outputSubdir));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');
    const wasiAntiCheat = runWasiAntiCheatChecks(VALKYRIE_RS_DIR);

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             WASI 自举验证 (L2)                            ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    const moduleSystemResult = validateModuleSystem(ROOT_DIR, options.verbose);
    if (!moduleSystemResult.success) {
        const gates = l2GateNamesForTrack('wasi').map((name, index) => createGate(
            name,
            index === 0 ? '未通过' : '跳过',
            index === 0 ? shortenText(moduleSystemResult.errors.join('；'), 400) : MODULE_GUARD_SKIPPED_REASON,
        ));
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('wasi', {
            gates,
            blockers: moduleSystemResult.errors.map((error) => `模块系统前置门失败：${error}`),
            moduleSystem: moduleSystemResult,
            antiCheat: wasiAntiCheat,
        }));
        printGateSummary(gates);
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath || !fs.existsSync(legionPath)) {
        const gates = [
            createGate('模块系统前置门', '通过', moduleSystemResult.detail),
            createGate('上一代编译器入口', '未通过', '未找到可用 legion'),
            ...l2GateNamesForTrack('wasi').slice(2).map((name) => createGate(name, '跳过', '上一代编译器入口未就绪')),
        ];
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('wasi', {
            gates,
            blockers: ['上一代编译器入口未就绪'],
            moduleSystem: moduleSystemResult,
            antiCheat: wasiAntiCheat,
        }));
        printGateSummary(gates);
        process.exit(1);
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const wasmtimeReady = v1Result.wasmtimeReady ?? false;
    const v2Result = v1Result.success && v1VersionPassed && v1HelpPassed ? compileV2(v1Result, v2OutputDir) : null;
    const compareResult = compareArtifacts(v1Result, v2Result);

    const blockers = [];
    if (!v1Result.success) blockers.push(`源码 -> v1.wasi 失败：${v1Result.error}`);
    if (!wasmtimeReady) blockers.push('wasmtime 不在 PATH');
    if (wasmtimeReady && !v1VersionPassed) blockers.push('v1 `wasmtime run -W gc v1.wasi --version` 失败');
    if (wasmtimeReady && !v1HelpPassed) blockers.push('v1 `wasmtime run -W gc v1.wasi --help` 失败');
    if (!v2Result) blockers.push(LEVEL2_SKIPPED_REASON);
    else if (!v2Result.success) blockers.push(`v1 -> v2.wasi 失败：${v2Result.error}`);
    else if (!compareResult.match) blockers.push('v1 / v2 比对不一致');

    const gates = [
        createGate('模块系统前置门', '通过', moduleSystemResult.detail),
        createGate('上一代编译器入口', '通过', legionPath),
        createGate('源码 -> v1.wasi', v1Result.success ? '通过' : '未通过', v1Result.success ? v1Result.entry.legionWasm : v1Result.error),
        createGate('v1 --version', v1VersionPassed ? '通过' : '未通过', v1VersionPassed ? '退出码 0' : (wasmtimeReady ? '执行失败' : 'wasmtime 不可用')),
        createGate('v1 --help', v1HelpPassed ? '通过' : '未通过', v1HelpPassed ? '退出码 0' : (wasmtimeReady ? '执行失败' : 'wasmtime 不可用')),
        createGate('v1 -> v2.wasi', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result?.error || LEVEL2_SKIPPED_REASON),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? 'v1->v2 未完成' : 'wasi + run-contract*.txt'),
    ];

    const reportPath = writeReport(outputRoot, {
        success: blockers.length === 0,
        track: TRACK.track,
        profile: TRACK.profile,
        targetTriple: TARGET_TRIPLE,
        gates,
        blockers,
        previousLegion: legionPath,
        moduleSystem: moduleSystemResult,
        artifacts: collectFiles(v1Result.outputDir || v1OutputDir, ['.wasi', '.wasm', '.wit', '.txt', '.json']),
        wasmtimeGcArgs: WASMTIME_GC_ARGS,
        v1: v1Result,
        v2: v2Result,
        compare: compareResult,
        matrix: {
            build: v1Result.success,
            cli: v1VersionPassed && v1HelpPassed,
            runContract: v1Result.success,
            runtime: v1VersionPassed && v1HelpPassed,
            v1ToV2: Boolean(v2Result?.success),
            compared: compareResult.match,
        },
        antiCheat: wasiAntiCheat,
    });

    printGateSummary(gates);
    console.log(`\n反作弊进度：${wasiAntiCheat.passed ? '通过' : '未通过'}`);
    if (!wasiAntiCheat.passed) {
        for (const violation of wasiAntiCheat.violations) {
            console.log(`  - ${violation}`);
        }
    }
    console.log(`\n报告已写入：${reportPath}`);
    process.exit(blockers.length === 0 ? 0 : 1);
}

main();
