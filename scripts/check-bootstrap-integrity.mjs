#!/usr/bin/env node

/**
 * 自举反作弊机读检查
 *
 * 扫描源码与产物，禁止 build stub / bridge 代编译 / 非 canonical 入口。
 *
 * 用法：
 *   node scripts/check-bootstrap-integrity.mjs [--repo-root <path>] [--artifact-dir <path>]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
    AD_HOC_SCRIPT_ENTRIES,
    BOOTSTRAP_TRACKS,
    collectFiles,
    l2GateNamesForTrack,
    OFFICIAL_SCRIPT_ENTRIES,
    repoRootFrom,
    validateCanonicalRunContract,
    validateReportGateSchema,
    WITNESS_GATE_NAMES,
} from './bootstrap-lib.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_ROOT = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(DEFAULT_ROOT, '..', 'valkyrie.rs');

/// 源码 stub / 边界回退模式。
///
/// 每条规则指定一个源文件与若干正则；命中即视为违规。`stripTestModule` 为 `true`
/// 时，扫描前先剔除 `#[cfg(test)]` 及其之后的测试模块，避免测试断言被误判。
const SOURCE_STUB_PATTERNS = [
    {
        file: 'projects/emitter/src/backend/wasm_js_glue/mod.rs',
        patterns: [
            /instantiate\(wasmBytes,\s*\{\s*\}\)/,
            /return\s+0\s*;\s*\/\/\s*build stub/i,
        ],
    },
    {
        file: 'projects/emitter/src/lowering/backends/wasm/mir.rs',
        patterns: [
            /exports\.push\(\("build",\s*0x00,\s*0\)\)/,
        ],
    },
    {
        file: 'projects/emitter/src/lowering/backends/wasm/mod.rs',
        patterns: [
            /"legion\.[a-z_.]+"/,
        ],
    },
    {
        file: 'projects/emitter/src/lowering/shared/interop.rs',
        patterns: [
            /wasi_snapshot_preview1/,
        ],
    },
    {
        file: 'projects/emitter/src/backend/wasi/component.rs',
        patterns: [
            /WasiComponentBindingBuilder/,
        ],
    },
    {
        file: 'projects/emitter/src/backend/wasi/mod.rs',
        patterns: [
            /main_legion/,
            /legion\.tools/,
        ],
    },
    {
        file: 'projects/emitter/src/driver/families/wasm.rs',
        patterns: [
            /main_legion/,
            /legion\.tools/,
        ],
        stripTestModule: true,
    },
];

/// 必须存在的遗留路径标注。
///
/// 历史要求：`wasi_cm.rs` 保留 `// LEGACY: wasi-interop-no-output`。
/// 2026-07 wasm 后端重组后，宿主壳迁至 `wasm/host/wasi_cm.rs`，且遗留标记已退役；
/// 此表置空。若再引入临时逃生舱，应在此重新登记标注。
const REQUIRED_ANNOTATIONS = [];

/// 遗留函数引用点冻结配置。
///
/// `lower_fragment_to_wasi_module` 已删除；基线为 0（不得再出现）。
const LEGACY_PATH_FREEZE = {
    function: 'lower_fragment_to_wasi_module',
    searchDir: 'projects/emitter',
    baselineCount: 0,
    knownSites: [],
};

const FORBIDDEN_ARTIFACT_NAMES = [
    /^legion_tools\.mjs$/i,
    /^legion_tools\.wasm$/i,
    /^legion_tools\.jar$/i,
];

function parseArgs() {
    const options = { repoRoot: DEFAULT_ROOT, artifactDirs: [] };
    const argv = process.argv.slice(2);
    for (let index = 0; index < argv.length; index += 1) {
        const arg = argv[index];
        if (arg === '--repo-root' && argv[index + 1]) {
            options.repoRoot = path.resolve(argv[++index]);
        } else if (arg === '--artifact-dir' && argv[index + 1]) {
            options.artifactDirs.push(path.resolve(argv[++index]));
        }
    }
    return options;
}

/// 剔除 Rust 源文件中的 `#[cfg(test)]` 测试模块。
///
/// 测试模块中的断言（如 `assert_eq!(fn("main_legion"), "main_legion")`）不应
/// 被边界扫描误判为产品特判回退。
function stripRustTestModule(text) {
    const marker = '#[cfg(test)]';
    const index = text.indexOf(marker);
    if (index === -1) {
        return text;
    }
    return text.slice(0, index);
}

function scanSourceStubs(valkyrieRsDir) {
    const violations = [];
    for (const { file, patterns, stripTestModule: shouldStrip } of SOURCE_STUB_PATTERNS) {
        const fullPath = path.join(valkyrieRsDir, file);
        if (!fs.existsSync(fullPath)) {
            continue;
        }
        let text = fs.readFileSync(fullPath, 'utf8');
        if (shouldStrip) {
            text = stripRustTestModule(text);
        }
        for (const pattern of patterns) {
            if (pattern.test(text)) {
                violations.push(`源码 stub 检出：${file} 匹配 ${pattern}`);
            }
        }
    }
    return violations;
}

/// 扫描必须存在的遗留路径标注。
///
/// 标注缺失即视为遗留路径被静默移除（回退风险）。
function scanRequiredAnnotations(valkyrieRsDir) {
    const violations = [];
    for (const { file, annotation, description } of REQUIRED_ANNOTATIONS) {
        const fullPath = path.join(valkyrieRsDir, file);
        if (!fs.existsSync(fullPath)) {
            violations.push(`必要标注缺失：${file} 不存在（${description}）`);
            continue;
        }
        const text = fs.readFileSync(fullPath, 'utf8');
        if (!text.includes(annotation)) {
            violations.push(`必要标注缺失：${file} 缺少 ${annotation}（${description}）`);
        }
    }
    return violations;
}

/// 扫描遗留函数引用点，冻结调用范围。
///
/// 遗留函数 `lower_fragment_to_wasi_module` 已被替代，当前仅允许在
/// `wasi_cm.rs` 注释中出现。引用点数量超过基线即视为遗留路径扩散。
function scanLegacyPathFreeze(valkyrieRsDir) {
    const violations = [];
    const searchDir = path.join(valkyrieRsDir, LEGACY_PATH_FREEZE.searchDir);
    if (!fs.existsSync(searchDir)) {
        return violations;
    }
    const rsFiles = collectFiles(searchDir, ['.rs']);
    const sites = [];
    for (const filePath of rsFiles) {
        const text = fs.readFileSync(filePath, 'utf8');
        const lines = text.split('\n');
        for (let i = 0; i < lines.length; i += 1) {
            if (lines[i].includes(LEGACY_PATH_FREEZE.function)) {
                const relativePath = path.relative(valkyrieRsDir, filePath).replace(/\\/g, '/');
                sites.push(`${relativePath}:${i + 1}`);
            }
        }
    }
    if (sites.length > LEGACY_PATH_FREEZE.baselineCount) {
        const newSites = sites.filter((site) => !LEGACY_PATH_FREEZE.knownSites.includes(site));
        violations.push(
            `遗留路径调用点冻结失败：${LEGACY_PATH_FREEZE.function} 引用点 ${sites.length} > 基线 ${LEGACY_PATH_FREEZE.baselineCount}`
            + (newSites.length > 0 ? `（新增：${newSites.join(', ')}）` : ''),
        );
    }
    return violations;
}

/// 运行 wasm/wasi 专项反作弊检查，供 `monthly-matrix.mjs` / `bootstrap-wasi-witness.mjs` 复用。
///
/// 仅覆盖 wasm/wasi 边界规则（源码 stub、必要标注、遗留路径冻结），
/// 不包含脚本治理与产物检查（这些由 `main()` 独立执行）。
/// @param {string} valkyrieRsDir - `valkyrie.rs` 仓库根绝对路径
/// @returns {{passed: boolean, violations: string[]}}
export function runWasiAntiCheatChecks(valkyrieRsDir) {
    const violations = [
        ...scanSourceStubs(valkyrieRsDir),
        ...scanRequiredAnnotations(valkyrieRsDir),
        ...scanLegacyPathFreeze(valkyrieRsDir),
    ];
    return {
        passed: violations.length === 0,
        violations,
    };
}

function scanForbiddenArtifactNames(artifactDir) {
    const violations = [];
    if (!fs.existsSync(artifactDir)) {
        return violations;
    }
    for (const entry of fs.readdirSync(artifactDir)) {
        if (FORBIDDEN_ARTIFACT_NAMES.some((pattern) => pattern.test(entry))) {
            violations.push(`${artifactDir}：禁止非 canonical 入口 ${entry}`);
        }
    }
    return violations;
}

function scanNodeArtifact(artifactDir) {
    const violations = [...scanForbiddenArtifactNames(artifactDir)];
    const mjsPath = path.join(artifactDir, 'legion.mjs');
    if (!fs.existsSync(mjsPath)) {
        return violations;
    }
    const text = fs.readFileSync(mjsPath, 'utf8');
    if (/instantiate\(\{\}\)/.test(text) || /WebAssembly\.instantiate\([^,]+,\s*\{\s*\}\)/.test(text)) {
        violations.push(`${mjsPath}：空 imports instantiate（build stub）`);
    }
    if (text.includes('firstArg === "build"') && !/exports\.build/.test(text)) {
        violations.push(`${mjsPath}：build 子命令存在但未调用 exports.build`);
    }
    if (!/hostReadFileText|hostFileExists|hostGetCurrentDirectory/.test(text)) {
        violations.push(`${mjsPath}：缺少 FS host imports`);
    }
    const contract = validateCanonicalRunContract(artifactDir);
    if (!contract.valid) {
        violations.push(...contract.errors.map((error) => `${artifactDir}：${error}`));
    }
    return violations;
}

function scanBootstrapScriptCheats(repoRoot) {
    const violations = [];
    const scriptNames = ['bootstrap-clr.mjs', 'bootstrap-jvm.mjs', 'bootstrap-node.mjs'];
    for (const scriptName of scriptNames) {
        const scriptPath = path.join(repoRoot, 'scripts', scriptName);
        if (!fs.existsSync(scriptPath)) {
            continue;
        }
        const text = fs.readFileSync(scriptPath, 'utf8');
        if (/success:\s*true/.test(text) && /v2Result\s*=\s*null/.test(text) && !/blockers\.length\s*===\s*0/.test(text)) {
            violations.push(`${scriptName}：可能存在跳过 v1->v2 仍报 success 的路径`);
        }
        if (/legion_tools/.test(text) && !/legacy|禁止|hard fail|LEGACY_ENTRY/.test(text)) {
            violations.push(`${scriptName}：仍引用 legion_tools.* 且未标注 legacy 阻断`);
        }
    }
    return violations;
}

function scanAdHocScriptEntries(repoRoot) {
    const violations = [];
    const scriptsDir = path.join(repoRoot, 'scripts');
    for (const entry of AD_HOC_SCRIPT_ENTRIES) {
        const fullPath = path.join(scriptsDir, entry);
        if (fs.existsSync(fullPath)) {
            violations.push(`scripts/${entry}：禁止保留临时手工分析器，请改用 legion spy 或正式 bootstrap 脚本`);
        }
    }
    return violations;
}

function scanUnexpectedScriptEntries(repoRoot) {
    const violations = [];
    const scriptsDir = path.join(repoRoot, 'scripts');
    if (!fs.existsSync(scriptsDir)) {
        return violations;
    }
    const actualEntries = fs.readdirSync(scriptsDir).sort();
    const allowed = new Set(OFFICIAL_SCRIPT_ENTRIES);
    for (const entry of actualEntries) {
        if (!allowed.has(entry)) {
            violations.push(`scripts/${entry}：不在正式脚本白名单内，请移出 scripts/ 或纳入 OFFICIAL_SCRIPT_ENTRIES`);
        }
    }
    return violations;
}

function scanBootstrapReports(repoRoot) {
    const violations = [];
    const reportSpecs = [
        { track: 'clr', dir: BOOTSTRAP_TRACKS.clr.outputSubdir, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('clr') },
        { track: 'jvm', dir: BOOTSTRAP_TRACKS.jvm.outputSubdir, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('jvm') },
        { track: 'node', dir: BOOTSTRAP_TRACKS.node.outputSubdir, profile: 'l2', file: 'bootstrap-report.json', gateNames: l2GateNamesForTrack('node') },
        { track: 'wasi', dir: BOOTSTRAP_TRACKS.wasi.outputSubdir, profile: 'witness', file: BOOTSTRAP_TRACKS.wasi.reportFile, gateNames: WITNESS_GATE_NAMES },
    ];

    for (const spec of reportSpecs) {
        const reportPath = path.join(repoRoot, 'dist', spec.dir, spec.file);
        if (!fs.existsSync(reportPath)) {
            continue;
        }
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        const schema = validateReportGateSchema(report, spec.profile, spec.gateNames);
        if (!schema.valid) {
            violations.push(...schema.errors.map((error) => `${spec.track} report：${error}`));
        }
        if (report.success === true && Array.isArray(report.gates) && report.gates.some((gate) => gate.status === '跳过')) {
            violations.push(`${spec.track} report：success=true 但存在跳过的 gate`);
        }
        if (report.profile === 'l2' && report.success === true && report.v2?.attempted !== true) {
            violations.push(`${spec.track} report：L2 success=true 但 v2 未尝试`);
        }
        if (report.profile === 'l2' && report.success === true && report.v2?.compared !== true) {
            violations.push(`${spec.track} report：L2 success=true 但未完成 compare`);
        }
        if (report.bridgeDetected === true) {
            violations.push(`${spec.track} report：bridge 代编译检出`);
        }
        if (!report.matrix || typeof report.matrix !== 'object') {
            violations.push(`${spec.track} report：缺少 matrix 六栏`);
        }
    }
    return violations;
}

function main() {
    const options = parseArgs();
    const valkyrieRsDir = path.resolve(options.repoRoot, '..', 'valkyrie.rs');
    const violations = [
        ...scanSourceStubs(valkyrieRsDir),
        ...scanRequiredAnnotations(valkyrieRsDir),
        ...scanLegacyPathFreeze(valkyrieRsDir),
        ...scanBootstrapReports(options.repoRoot),
        ...scanBootstrapScriptCheats(options.repoRoot),
        ...scanAdHocScriptEntries(options.repoRoot),
        ...scanUnexpectedScriptEntries(options.repoRoot),
    ];

    for (const artifactDir of options.artifactDirs) {
        violations.push(...scanNodeArtifact(artifactDir));
        violations.push(...scanForbiddenArtifactNames(artifactDir));
    }

    const defaultNodeDirs = [
        path.join(options.repoRoot, 'dist', 'bootstrap-node', 'v1'),
        path.join(options.repoRoot, 'dist', 'bootstrap-node', 'v2'),
    ];
    for (const artifactDir of defaultNodeDirs) {
        if (fs.existsSync(artifactDir)) {
            violations.push(...scanNodeArtifact(artifactDir));
        }
    }

    if (violations.length > 0) {
        console.error('反作弊检查失败：');
        for (const violation of violations) {
            console.error(`  - ${violation}`);
        }
        process.exit(1);
    }

    console.log('反作弊检查通过：未发现 stub / bridge / 非 canonical 入口 / 临时手工分析器 / 边界回退');
}

const __scriptPath = fileURLToPath(import.meta.url);
const __entryPath = process.argv[1] ? path.resolve(process.argv[1]) : '';
if (__entryPath === __scriptPath) {
    main();
}
