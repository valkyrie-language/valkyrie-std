#!/usr/bin/env node

/**
 * 自举验证共享�? *
 * 为四目标自举脚本（CLR / JVM / Node / WASI witness）提供模块系统前置门�? * gate 汇总、报告落盘、seed 查找、产物解析与命令执行等公共能力�? *
 * 设计原则�? *   - �?Node 内置模块，零外部依赖
 *   - 跨平台（Windows / Linux / macOS�? *   - 所有路径用 `path.join`，不拼字符串
 */

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { execSync } from 'child_process';

/// 自举目标项目相对路径（相对仓库根）�?export const BOOTSTRAP_PROJECT = 'projects/legion._/projects/legion.tools';

/// 已废弃的作弊工程相对路径（模块系统前置门禁止其存在）�?export const REMOVED_MICRO_COMPILER_PROJECT = 'projects/micro_compiler';

/// 禁止回流�?`scripts/` 的临时手工分析器 / 调试产物�?///
/// 这些文件不属于正式自举验收链路，统一�?`legion spy` 与正�?bootstrap
/// 脚本替代；如重新出现，视为脚本治理回退�?export const AD_HOC_SCRIPT_ENTRIES = [
    '_build_check.mjs',
    '_cargo_build_check.mjs',
    '_check_output.mjs',
    '_clear_jvm_cache.mjs',
    '_debug_build.mjs',
    '_debug_stderr.txt',
    '_debug_stdout.txt',
    '_debug-map.mjs',
    '_dump_memberref.mjs',
    '_dump_method.mjs',
    '_dump_method_il.mjs',
    '_dump_methoddef.mjs',
    '_dump_pe_entry.mjs',
    '_dump_typedef.mjs',
    '_extract_class.mjs',
    '_find_method.mjs',
    '_find_vondiag.mjs',
    '_javap_dump.mjs',
    '_javap_full.txt',
    '_javap_method.mjs',
    '_jvm_diagnose.mjs',
    '_list_jar.mjs',
    '_method_body.txt',
    '_repro-build.mjs',
    '_run_clr_debug.mjs',
    '_run_clr_v1.mjs',
    '_spy_dump.mjs',
    '_spy_list.txt',
    '_spy_manifest.txt',
    '_spy_method.txt',
    '_test_clr_help.mjs',
    '_test_clr_help_v2.mjs',
    '_test_global_entry.il',
    '_test_jvm_cli.mjs',
    '_tmp_run_clr.mjs',
    'debug-build-v1.mjs',
    'debug-v1-trap.mjs',
    'fix-turbofish.mjs',
    'parse-locals.mjs',
    'spy-func.mjs',
];

/// `scripts/` 目录正式允许存在的入口�?///
/// �?`__tests__` 目录外，其余文件必须属于该白名单；新增正式脚本时要同步更新，
/// 否则视为把临时工具重新塞�?scripts 根目录�?export const OFFICIAL_SCRIPT_ENTRIES = [
    '__tests__',
    'bootstrap-clr.mjs',
    'bootstrap-jvm.mjs',
    'bootstrap-lib.mjs',
    'bootstrap-node.mjs',
    'bootstrap-smoke-clr.mjs',
    'bootstrap-smoke-node.mjs',
    'bootstrap-wasi-witness.mjs',
    'check-bootstrap-integrity.mjs',
    'monthly-matrix.mjs',
    'run-runtime-matrix.mjs',
];

/**
 * 从脚本所在目录推导仓库根目录�? *
 * 约定：本文件位于 `<repo>/scripts/bootstrap-lib.mjs`，仓库根为其父目录�? * @param {string} scriptDir - 脚本所在目录（通常�?`path.dirname(fileURLToPath(import.meta.url))` 得到�? * @returns {string} 仓库根目录绝对路�? */
export function repoRootFrom(scriptDir) {
    return path.resolve(scriptDir, '..');
}

/**
 * 在候选目录中查找 legion 可执行入口�? *
 * 候选优先级：`legion.exe` �?`legion`（无扩展名原生）�?`legion.dll`（CLR 托管）�? * @param {string} baseDir - 候选目�? * @returns {string|null} 命中入口绝对路径，或 `null`
 */
export function resolveLegionLauncher(baseDir) {
    const candidates = [
        path.join(baseDir, 'legion.exe'),
        path.join(baseDir, 'legion'),
        path.join(baseDir, 'legion.dll'),
    ];
    for (const candidate of candidates) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return null;
}

/**
 * 在三个仓库根中查找现成的上一�?legion CLI�? *
 * 查找顺序�? *   1. `LEGION_PATH` 环境变量
 *   2. `valkyrie.rs/target/{release,debug}/legion[.exe]`
 *   3. `valkyrie.v/dist/legion/legion[.exe]`
 *   4. `NyarVM.cs/tools/legion/publish/legion[.exe]`
 * @param {string} valkyrieVDir - `valkyrie.v` 仓库�? * @param {string} valkyrieRsDir - `valkyrie.rs` 仓库�? * @param {string} nyarVmDir - `NyarVM.cs` 仓库�? * @returns {string|null} 命中入口路径，或 `null`
 */
