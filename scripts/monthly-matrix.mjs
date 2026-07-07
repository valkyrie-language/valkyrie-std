#!/usr/bin/env node

/**
 * 四目标月度验收矩阵聚合器
 *
 * 聚合 CLR / JVM / Node / WASI 报告 + runtime 矩阵结果。
 * 任一目标缺席 → exit 1（CI 硬阻断口径）。
 *
 * 用法：
 *   node scripts/monthly-matrix.mjs [--repo-root <path>] [--runtime-matrix <path>]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
    BOOTSTRAP_TRACKS,
    l2GateNamesForTrack,
    repoRootFrom,
    validateReportGateSchema,
} from './bootstrap-lib.mjs';
import { runWasiAntiCheatChecks } from './check-bootstrap-integrity.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_ROOT = repoRootFrom(SCRIPT_DIR);

const MATRIX_COLUMNS = ['build', 'cli', 'runContract', 'runtime', 'v1ToV2', 'compared'];
const WASI_EXTRA_COLUMNS = ['functional', 'antiCheat'];

const REPORT_SPECS = [
    { key: 'clr', track: BOOTSTRAP_TRACKS.clr, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('clr') },
    { key: 'jvm', track: BOOTSTRAP_TRACKS.jvm, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('jvm') },
    { key: 'node', track: BOOTSTRAP_TRACKS.node, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('node') },
    { key: 'wasi', track: BOOTSTRAP_TRACKS.wasi, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('wasi') },
];

function parseArgs() {
    const options = { repoRoot: DEFAULT_ROOT, runtimeMatrix: null };
    const argv = process.argv.slice(2);
    for (let index = 0; index < argv.length; index += 1) {
        const arg = argv[index];
        if (arg === '--repo-root' && argv[index + 1]) options.repoRoot = path.resolve(argv[++index]);
        else if (arg === '--runtime-matrix' && argv[index + 1]) options.runtimeMatrix = path.resolve(argv[++index]);
    }
    return options;
}

function loadReport(repoRoot, spec) {
    const reportPath = path.join(repoRoot, 'dist', spec.track.outputSubdir, spec.file);
    if (!fs.existsSync(reportPath)) {
        return { present: false, reportPath, report: null, errors: [`${spec.key} report 缺席：${reportPath}`] };
    }
    const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
    const schema = validateReportGateSchema(report, spec.profile, spec.gateNames);
    return { present: true, reportPath, report, errors: schema.valid ? [] : schema.errors.map((e) => `${spec.key}: ${e}`) };
}

function deriveMatrixRow(report, gateNames) {
    if (report.matrix && typeof report.matrix === 'object') {
        return report.matrix;
    }
    const gates = report.gates || [];
    const gateStatus = (name) => gates.find((gate) => gate.name === name)?.status;
    const v1Gate = gateNames[2];
    const v2Gate = gateNames[5];
    return {
        profile: 'l2',
        build: gateStatus(v1Gate) === '通过',
        cli: gateStatus('v1 --version') === '通过' && gateStatus('v1 --help') === '通过',
        runContract: gateStatus(v1Gate) === '通过',
        runtime: gateStatus('v1 --version') === '通过' && gateStatus('v1 --help') === '通过',
        v1ToV2: gateStatus(v2Gate) === '通过',
        compared: gateStatus('v1 / v2 比对') === '通过',
    };
}

function collectGateFailures(report, spec) {
    const errors = [];
    if (!report?.gates) {
        return errors;
    }
    const expectedCount = spec.gateNames.length;
    const passed = report.gates.filter((gate) => gate.status === '通过').length;
    const skipped = report.gates.filter((gate) => gate.status === '跳过');
    const failed = report.gates.filter((gate) => gate.status === '未通过');

    if (skipped.length > 0) {
        errors.push(`${spec.key}：${skipped.length} 个 gate 被跳过（整组 KPI 不允许跳过 v1→v2 / 比对）`);
        for (const gate of skipped) {
            errors.push(`  ${spec.key} gate 跳过：${gate.name} — ${gate.detail || '无详情'}`);
        }
    }
    if (failed.length > 0) {
        errors.push(`${spec.key}：${failed.length}/${expectedCount} gate 未通过`);
        for (const gate of failed) {
            errors.push(`  ${spec.key} gate 失败：${gate.name} — ${gate.detail || '无详情'}`);
        }
    }
    if (report.bridgeDetected === true) {
        errors.push(`${spec.key}：bridge 代编译检出`);
    }
    if (spec.profile === 'l2' && report.v2?.compared === false && report.success === true) {
        errors.push(`${spec.key}：v1/v2 比对未执行但 report.success=true`);
    }
    if (report.success === true && passed < expectedCount) {
        errors.push(`${spec.key}：success=true 但仅 ${passed}/${expectedCount} gate 通过`);
    }
    return errors;
}

function formatMatrixTable(rows) {
    const hasWasiRow = rows.some((row) => row.target === 'wasi');
    const columns = [...MATRIX_COLUMNS];
    if (hasWasiRow) {
        columns.push(...WASI_EXTRA_COLUMNS);
    }
    const header = ['target', 'profile', ...columns].join(' | ');
    const separator = ['---', '---', ...columns.map(() => '---')].join(' | ');
    const lines = rows.map((row) => [
        row.target,
        row.profile ?? 'n/a',
        ...columns.map((col) => String(row[col] ?? 'n/a')),
    ].join(' | '));
    return [header, separator, ...lines].join('\n');
}

function main() {
    const options = parseArgs();
    const errors = [];
    const rows = [];

    const valkyrieRsDir = path.resolve(options.repoRoot, '..', 'valkyrie.rs');
    const wasiAntiCheat = runWasiAntiCheatChecks(valkyrieRsDir);

    for (const spec of REPORT_SPECS) {
        const loaded = loadReport(options.repoRoot, spec);
        if (!loaded.present) {
            errors.push(...loaded.errors);
            const absentRow = {
                target: spec.key,
                profile: spec.profile,
                build: false,
                cli: false,
                runContract: false,
                runtime: false,
                v1ToV2: false,
                compared: false,
            };
            if (spec.key === 'wasi') {
                absentRow.functional = false;
                absentRow.antiCheat = wasiAntiCheat.passed;
            }
            rows.push(absentRow);
            continue;
        }
        errors.push(...loaded.errors);
        errors.push(...collectGateFailures(loaded.report, spec));
        const row = { target: spec.key, ...deriveMatrixRow(loaded.report, spec.gateNames) };
        if (spec.key === 'wasi') {
            row.functional = loaded.report.success === true;
            row.antiCheat = wasiAntiCheat.passed;
        }
        rows.push(row);
    }

    let runtimeMatrixOk = true;
    if (options.runtimeMatrix) {
        if (!fs.existsSync(options.runtimeMatrix)) {
            errors.push(`runtime 矩阵结果缺席：${options.runtimeMatrix}`);
            runtimeMatrixOk = false;
        } else {
            const runtimePayload = JSON.parse(fs.readFileSync(options.runtimeMatrix, 'utf8'));
            if (runtimePayload.success !== true) {
                errors.push('runtime 矩阵未全绿');
                runtimeMatrixOk = false;
            }
        }
    }

    const outputRoot = path.join(options.repoRoot, 'dist', 'monthly-matrix');
    fs.mkdirSync(outputRoot, { recursive: true });
    const summary = {
        generatedAt: new Date().toISOString(),
        success: errors.length === 0 && runtimeMatrixOk,
        targets: rows,
        failureConditions: {
            absentReport: errors.some((e) => e.includes('report 缺席')),
            skippedGate: errors.some((e) => e.includes('gate 跳过')),
            failedGate: errors.some((e) => e.includes('gate 失败')),
            bridgeDetected: errors.some((e) => e.includes('bridge')),
            runtimeMatrix: !runtimeMatrixOk,
            antiCheatViolation: !wasiAntiCheat.passed,
        },
        wasiAntiCheat: {
            passed: wasiAntiCheat.passed,
            violations: wasiAntiCheat.violations,
        },
        errors,
        runtimeMatrix: options.runtimeMatrix,
    };
    const summaryPath = path.join(outputRoot, 'monthly-matrix.json');
    fs.writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`, 'utf8');

    console.log('\n══════════════════════════════════════════════════');
    console.log('  四目标月度验收矩阵');
    console.log('══════════════════════════════════════════════════\n');
    console.log(formatMatrixTable(rows));
    console.log(`\n汇总已写入：${summaryPath}`);

    if (errors.length > 0 || !runtimeMatrixOk) {
        console.error('\n月度矩阵未通过：');
        for (const error of errors) {
            console.error(`  - ${error}`);
        }
        process.exit(1);
    }

    console.log('\n四目标联合验收通过');
}

main();
