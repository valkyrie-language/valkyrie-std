#!/usr/bin/env node

/**
 * Node（wasm32-node-unknown-wasm）自举验证脚本
 *
 * 与 CLR 轨并行，面向 npm / JSR 分发：
 *   1. 模块系统前置门（与 bootstrap-clr 共享）
 *   2. seed → v1.node（legion.mjs + legion.wasm）
 *   3. node v1 --version / --help
 *   4. node v1 build → v2.node
 *   5. v1 / v2 比对（.wasm + run-contract*.txt）
 *
 * 用法：
 *   node scripts/bootstrap-node.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * seed 优先级：LEGION_PATH → valkyrie.rs legion → dist → NyarVM.cs
 *
 * 当前状态：诚实失败验收；v1→v2 在 v1 未形成稳定 Node 编译器入口前会明确阻断。
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
    l2GateNamesForTrack,
    printGateSummary,
    repoRootFrom,
    resolveArtifactDir,
    resolveNodeEntry,
    runCommand,
    seedLaunchCommand,
    shortenText,
    validateModuleSystem,
    writeReport,
} from './bootstrap-lib.mjs';

const TRACK = BOOTSTRAP_TRACKS.node;

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = TRACK.targetTriple;
const TARGET_ALIAS = TRACK.targetAlias;
const MODULE_GUARD_SKIPPED_REASON = '由于模块系统前置门未通过，`seed -> v1.node` 未执行。';
const LEVEL2_SKIPPED_REASON = '由于上游门禁未通过，`v1.node -> v2.node` 未执行。';

const LEGACY_ENTRY_BASENAME = 'legion_tools';
const MANIFEST_PARSE_ERROR_PATTERN = /projects[\\/]+legion\.tools[\\/]+source[\\/]+manifest\.v/i;

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

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.node');
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
            entry: { legionMjs: null, legionWasm: null },
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
    const entry = resolveNodeEntry(targetDir);
    const buildOutput = [buildResult.stdout, buildResult.stderr].filter(Boolean).join('\n');
    const manifestParseErrorFound = MANIFEST_PARSE_ERROR_PATTERN.test(buildOutput);

    if (manifestParseErrorFound) {
        console.error('错误：构建日志仍含 `projects/legion._/projects/legion.tools/source/manifest.v` 相关错误');
    }

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
            manifestParseErrorFound,
        };
    }

    if (!entry.legionMjs || !entry.legionWasm) {
        const legacyMjs = path.join(targetDir, `${LEGACY_ENTRY_BASENAME}.mjs`);
        const legacyWasm = path.join(targetDir, `${LEGACY_ENTRY_BASENAME}.wasm`);
        let detail = '未产出 `legion.mjs` / `legion.wasm`';
        if (fs.existsSync(legacyMjs) || fs.existsSync(legacyWasm)) {
            detail = '当前仍输出 `legion_tools.*`，正确产物应为 `legion.mjs` / `legion.wasm`';
        }
        console.error(`错误：v1 Node 入口契约未满足 — ${detail}`);
        return {
            success: false,
            stage: 'v1_entry_contract',
            error: detail,
            outputDir: targetDir,
            entry,
            artifacts: collectFiles(targetDir, ['.wasm', '.mjs', '.txt']),
            hash: null,
            runtime: { version: { success: false }, help: { success: false } },
            manifestParseErrorFound,
        };
    }

    console.log('\n验证 v1 产物...');
    const v1VersionCheck = runCommand(`node "${entry.legionMjs}" --version`, { silent: true, timeout: 10000 });
    const v1HelpCheck = runCommand(`node "${entry.legionMjs}" --help`, { silent: true, timeout: 10000 });

    if (v1VersionCheck.success) {
        console.log(`  v1 --version：${v1VersionCheck.stdout.trim()}`);
    } else {
        console.error(`  v1 --version 失败：${shortenText(v1VersionCheck.stderr, 300)}`);
    }
    if (v1HelpCheck.success) {
        console.log('  v1 --help：退出码 0');
    } else {
        console.error('  v1 --help 失败');
    }

    const v1Artifacts = collectFiles(targetDir, ['.wasm', '.mjs', '.txt', '.json']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: v1VersionCheck.success && v1HelpCheck.success,
        stage: 'source_to_v1',
        outputDir: targetDir,
        entry,
        artifacts: v1Artifacts,
        hash: computeDirHash(targetDir, ['.wasm']),
        runtime: { version: v1VersionCheck, help: v1HelpCheck },
        manifestParseErrorFound,
    };
}

function compileV2(v1Result, outputDir, verbose, legionHostPath) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.node → v2.node');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`v1 编译器：${v1Result.entry.legionMjs}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    const buildResult = runCommand(
        `node "${v1Result.entry.legionMjs}" build "${BOOTSTRAP_PROJECT_DIR}" --target ${TARGET_ALIAS} -o "${outputDir}"`,
        {
            cwd: ROOT_DIR,
            timeout: 300000,
            env: {
                LEGION_BOOTSTRAP_HOST: legionHostPath,
            },
        },
    );

    const targetDir = resolveArtifactDir(outputDir, TARGET_TRIPLE);
    const entry = resolveNodeEntry(targetDir);

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

    if (!entry.legionMjs || !entry.legionWasm) {
        console.error('错误：v2 未产出 `legion.mjs` / `legion.wasm`');
        return {
            success: false,
            stage: 'v2_entry_contract',
            error: 'v2 Node 入口契约未满足',
            outputDir: targetDir,
            entry,
            artifacts: collectFiles(targetDir, ['.wasm', '.mjs', '.txt']),
            hash: null,
        };
    }

    const v2Artifacts = collectFiles(targetDir, ['.wasm', '.mjs', '.txt', '.json']);
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
        hash: computeDirHash(targetDir, ['.wasm']),
    };
}

/**
 * 规范化 `.mjs` 内容：折叠所有空白为单个空格，用于结构性比对。
 *
 * 此规范化保留注释与字符串内容，仅消除空格 / 制表符 / 换行差异，
 * 确保 v1 与 v2 的 `.mjs` 胶水代码在结构层面一致而非仅"能运行"。
 *
 * @param {string} content - 原始 `.mjs` 文件内容
 * @returns {string} 规范化后的字符串
 */