export function findLegion(valkyrieVDir, valkyrieRsDir, nyarVmDir) {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidateDirs = [
        path.join(valkyrieRsDir, 'target', 'release'),
        path.join(valkyrieRsDir, 'target', 'debug'),
        path.join(valkyrieVDir, 'dist', 'legion'),
        path.join(nyarVmDir, 'tools', 'legion', 'publish'),
    ];

    for (const dir of candidateDirs) {
        const found = resolveLegionLauncher(dir);
        if (found) {
            return found;
        }
    }
    return null;
}

/**
 * 解析 seed 启动命令前缀�? *
 * - CLR 托管 `.dll`：`dotnet exec "<path>"`
 * - 原生 `.exe` 或无扩展名：`"<path>"`
 * - 其他（如 `.mjs`）：`"<path>"`
 * @param {string} legionPath - seed 入口路径
 * @returns {string} 命令前缀字符�? */
export function seedLaunchCommand(legionPath) {
    const ext = path.extname(legionPath).toLowerCase();
    if (ext === '.dll') {
        return `dotnet exec "${legionPath}"`;
    }

    const runtimeconfig = legionPath.replace(/\.(exe|dll)$/i, '.runtimeconfig.json');
    if (fs.existsSync(runtimeconfig)) {
        return `dotnet exec "${legionPath}"`;
    }

    return `"${legionPath}"`;
}

/**
 * 解析构建产物目录�? *
 * 旧布局�?`{outputDir}/{targetTriple}/`，新布局直接写入 `{outputDir}/`�? * @param {string} outputDir - 构建命令�?`-o` 输出目录
 * @param {string} targetTriple - 规范目标三元组（�?`wasm32-node-unknown-wasm`�? * @returns {string} 实际产物所在目�? */
export function resolveArtifactDir(outputDir, targetTriple) {
    const nested = path.join(outputDir, targetTriple);
    if (fs.existsSync(nested)) {
        return nested;
    }
    return outputDir;
}

/**
 * 解析 run-contract 文件中的 physical_entry 字段�? * @param {string} contractPath
 * @returns {string|null}
 */
function readPhysicalEntryFromContract(contractPath) {
    if (!fs.existsSync(contractPath)) {
        return null;
    }
    const contractText = fs.readFileSync(contractPath, 'utf8');
    const match = contractText.match(/physical_entry\s*:\s*"([^"]+\.mjs)"/);
    return match ? match[1] : null;
}

/**
 * 解析 Node 轨入口契约产物�? *
 * 查找优先级：
 *   1. 规范入口 `legion.mjs` + `legion.wasm`
 *   2. `run-contracts.txt` 首条 `physical_entry`（复�?manifest，优先）
 *   3. `run-contract.txt` �?`physical_entry` 指定的实际入�? *   4. 遗留产物�?`legion_tools.*`
 * 交由调用方判定是否阻断�? * @param {string} targetDir - 产物目录
 * @returns {{legionMjs: string|null, legionWasm: string|null, legacy: boolean, physicalEntry: string|null}}
 */
