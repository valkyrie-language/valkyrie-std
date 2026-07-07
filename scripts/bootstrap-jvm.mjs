#!/usr/bin/env node

/**
 * JVM（jvm-openjdk-unknown-managed）自举验证脚本
 *
 * 与 CLR / Node 轨共享 gate schema；允许诚实失败，但 report 字段必须齐全。
 *
 * 用法：
 *   node scripts/bootstrap-jvm.mjs [--legion <path>] [--output <dir>] [--verbose]
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
    resolveJvmEntry,
    runCommand,
    seedLaunchCommand,
    shortenText,
    validateCanonicalRunContract,
    validateModuleSystem,
    writeReport,
} from './bootstrap-lib.mjs';

const TRACK = BOOTSTRAP_TRACKS.jvm;
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = TRACK.targetTriple;
const TARGET_ALIAS = TRACK.targetAlias;
const MODULE_GUARD_SKIPPED_REASON = '由于模块系统前置门未通过，`seed -> v1.jvm` 未执行。';
const LEVEL2_SKIPPED_REASON = '由于上游门禁未通过，`v1.jvm -> v2.jvm` 未执行。';

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

function runJarCli(jarPath, args, options = {}) {
    return runCommand(`java -jar "${jarPath}" ${args}`, { silent: options.silent ?? true, timeout: options.timeout ?? 10000 });
}

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.jvm');
    console.log('══════════════════════════════════════════════════\n');

    const versionCheck = runCommand(`${seedLaunchCommand(legionPath)} --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        return {
            success: false,
            error: shortenText(versionCheck.stderr || versionCheck.stdout || '上一代编译器不可用'),
            outputDir,
            entry: resolveJvmEntry(outputDir),
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
    const entry = resolveJvmEntry(targetDir);

    if (!buildResult.success) {
        return {
            success: false,
            error: shortenText(buildResult.stderr || buildResult.stdout || 'v1 编译失败'),
            outputDir: targetDir,
            entry,
            runtime: { version: { success: false }, help: { success: false } },
        };
    }

    if (!entry.legionJar || entry.legacy) {
        return {
            success: false,
            error: entry.legacy ? '仍输出 legion_tools.jar' : '未产出 legion.jar',
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

    const v1VersionCheck = runJarCli(entry.legionJar, '--version');
    const v1HelpCheck = runJarCli(entry.legionJar, '--help');

    return {
        success: true,
        outputDir: targetDir,
        entry,
        hash: computeDirHash(targetDir, ['.jar']),
        runtime: { version: v1VersionCheck, help: v1HelpCheck },
    };
}

function compileV2(v1Result, outputDir) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.jvm → v2.jvm');
    console.log('══════════════════════════════════════════════════\n');

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildResult = runJarCli(
        v1Result.entry.legionJar,
        `build "${BOOTSTRAP_PROJECT_DIR}" --target ${TARGET_ALIAS} -o "${outputDir}"`,
        { silent: false, timeout: 300000 },
    );
    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveJvmEntry(targetDir);

    if (!buildResult.success) {
        return { success: false, error: shortenText(buildResult.stderr || buildResult.stdout || 'v2 编译失败'), outputDir: targetDir, entry };
    }
    if (!entry.legionJar) {
        return { success: false, error: 'v2 未产出 legion.jar', outputDir: targetDir, entry };
    }
    return { success: true, outputDir: targetDir, entry, hash: computeDirHash(targetDir, ['.jar']) };
}

function compareArtifacts(v1Result, v2Result) {
    if (!v1Result?.success || !v2Result?.success) {
        return { match: false, skipped: true, v1Hash: null, v2Hash: null, contractMatch: false };
    }

    const v1Hash = v1Result.hash || computeFileHash(v1Result.entry.legionJar);
    const v2Hash = v2Result.hash || computeFileHash(v2Result.entry.legionJar);
    const jarMatch = v1Hash === v2Hash;
    const contract = compareRunContractArtifacts(v1Result.outputDir, v2Result.outputDir);
    const match = jarMatch && contract.match;

    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');
    console.log(`  legion.jar：${jarMatch ? '一致' : '不一致'}`);
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
        } else if (arg === '--output' && argv[index + 1]) {
            options.output = argv[++index];
        } else if (arg === '--verbose') {
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

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             JVM 自举验证                                  ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    const moduleSystemResult = validateModuleSystem(ROOT_DIR, options.verbose);
    if (!moduleSystemResult.success) {
        const gates = l2GateNamesForTrack('jvm').map((name, index) => createGate(
            name,
            index === 0 ? '未通过' : '跳过',
            index === 0 ? shortenText(moduleSystemResult.errors.join('；'), 400) : MODULE_GUARD_SKIPPED_REASON,
        ));
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('jvm', {
            gates,
            blockers: moduleSystemResult.errors.map((error) => `模块系统前置门失败：${error}`),
            moduleSystem: moduleSystemResult,
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
            ...l2GateNamesForTrack('jvm').slice(2).map((name) => createGate(name, '跳过', '上一代编译器入口未就绪')),
        ];
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('jvm', {
            gates,
            blockers: ['上一代编译器入口未就绪'],
            moduleSystem: moduleSystemResult,
        }));
        printGateSummary(gates);
        process.exit(1);
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v2Result = v1Result.success && v1VersionPassed && v1HelpPassed ? compileV2(v1Result, v2OutputDir) : null;
    const compareResult = compareArtifacts(v1Result, v2Result);

    const blockers = [];
    if (!v1Result.success) blockers.push(`源码 -> v1.jvm 失败：${v1Result.error}`);
    if (!v1VersionPassed) blockers.push('v1 `java -jar legion.jar --version` 失败');
    if (!v1HelpPassed) blockers.push('v1 `java -jar legion.jar --help` 失败');
    if (!v2Result) blockers.push(LEVEL2_SKIPPED_REASON);
    else if (!v2Result.success) blockers.push(`v1 -> v2.jvm 失败：${v2Result.error}`);
    else if (!compareResult.match) blockers.push('v1 / v2 jar 比对不一致');

    const gates = [
        createGate('模块系统前置门', '通过', moduleSystemResult.detail),
        createGate('上一代编译器入口', '通过', legionPath),
        createGate('源码 -> v1.jvm', v1Result.success ? '通过' : '未通过', v1Result.success ? v1Result.entry.legionJar : v1Result.error),
        createGate('v1 --version', v1VersionPassed ? '通过' : '未通过', v1VersionPassed ? '退出码 0' : '执行失败'),
        createGate('v1 --help', v1HelpPassed ? '通过' : '未通过', v1HelpPassed ? '退出码 0' : '执行失败'),
        createGate('v1 -> v2.jvm', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result?.error || LEVEL2_SKIPPED_REASON),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? 'v1->v2 未完成' : 'jar + run-contract*.txt'),
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
    });
    printGateSummary(gates);
    console.log(`\n报告已写入：${reportPath}`);
    process.exit(blockers.length === 0 ? 0 : 1);
}

main();