function normalizeMjsContent(content) {
    return content.replace(/\s+/g, ' ').trim();
}

/**
 * 解析 `run-contract*.txt` 中的语义字段（Von `key: "value"` 格式）。
 *
 * 提取所有 `key: "value"` 对，用于逐字段比对而非整体哈希比对，
 * 精确定位契约漂移发生在哪个字段。
 *
 * @param {string} filePath - run-contract 文件路径
 * @returns {Object|null} 字段键值对象，或 `null`（文件不存在）
 */
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

    const allExtensions = ['.wasm', '.mjs', '.json', '.txt'];
    const contractFiles = ['run-contract.txt', 'run-contracts.txt'];

    console.log('比对规则：');
    console.log('  必须一致（哈希）：.wasm');
    console.log('  必须一致（语义字段）：run-contract*.txt');
    console.log('  必须一致（规范化比对）：.mjs');
    console.log('  文件清单必须一致：所有扩展名（.json / 非 contract .txt 仅比对清单）');
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

        if (ext === '.wasm') {
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
        } else if (ext === '.mjs') {
            const n1 = normalizeMjsContent(fs.readFileSync(v1File, 'utf8'));
            const n2 = normalizeMjsContent(fs.readFileSync(v2File, 'utf8'));
            if (n1 !== n2) {
                console.log(`  [阻断] ${name}：规范化后不一致（v1=${n1.length}字符, v2=${n2.length}字符）`);
                details.push({ type: 'mjs_normalized_mismatch', file: name, v1Length: n1.length, v2Length: n2.length });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：规范化后一致`);
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
Node（wasm32-node-unknown-wasm）自举验证

用法：node scripts/bootstrap-node.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-node）
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
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', TRACK.outputSubdir));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║        Node（WASM）自举验证 — npm / JSR 分发轨          ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    const moduleSystemResult = validateModuleSystem(ROOT_DIR, options.verbose);
    if (!moduleSystemResult.success) {
        const gates = l2GateNamesForTrack('node').map((name, index) => createGate(
            name,
            index === 0 ? '未通过' : '跳过',
            index === 0 ? shortenText(moduleSystemResult.errors.join('；'), 400) : MODULE_GUARD_SKIPPED_REASON,
        ));
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('node', {
            gates,
            blockers: moduleSystemResult.errors.map((error) => `模块系统前置门失败：${error}`),
            moduleSystem: moduleSystemResult,
            v2: { attempted: false, success: false, outputDir: null, compared: false, match: false, reason: LEVEL2_SKIPPED_REASON },
        }));
        printGateSummary(gates);
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath || !fs.existsSync(legionPath)) {
        const gates = [
            createGate('模块系统前置门', '通过', moduleSystemResult.detail),
            createGate('上一代编译器入口', '未通过', '未找到可用 `legion`'),
            ...l2GateNamesForTrack('node').slice(2).map((name) => createGate(name, '跳过', '上一代编译器入口未就绪')),
        ];
        const reportPath = writeReport(outputRoot, createL2ReportSkeleton('node', {
            gates,
            blockers: ['上一代编译器入口未就绪'],
            moduleSystem: moduleSystemResult,
        }));
        printGateSummary(gates);
        console.error('\n错误：找不到上一代 legion CLI');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v1RuntimePassed = v1VersionPassed && v1HelpPassed;

    const v2Result = v1Result.success && v1RuntimePassed ? compileV2(v1Result, v2OutputDir, options.verbose, legionPath) : null;
    const compareResult = compareArtifacts(v1Result, v2Result);

    const blockers = [];
    if (!v1Result.success) {
        blockers.push(`源码 -> v1 失败：${v1Result.error || '见构建日志'}`);
    }
    if (v1Result.manifestParseErrorFound) {
        blockers.push('构建日志仍含 `manifest.v` 解析错误');
    }
    if (!v1VersionPassed) {
        blockers.push('v1 `node legion.mjs --version` 失败');
    }
    if (!v1HelpPassed) {
        blockers.push('v1 `node legion.mjs --help` 失败');
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
        createGate('源码 -> v1.node', v1Result.success ? '通过' : '未通过', v1Result.success ? `产物：${v1Result.entry.legionMjs}` : v1Result.error),
        createGate('v1 --version', v1VersionPassed ? '通过' : '未通过', v1VersionPassed ? '退出码 0' : '执行失败'),
        createGate('v1 --help', v1HelpPassed ? '通过' : '未通过', v1HelpPassed ? '退出码 0' : '执行失败'),
        createGate('v1 -> v2.node', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result?.success ? `产物：${v2Result.entry.legionMjs}` : v2Result?.error || LEVEL2_SKIPPED_REASON),
        createGate('v1 / v2 比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? 'v1->v2 未完成' : '`.wasm` 哈希 + `run-contract*.txt` 语义字段 + `.mjs` 规范化 + 全文件清单'),
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
        profile: TRACK.profile,
        targetTriple: TARGET_TRIPLE,
        gates,
        blockers,
        previousLegion: legionPath,
        moduleSystem: moduleSystemResult,
        matrix: {
            build: v1Result.success,
            cli: v1VersionPassed && v1HelpPassed,
            runContract: v1Result.success,
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
        publish: {
            primaryRegistries: ['npm', 'jsr'],
            note: 'Node 轨产物通过 legion publish 发布到 npm（CLI）或 JSR（库包）',
        },
    });

    printGateSummary(gates);
    console.log(`\n报告已写入：${reportPath}`);

    if (blockers.length > 0) {
        console.log('\n当前仍未满足 Node 轨真实自举验收，阻断项如下：');
        for (const blocker of blockers) {
            console.log(`  - ${blocker}`);
        }
        process.exit(1);
    }

    process.exit(0);
}

main();