export function resolveNodeEntry(targetDir) {
    const canonical = {
        legionMjs: path.join(targetDir, 'legion.mjs'),
        legionWasm: path.join(targetDir, 'legion.wasm'),
    };
    if (fs.existsSync(canonical.legionMjs) && fs.existsSync(canonical.legionWasm)) {
        return { ...canonical, legacy: false, physicalEntry: 'legion.mjs' };
    }

    const contractsPlural = path.join(targetDir, 'run-contracts.txt');
    const physicalFromPlural = readPhysicalEntryFromContract(contractsPlural);
    if (physicalFromPlural) {
        const physicalMjsPath = path.join(targetDir, physicalFromPlural);
        const physicalWasm = physicalFromPlural.replace(/\.mjs$/, '.wasm');
        const physicalWasmPath = path.join(targetDir, physicalWasm);
        if (fs.existsSync(physicalMjsPath) && fs.existsSync(physicalWasmPath)) {
            return { legionMjs: physicalMjsPath, legionWasm: physicalWasmPath, legacy: false, physicalEntry: physicalFromPlural };
        }
        if (fs.existsSync(physicalMjsPath)) {
            return { legionMjs: physicalMjsPath, legionWasm: null, legacy: false, physicalEntry: physicalFromPlural };
        }
    }

    const contractFile = path.join(targetDir, 'run-contract.txt');
    const physicalFromSingular = readPhysicalEntryFromContract(contractFile);
    if (physicalFromSingular) {
        const physicalMjsPath = path.join(targetDir, physicalFromSingular);
        const physicalWasm = physicalFromSingular.replace(/\.mjs$/, '.wasm');
        const physicalWasmPath = path.join(targetDir, physicalWasm);
        if (fs.existsSync(physicalMjsPath) && fs.existsSync(physicalWasmPath)) {
            return { legionMjs: physicalMjsPath, legionWasm: physicalWasmPath, legacy: false, physicalEntry: physicalFromSingular };
        }
        if (fs.existsSync(physicalMjsPath)) {
            return { legionMjs: physicalMjsPath, legionWasm: null, legacy: false, physicalEntry: physicalFromSingular };
        }
    }

    const legacyMjs = path.join(targetDir, 'legion_tools.mjs');
    const legacyWasm = path.join(targetDir, 'legion_tools.wasm');
    if (fs.existsSync(legacyMjs) && fs.existsSync(legacyWasm)) {
        return { legionMjs: legacyMjs, legionWasm: legacyWasm, legacy: true, physicalEntry: 'legion_tools.mjs' };
    }

    // 单文件命中（仅一侧存在）
    if (fs.existsSync(canonical.legionMjs)) {
        return { legionMjs: canonical.legionMjs, legionWasm: null, legacy: false, physicalEntry: 'legion.mjs' };
    }
    if (fs.existsSync(canonical.legionWasm)) {
        return { legionMjs: null, legionWasm: canonical.legionWasm, legacy: false, physicalEntry: 'legion.wasm' };
    }
    return { legionMjs: null, legionWasm: null, legacy: false, physicalEntry: null };
}

/**
 * 执行 shell 命令并捕获结果�? *
 * @param {string} command - 完整命令字符�? * @param {{cwd?: string, silent?: boolean, timeout?: number, env?: Object}} [options]
 * @returns {{success: boolean, stdout: string, stderr: string}}
 */
export function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: options.silent ? 'pipe' : 'inherit',
            env: options.env ? { ...process.env, ...options.env } : process.env,
        });
        return { success: true, stdout: result || '', stderr: '' };
    } catch (error) {
        return {
            success: false,
            stdout: error.stdout || '',
            stderr: error.stderr || error.message || '',
        };
    }
}

/**
 * 递归收集目录下指定扩展名的文件�? * @param {string} dir - 起始目录
 * @param {string[]} extensions - 扩展名列表（含点号，�?`['.wasm', '.mjs']`�? * @returns {string[]} 排序后的文件绝对路径
 */
export function collectFiles(dir, extensions) {
    const results = [];
    if (!fs.existsSync(dir)) {
        return results;
    }
    const extSet = new Set(extensions.map((e) => e.toLowerCase()));
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

/**
 * 计算单个文件�?SHA-256�? * @param {string} filePath
 * @returns {string} hex 摘要
 */
export function computeFileHash(filePath) {
    const content = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * 计算目录下指定扩展名文件的聚�?SHA-256�? * @param {string} dir
 * @param {string[]} extensions
 * @returns {string|null} 摘要�?`null`（无文件�? */
export function computeDirHash(dir, extensions) {
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

/**
 * 截断文本到指定长度，超出加省略号�? * @param {string} value
 * @param {number} [maxChars=240]
 * @returns {string}
 */
export function shortenText(value, maxChars = 240) {
    const text = String(value || '').trim();
    if (text.length <= maxChars) {
        return text;
    }
    return `${text.slice(0, maxChars)}...`;
}

/**
 * 构造门级状态对象�? * @param {string} name - 门名
 * @param {string} status - 状态：`通过` / `未通过` / `跳过`
 * @param {string} [detail] - 详情
 * @returns {{name: string, status: string, detail: string}}
 */
export function createGate(name, status, detail = '') {
    return { name, status, detail };
}

/**
 * 打印门级汇总�? * @param {Array<{name: string, status: string, detail?: string}>} gates
 */
export function printGateSummary(gates) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  门级状�?);
    console.log('══════════════════════════════════════════════════\n');
    for (const gate of gates) {
        console.log(`- ${gate.name}�?{gate.status}`);
        if (gate.detail) {
            console.log(`  ${gate.detail}`);
        }
    }
}

/**
 * �?JSON 报告到指定目录�? * @param {string} outputRoot - 输出根目�? * @param {Object} payload - 报告内容
 * @param {string} [reportFileName='bootstrap-report.json'] - 报告文件�? * @returns {string} 报告文件路径
 */
export function writeReport(outputRoot, payload, reportFileName = 'bootstrap-report.json') {
    fs.mkdirSync(outputRoot, { recursive: true });
    const reportPath = path.join(outputRoot, reportFileName);
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

/// �?workspace 嵌套成员映射（与 [`legions.von`](../../legions.von) 当前 members 对齐）�?/// �?workspace 引用 `projects/nyar._` 等超 workspace 时，视为间接包含嵌套 flat 成员�?const NESTED_WORKSPACE_PREFIX = {
    'projects/nyar._': [
        'projects/nyar',
        'projects/nyar.analyzer',
        'projects/nyar.optimizer',
        'projects/nyar.emitter',
        'projects/nyar.language',
        'projects/nyar.package_manager',
        'projects/nyar.package_registry',
    ],
    'projects/std.adaptors._': [
        'projects/std.adaptor.clr',
        'projects/std.adaptor.jvm',
        'projects/std.adaptor.linux',
        'projects/std.adaptor.macos',
        'projects/std.adaptor.nyar',
        'projects/std.adaptor.wasi',
        'projects/std.adaptor.wasm',
        'projects/std.adaptor.windows',
    ],
    'projects/std.data._': [
        'projects/std.data.text.valkyrie',
        'projects/std.data.text.von',
        'projects/std.data.text.msil',
        'projects/std.data.text.wat',
        'projects/std.data.text.wit',
        'projects/std.data.binary.clr',
        'projects/std.data.binary.class',
        'projects/std.data.binary.jar',
        'projects/std.data.binary.wasm',
    ],
    'projects/legion._': [
        'projects/legion.tools',
        'projects/legion.report',
    ],
    'projects/unity._': [
        'projects/unity.engine.sdk',
        'projects/valkyrie.unity',
    ],
};

/// �?dot-prefix / flat nyar 布局（仅 `VALKYRIE_BOOTSTRAP_LEGACY_PATHS=1` 时启用）�?const LEGACY_NESTED_WORKSPACE_PREFIX = {
    'projects/.nyar': NESTED_WORKSPACE_PREFIX['projects/nyar._'],
    'projects/.std.adaptors': NESTED_WORKSPACE_PREFIX['projects/std.adaptors._'],
    'projects/.std.data': NESTED_WORKSPACE_PREFIX['projects/std.data._'],
};

function nestedWorkspacePrefixMap() {
    if (process.env.VALKYRIE_BOOTSTRAP_LEGACY_PATHS === '1') {
        return { ...NESTED_WORKSPACE_PREFIX, ...LEGACY_NESTED_WORKSPACE_PREFIX };
    }
    return NESTED_WORKSPACE_PREFIX;
}

function legacyManifestCandidates(rootDir) {
    if (process.env.VALKYRIE_BOOTSTRAP_LEGACY_PATHS !== '1') {
        return { nyarManifest: [], stdManifest: [] };
    }
    return {
        nyarManifest: [
            path.join(rootDir, 'projects', 'nyar', 'legion.von'),
            path.join(rootDir, 'projects', '.nyar', 'projects', 'nyar', 'legion.von'),
        ],
        stdManifest: [
            path.join(rootDir, 'projects', '.std.adaptors', 'std', 'legion.von'),
        ],
    };
}

/**
 * 在候选路径列表中解析第一个存在的文件�? * @param {string} label
 * @param {string[]} candidateList
 * @returns {{hit: string|null, errors: string[]}}
 */
function resolveFirstExistingPath(label, candidateList) {
    const hit = candidateList.find((candidate) => fs.existsSync(candidate));
    if (!hit) {
        return {
            hit: null,
            errors: [`缺少必要文件�?{label} -> ${candidateList.join(' �?')}`],
        };
    }
    return { hit, errors: [] };
}

/// 判断 workspace 是否显式或通过�?workspace 嵌套间接包含某成员�?function workspaceIncludesMemberResolved(workspaceText, memberPath) {
    if (workspaceIncludesMember(workspaceText, memberPath)) {
        return true;
    }
    for (const [superMember, nestedMembers] of Object.entries(nestedWorkspacePrefixMap())) {
        if (workspaceIncludesMember(workspaceText, superMember) && nestedMembers.includes(memberPath)) {
            return true;
        }
    }
    return false;
}

/**
 * 构�?L2 六栏矩阵默认值�? * @param {Object} [overrides]
 * @returns {{build: boolean, cli: boolean, runContract: boolean, runtime: boolean, v1ToV2: boolean, compared: boolean}}
 */
export function createEmptyMatrix(overrides = {}) {
    return {
        build: false,
        cli: false,
        runContract: false,
        runtime: false,
        v1ToV2: false,
        compared: false,
        ...overrides,
    };
}

/**
 * 构�?WASI witness 六栏矩阵默认值（v1ToV2 / compared �?null）�? * @param {Object} [overrides]
 */
export function createWitnessMatrix(overrides = {}) {
    return {
        build: false,
        cli: false,
        runContract: false,
        runtime: false,
        v1ToV2: null,
        compared: null,
        ...overrides,
    };
}

/**
 * 构�?L2 bootstrap-report 骨架（早期失败也必须写全字段）�? * @param {'clr'|'jvm'|'node'|'wasi'} trackKey
 * @param {Object} [extra]
 */
export function createL2ReportSkeleton(trackKey, extra = {}) {
    const track = BOOTSTRAP_TRACKS[trackKey];
    return {
        success: false,
        track: track.track,
        profile: track.profile,
        targetTriple: track.targetTriple,
        gates: [],
        blockers: [],
        previousLegion: null,
        moduleSystem: { success: false, errors: [] },
        matrix: createEmptyMatrix(),
        v1: {
            success: false,
            outputDir: null,
            hash: null,
            runtime: { version: false, help: false },
        },
        v2: {
            attempted: false,
            success: false,
            outputDir: null,
            compared: false,
            match: false,
            reason: null,
        },
        ...extra,
    };
}

/**
 * CLR 产物目录解析（兼容旧 `{out}/{targetTriple}/` 布局）�? * @param {string} outputDir
 * @param {string} [targetTriple]
 */
export function resolveClrArtifactDir(outputDir, targetTriple = BOOTSTRAP_TRACKS.clr.targetTriple) {
    return resolveArtifactDir(outputDir, targetTriple);
}

/**
 * 比对 v1 / v2 �?run-contract*.txt（CLR / JVM / Node 共享规则）�? * @param {string} v1Dir
 * @param {string} v2Dir
 * @returns {{match: boolean, skipped: boolean, details: Object[]}}
 */
export function compareRunContractArtifacts(v1Dir, v2Dir) {
    const mustCompareFiles = ['run-contract.txt', 'run-contracts.txt'];
    let allMatch = true;
    const details = [];

    for (const fileName of mustCompareFiles) {
        const v1File = path.join(v1Dir, fileName);
        const v2File = path.join(v2Dir, fileName);
        const v1Exists = fs.existsSync(v1File);
        const v2Exists = fs.existsSync(v2File);

        if (v1Exists && v2Exists) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                allMatch = false;
                details.push({ type: 'contract_mismatch', file: fileName });
            }
        } else if (v1Exists !== v2Exists) {
            allMatch = false;
            details.push({ type: 'contract_missing', file: fileName });
        }
    }

    return { match: allMatch, skipped: false, details };
}

/**
 * 模块系统前置门：验证 `legion.tools` 项目�?workspace 与依赖契约�? *
 * 检查项（任一未满足则失败）：
 *   - 必要文件存在（`legions.von` / `legion.tools/legion.von` / `nyar/legion.von` / `std/legion.von` / `build_context.v`�? *   - `legion.tools` manifest：`name: "legion.tools"`、`auto_link: { core: true, std: false }`�? *     `nyar` / `std` / `std.data.text.von` 显式 workspace 依赖
 *   - `nyar` manifest：`name: "nyar"`、`auto_link: { core: true, std: true }`
 *   - `std` manifest：`name: "std"`
 *   - workspace 显式包含 `legion.tools` / `nyar` / `std` / `examples/test.module_system`
 *   - workspace 不再包含 `micro_compiler`
 *   - `micro_compiler` 目录已物理移�? *   - `build_context.v` �?`using nyar;` 与契约片�? *
 * @param {string} rootDir - `valkyrie.v` 仓库�? * @param {boolean} [verbose=false] - 详细输出
 * @returns {{success: boolean, errors: string[], detail?: string}}
 */
export function validateModuleSystem(rootDir, verbose = false) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  模块系统前置�?);
    console.log('══════════════════════════════════════════════════\n');

    // 当前仓库布局�?026-07）：
    //   - legion.tools / build_context：`projects/legion._/projects/legion.tools/`
    //   - legion.report：`projects/legion._/projects/legion.report/`
    //   - nyar：`projects/nyar._/projects/nyar/`（超 workspace 嵌套�?    //   - std：`projects/std/`（legions.von 直接 member�?    const legacy = legacyManifestCandidates(rootDir);
    const candidates = {
        workspaceManifest: [path.join(rootDir, 'legions.von')],
        legionToolsManifest: [
            path.join(rootDir, 'projects', 'legion._', 'projects', 'legion.tools', 'legion.von'),
            path.join(rootDir, 'projects', 'legion.tools', 'legion.von'),
        ],
        nyarManifest: [
            path.join(rootDir, 'projects', 'nyar._', 'projects', 'nyar', 'legion.von'),
            ...legacy.nyarManifest,
        ],
        stdManifest: [
            path.join(rootDir, 'projects', 'std', 'legion.von'),
            ...legacy.stdManifest,
        ],
        buildContext: [
            path.join(rootDir, 'projects', 'legion._', 'projects', 'legion.tools', 'source', 'build_context.v'),
            path.join(rootDir, 'projects', 'legion.tools', 'source', 'build_context.v'),
        ],
    };

    const paths = {};
    const errors = [];
    for (const [name, candidateList] of Object.entries(candidates)) {
        const resolved = resolveFirstExistingPath(name, candidateList);
        if (!resolved.hit) {
            errors.push(...resolved.errors);
            continue;
        }
        paths[name] = resolved.hit;
    }
    const removedMicroCompilerDir = path.join(rootDir, REMOVED_MICRO_COMPILER_PROJECT);

    if (errors.length > 0) {
        console.log('模块系统前置门失败：');
        for (const error of errors) {
            console.log(`  - ${error}`);
        }
        return { success: false, errors };
    }

    const workspaceText = fs.readFileSync(paths.workspaceManifest, 'utf8');
    const legionToolsText = fs.readFileSync(paths.legionToolsManifest, 'utf8');
    const nyarText = fs.readFileSync(paths.nyarManifest, 'utf8');
    const stdText = fs.readFileSync(paths.stdManifest, 'utf8');
    const buildContextText = fs.readFileSync(paths.buildContext, 'utf8');

    if (!/name\s*:\s*"legion\.tools"/.test(legionToolsText)) {
        errors.push('`projects/legion._/projects/legion.tools/legion.von` �?`name` 不是 `legion.tools`');
    }
    if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*false[\s\S]*?\}/m.test(legionToolsText)) {
        errors.push('`legion.tools` 未保�?`auto_link: { core: true, std: false }`');
    }
    for (const dependencyName of ['nyar', 'std', 'std.data.text.von']) {
        if (!hasWorkspaceDependency(legionToolsText, dependencyName)) {
            errors.push(`\`legion.tools\` 缺少显式 workspace 依赖�?{dependencyName}`);
        }
    }

    if (!/name\s*:\s*"nyar"/.test(nyarText)) {
        errors.push('`projects/nyar/legion.von` �?`name` 不是 `nyar`');
    }
    if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*true[\s\S]*?\}/m.test(nyarText)) {
        errors.push('`nyar` 未保�?`auto_link: { core: true, std: true }`');
    }
    if (!/name\s*:\s*"std"/.test(stdText)) {
        errors.push('`projects/std/legion.von` �?`name` 不是 `std`');
    }

    for (const memberPath of ['projects/legion.tools', 'projects/nyar', 'projects/std', 'examples/test.module_system']) {
        if (!workspaceIncludesMemberResolved(workspaceText, memberPath)) {
            errors.push(`workspace 未显式包含成员：${memberPath}`);
        }
    }
    if (workspaceIncludesMember(workspaceText, REMOVED_MICRO_COMPILER_PROJECT)) {
        errors.push(`workspace 仍包含已废弃项目�?{REMOVED_MICRO_COMPILER_PROJECT}`);
    }
    if (fs.existsSync(removedMicroCompilerDir)) {
        errors.push(`已废弃作弊工程仍存在�?{removedMicroCompilerDir}`);
    }

    if (!buildContextText.includes('using nyar;')) {
        errors.push('`build_context.v` 未显�?`using nyar;`');
    }
    for (const requiredSymbol of [
        'micro legion_parse_canonical_target(target: utf8) -> CanonicalTarget {',
        'return parse_target(canonical)',
        'return format_target(parsed)',
        'return default_target()',
    ]) {
        if (!buildContextText.includes(requiredSymbol)) {
            errors.push(`build_context 缺少模块系统契约片段�?{requiredSymbol}`);
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

    console.log('模块系统前置门通过�?);
    console.log('  - `legion.tools` 已显式依�?`nyar`、`std`、`std.data.text.von`');
    console.log('  - workspace 已显式包�?`legion.tools` / `nyar` / `std` / `test.module_system`');
    console.log('  - `micro_compiler` 已从 workspace 与源码树中移�?);
    console.log('  - `build_context.v` 通过 `using nyar;` 显式导入跨模块类型与函数');
    const resolvedPaths = {
        workspaceManifest: paths.workspaceManifest,
        legionToolsManifest: paths.legionToolsManifest,
        nyarManifest: paths.nyarManifest,
        stdManifest: paths.stdManifest,
        buildContext: paths.buildContext,
    };

    return {
        success: true,
        errors: [],
        resolvedPaths,
        detail: [
            '`legion.tools -> nyar/std` 模块依赖、workspace 成员、`micro_compiler` 清退与显式导入契约均已满�?,
            `nyar manifest: ${paths.nyarManifest}`,
            `std manifest: ${paths.stdManifest}`,
        ].join('�?),
    };
}

/// 四目标自举轨配置（统一 gate schema）�?export const BOOTSTRAP_TRACKS = {
    clr: {
        track: 'clr',
        targetTriple: 'clr-microsoft-unknown-managed',
        targetAlias: 'clr',
        profile: 'l2',
        outputSubdir: 'bootstrap-clr',
        v1Gate: '源码 -> v1.clr',
        v2Gate: 'v1 -> v2.clr',
    },
    jvm: {
        track: 'jvm',
        targetTriple: 'jvm-openjdk-unknown-managed',
        targetAlias: 'jvm',
        profile: 'l2',
        outputSubdir: 'bootstrap-jvm',
        v1Gate: '源码 -> v1.jvm',
        v2Gate: 'v1 -> v2.jvm',
    },
    node: {
        track: 'node',
        targetTriple: 'wasm32-node-unknown-wasm',
        targetAlias: 'node',
        profile: 'l2',
        outputSubdir: 'bootstrap-node',
        v1Gate: '源码 -> v1.node',
        v2Gate: 'v1 -> v2.node',
    },
    wasi: {
        track: 'wasi',
        targetTriple: 'wasm32-unknown-wasi-wasip3',
        targetAlias: 'wasip3',
        profile: 'l2',
        outputSubdir: 'bootstrap-wasi',
        v1Gate: '源码 -> v1.wasi',
        v2Gate: 'v1 -> v2.wasi',
    },
};

/// L2 完整七门（CLR / JVM / Node 共享 schema）�?export const L2_GATE_NAMES = [
    '模块系统前置�?,
    '上一代编译器入口',
    null, // v1 gate �?�?track 填入
    'v1 --version',
    'v1 --help',
    null, // v2 gate �?�?track 填入
    'v1 / v2 比对',
];

/// WASI witness 子集（不要求 v1→v2）�?export const WITNESS_GATE_NAMES = [
    '模块系统前置�?,
    '上一代编译器入口',
    '源码 -> v1.wasi',
    'wasmtime --version',
    'wasmtime --help',
    'run-contract 校验',
];

/**
 * �?track 配置构�?L2 gate 名称列表�? * @param {'clr'|'jvm'|'node'|'wasi'} trackKey
 * @returns {string[]}
 */
export function l2GateNamesForTrack(trackKey) {
    const track = BOOTSTRAP_TRACKS[trackKey];
    return [
        '模块系统前置�?,
        '上一代编译器入口',
        track.v1Gate,
        'v1 --version',
        'v1 --help',
        track.v2Gate,
        'v1 / v2 比对',
    ];
}

/**
 * 构造上游门禁未通过时的跳过 gate 列表�? * @param {'clr'|'jvm'|'node'} trackKey
 * @param {number} fromIndex - 从哪一门开始标记跳过（0-based�? * @param {string} reason
 * @returns {Array<{name: string, status: string, detail: string}>}
 */
export function buildSkippedL2Gates(trackKey, fromIndex, reason) {
    const names = l2GateNamesForTrack(trackKey);
    return names.map((name, index) => {
        if (index < fromIndex) {
            return null;
        }
        return createGate(name, index === fromIndex ? '未通过' : '跳过', index === fromIndex ? reason : `${names[fromIndex]}未通过`);
    }).filter(Boolean);
}

/**
 * 校验 bootstrap report 是否满足目标 profile �?gate schema�? * @param {Object} report
 * @param {'l2'|'witness'} profile
 * @param {string[]} [expectedGateNames]
 * @returns {{valid: boolean, errors: string[]}}
 */
export function validateReportGateSchema(report, profile, expectedGateNames = null) {
    const expected = expectedGateNames ?? (profile === 'witness' ? WITNESS_GATE_NAMES : null);
    const errors = [];
    if (!report || typeof report !== 'object') {
        return { valid: false, errors: ['report 缺失或格式无�?] };
    }
    if (!Array.isArray(report.gates)) {
        return { valid: false, errors: ['report.gates 必须为数�?] };
    }
    if (expected) {
        const actual = report.gates.map((gate) => gate.name);
        for (const name of expected) {
            if (!actual.includes(name)) {
                errors.push(`gate schema 缺少�?{name}`);
            }
        }
    }
    if (report.success === true && report.gates.some((gate) => gate.status === '跳过')) {
        errors.push('success=true 但存在跳过的 gate');
    }
    if (report.v2?.compared === false && report.success === true && !(report.blockers?.length > 0)) {
        errors.push('比对未执行但 success=true 且无 blocker');
    }
    return { valid: errors.length === 0, errors };
}

/**
 * �?run-contract 文件读取 physical_entry（任意扩展名）�? * @param {string} contractPath
 * @returns {string|null}
 */
export function readPhysicalEntry(contractPath) {
    if (!fs.existsSync(contractPath)) {
        return null;
    }
    const contractText = fs.readFileSync(contractPath, 'utf8');
    const match = contractText.match(/physical_entry\s*:\s*"([^"]+)"/);
    return match ? match[1] : null;
}

/**
 * 解析 CLR 轨产物入口（legion.exe / legion.msil）�? * @param {string} targetDir
 * @returns {{legionExe: string|null, legionMsil: string|null}}
 */
export function resolveClrEntry(targetDir) {
    const preferred = ['legion.exe', 'legion__main_legion.exe', 'legion.dll', 'legion__main_legion.dll'];
    let legionExe = null;
    for (const name of preferred) {
        const candidate = path.join(targetDir, name);
        if (fs.existsSync(candidate)) {
            legionExe = candidate;
            break;
        }
    }
    if (!legionExe && fs.existsSync(targetDir)) {
        const files = fs
            .readdirSync(targetDir)
            .filter((name) => /^legion.+\.(exe|dll)$/i.test(name) && !/__(?:vcc|voa)/i.test(name))
            .sort();
        const mainEntry = files.find((name) => /main_legion/i.test(name)) || files[0];
        if (mainEntry) {
            legionExe = path.join(targetDir, mainEntry);
        }
    }
    const stem = legionExe ? path.basename(legionExe).replace(/\.(exe|dll)$/i, '') : 'legion';
    const msilCandidates = [path.join(targetDir, `${stem}.msil`), path.join(targetDir, 'legion.msil')];
    const legionMsil = msilCandidates.find((candidate) => fs.existsSync(candidate)) || msilCandidates[1];
    return { legionExe, legionMsil: fs.existsSync(legionMsil) ? legionMsil : null };
}

/**
 * 解析 JVM 轨产物入口（legion.jar �?run-contract 指定）�? * @param {string} targetDir
 * @returns {{legionJar: string|null, physicalEntry: string|null, legacy: boolean}}
 */
export function resolveJvmEntry(targetDir) {
    const canonical = path.join(targetDir, 'legion.jar');
    if (fs.existsSync(canonical)) {
        return { legionJar: canonical, physicalEntry: 'legion.jar', legacy: false };
    }
    for (const contractName of ['run-contracts.txt', 'run-contract.txt']) {
        const physical = readPhysicalEntry(path.join(targetDir, contractName));
        if (physical && physical.endsWith('.jar')) {
            const jarPath = path.join(targetDir, physical);
            if (fs.existsSync(jarPath)) {
                return { legionJar: jarPath, physicalEntry: physical, legacy: false };
            }
        }
    }
    const legacy = path.join(targetDir, 'legion_tools.jar');
    if (fs.existsSync(legacy)) {
        return { legionJar: legacy, physicalEntry: 'legion_tools.jar', legacy: true };
    }
    return { legionJar: null, physicalEntry: null, legacy: false };
}

/**
 * 解析 WASI 轨产物入口（legion.wasi �?run-contract 指定）�? * @param {string} targetDir
 * @returns {{legionWasm: string|null, physicalEntry: string|null, legacy: boolean}}
 */
export function resolveWasiEntry(targetDir) {
    const canonical = path.join(targetDir, 'legion.wasi');
    if (fs.existsSync(canonical)) {
        return { legionWasm: canonical, physicalEntry: 'legion.wasi', legacy: false };
    }
    for (const contractName of ['run-contracts.txt', 'run-contract.txt']) {
        const physical = readPhysicalEntry(path.join(targetDir, contractName));
        if (physical && physical.endsWith('.wasi')) {
            const wasmPath = path.join(targetDir, physical);
            if (fs.existsSync(wasmPath)) {
                return { legionWasm: wasmPath, physicalEntry: physical, legacy: false };
            }
        }
    }
    // Nullary WASI command partitions (e.g. main_wasi_run) may be non-primary;
    // accept any packaged .wasi when canonical/run-contract lookup misses.
    if (fs.existsSync(targetDir)) {
        const wasiFiles = fs
            .readdirSync(targetDir)
            .filter((name) => name.endsWith('.wasi'))
            .sort((a, b) => {
                const score = (name) => (/wasi_run/i.test(name) ? 0 : /main_legion/i.test(name) ? 2 : 1);
                return score(a) - score(b) || a.localeCompare(b);
            });
        if (wasiFiles.length > 0) {
            return { legionWasm: path.join(targetDir, wasiFiles[0]), physicalEntry: wasiFiles[0], legacy: false };
        }
    }
    return { legionWasm: null, physicalEntry: null, legacy: false };
}

/**
 * 校验 run-contract 是否使用 canonical legion.* 命名（禁�?legion_tools.*）�? * @param {string} targetDir
 * @returns {{valid: boolean, errors: string[]}}
 */
export function validateCanonicalRunContract(targetDir) {
    const errors = [];
    for (const contractName of ['run-contracts.txt', 'run-contract.txt']) {
        const contractPath = path.join(targetDir, contractName);
        if (!fs.existsSync(contractPath)) {
            continue;
        }
        const text = fs.readFileSync(contractPath, 'utf8');
        if (/legion_tools\./.test(text)) {
            errors.push(`${contractName} 含非 canonical 入口 legion_tools.*`);
        }
    }
    return { valid: errors.length === 0, errors };
}
