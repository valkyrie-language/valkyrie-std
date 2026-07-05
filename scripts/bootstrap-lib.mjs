/**
 * Shared helpers for bootstrap acceptance scripts (CLR / Node).
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

export const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));

export function repoRootFrom(scriptDir = SCRIPT_DIR) {
    return path.resolve(scriptDir, '..');
}

export const BOOTSTRAP_PROJECT = 'projects/legion.tools';
export const REMOVED_MICRO_COMPILER_PROJECT = 'projects/micro_compiler';

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

export function shortenText(value, maxChars = 240) {
    const text = String(value || '').trim();
    if (text.length <= maxChars) {
        return text;
    }
    return `${text.slice(0, maxChars)}...`;
}

export function createGate(name, status, detail) {
    return { name, status, detail };
}

export function writeReport(outputRoot, payload) {
    fs.mkdirSync(outputRoot, { recursive: true });
    const reportPath = path.join(outputRoot, 'bootstrap-report.json');
    fs.writeFileSync(reportPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
    return reportPath;
}

export function printGateSummary(gates) {
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

function escapeRegex(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function readText(filePath) {
    return fs.readFileSync(filePath, 'utf8');
}

function parsePackageName(manifestText) {
    const match = manifestText.match(/name\s*:\s*"([^"]+)"/);
    return match ? match[1] : null;
}

function parseLegionsMembers(workspaceText) {
    const members = [];
    const membersMatch = workspaceText.match(/members\s*:\s*\[([\s\S]*?)\]/m);
    if (!membersMatch) {
        return members;
    }
    const pattern = /"([^"]+)"/g;
    let item;
    while ((item = pattern.exec(membersMatch[1])) !== null) {
        members.push(item[1]);
    }
    return members;
}

/**
 * Recursively enumerate workspace package directories that contain legion.von.
 * Mirrors Rust planner nested legions discovery.
 */
export function enumerateWorkspacePackages(workspaceRoot) {
    const packages = [];

    function visit(workspaceDir) {
        const legionsPath = path.join(workspaceDir, 'legions.von');
        if (!fs.existsSync(legionsPath)) {
            return;
        }

        const workspaceText = readText(legionsPath);
        for (const member of parseLegionsMembers(workspaceText)) {
            const memberDir = path.resolve(workspaceDir, member);
            const nestedLegions = path.join(memberDir, 'legions.von');
            if (fs.existsSync(nestedLegions)) {
                visit(memberDir);
            }
            const manifestPath = path.join(memberDir, 'legion.von');
            if (!fs.existsSync(manifestPath)) {
                continue;
            }
            const manifestText = readText(manifestPath);
            const packageName = parsePackageName(manifestText);
            packages.push({
                dir: memberDir,
                manifestPath,
                name: packageName,
                basename: path.basename(memberDir),
                member,
            });
        }
    }

    visit(path.resolve(workspaceRoot));
    return packages;
}

function packageByName(packages, name) {
    return packages.find((item) => item.name === name) ?? null;
}

function hasWorkspaceDependency(manifestText, dependencyName) {
    const pattern = new RegExp(`"${escapeRegex(dependencyName)}"\\s*:\\s*\\{[\\s\\S]*?version\\s*:\\s*"workspace"`, 'm');
    return pattern.test(manifestText);
}

function workspaceTextIncludesMember(workspaceText, memberPath) {
    const pattern = new RegExp(`"${escapeRegex(memberPath)}"`);
    return pattern.test(workspaceText);
}

/**
 * Module-system guard shared by CLR and Node bootstrap tracks.
 */
export function validateModuleSystem(rootDir, verbose = false) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  模块系统前置门');
    console.log('══════════════════════════════════════════════════\n');

    const workspaceManifestPath = path.join(rootDir, 'legions.von');
    const removedMicroCompilerDir = path.join(rootDir, 'projects', 'micro_compiler');
    const moduleSystemExample = path.join(rootDir, 'examples', 'test.module_system', 'legion.von');

    const errors = [];
    if (!fs.existsSync(workspaceManifestPath)) {
        errors.push(`缺少必要文件：legions.von -> ${workspaceManifestPath}`);
        return { success: false, errors };
    }

    const workspaceText = readText(workspaceManifestPath);
    const packages = enumerateWorkspacePackages(rootDir);
    const packageIndex = new Map();
    for (const item of packages) {
        if (item.name) {
            packageIndex.set(item.name, item);
        }
        packageIndex.set(item.basename, item);
    }

    const legionTools = packageByName(packages, 'legion.tools');
    const nyar = packageByName(packages, 'nyar');
    const std = packageByName(packages, 'std');

    if (!legionTools) {
        errors.push('workspace 中未找到 `name: "legion.tools"` 成员包');
    }
    if (!nyar) {
        errors.push('workspace 中未找到 `name: "nyar"` 成员包');
    }
    if (!std) {
        errors.push('workspace 中未找到 `name: "std"` 成员包');
    }
    if (!fs.existsSync(moduleSystemExample)) {
        errors.push(`缺少模块系统示例：${moduleSystemExample}`);
    }

    if (legionTools) {
        const legionToolsText = readText(legionTools.manifestPath);
        const buildContextPath = path.join(legionTools.dir, 'source', 'build_context.v');
        if (!fs.existsSync(buildContextPath)) {
            errors.push(`legion.tools 缺少 build_context.v：${buildContextPath}`);
        }
        else {
            const buildContextText = readText(buildContextPath);
            if (!/using\s+nyar\b/.test(buildContextText)) {
                errors.push('`build_context.v` 未显式 `using nyar`');
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
        }

        if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*false[\s\S]*?\}/m.test(legionToolsText)) {
            errors.push('`legion.tools` 未保持 `auto_link: { core: true, std: false }`');
        }
        for (const dependencyName of ['nyar', 'std', 'std.data.text.von']) {
            if (!hasWorkspaceDependency(legionToolsText, dependencyName)) {
                errors.push(`\`legion.tools\` 缺少显式 workspace 依赖：${dependencyName}`);
            }
        }
    }

    if (nyar) {
        const nyarText = readText(nyar.manifestPath);
        if (!/auto_link\s*:\s*\{[\s\S]*?core\s*:\s*true[\s\S]*?std\s*:\s*true[\s\S]*?\}/m.test(nyarText)) {
            errors.push('`nyar` 未保持 `auto_link: { core: true, std: true }`');
        }
    }

    if (workspaceTextIncludesMember(workspaceText, REMOVED_MICRO_COMPILER_PROJECT)) {
        errors.push(`workspace 仍包含已废弃项目：${REMOVED_MICRO_COMPILER_PROJECT}`);
    }
    if (fs.existsSync(removedMicroCompilerDir)) {
        errors.push(`已废弃作弊工程仍存在：${removedMicroCompilerDir}`);
    }

    if (verbose) {
        console.log(`workspace manifest: ${workspaceManifestPath}`);
        console.log(`discovered packages: ${packages.length}`);
        for (const item of packages) {
            console.log(`  - ${item.name ?? '(unnamed)'} @ ${item.dir}`);
        }
        console.log(`module system example: ${moduleSystemExample}`);
    }

    if (errors.length > 0) {
        console.log('模块系统前置门失败：');
        for (const error of errors) {
            console.log(`  - ${error}`);
        }
        return { success: false, errors };
    }

    console.log('模块系统前置门通过：');
    console.log('  - workspace 已解析 `legion.tools` / `nyar` / `std` 成员包');
    console.log('  - `examples/test.module_system` 存在');
    console.log('  - `legion.tools` 已显式依赖 `nyar`、`std`、`std.data.text.von`');
    console.log('  - `micro_compiler` 已从 workspace 与源码树中移除');
    console.log('  - `build_context.v` 通过 `using nyar` 显式导入跨模块类型与函数');
    return {
        success: true,
        errors: [],
        detail: '递归 workspace 成员、`legion.tools -> nyar/std` 依赖与显式导入契约均已满足',
    };
}

export function seedLaunchCommand(legionPath) {
    const lower = legionPath.toLowerCase();
    if (lower.endsWith('.dll')) {
        return `dotnet exec "${legionPath}"`;
    }
    return `"${legionPath}"`;
}

export function legionLauncherCandidates(baseDir) {
    return [
        path.join(baseDir, 'legion.exe'),
        path.join(baseDir, 'legion'),
        path.join(baseDir, 'legion.dll'),
    ];
}

export function resolveLegionLauncher(baseDir) {
    for (const candidate of legionLauncherCandidates(baseDir)) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return null;
}

/**
 * Resolve seed compiler: LEGION_PATH, Rust build, dist, NyarVM.cs publish.
 */
export function findLegion(rootDir, valkyrieRsDir, nyarvmDir) {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidates = [
        ...legionLauncherCandidates(path.join(valkyrieRsDir, 'target', 'release')),
        ...legionLauncherCandidates(path.join(valkyrieRsDir, 'target', 'debug')),
        ...legionLauncherCandidates(path.join(rootDir, 'dist', 'legion')),
        ...legionLauncherCandidates(path.join(rootDir, 'dist', 'legion-tool')),
        ...legionLauncherCandidates(path.join(nyarvmDir, 'tools', 'legion', 'publish')),
        ...legionLauncherCandidates(path.join(nyarvmDir, 'tools', 'legion', '.artifacts', 'bin', 'Release', 'net10.0')),
        ...legionLauncherCandidates(path.join(nyarvmDir, 'tools', 'legion', '.artifacts', 'bin', 'Debug', 'net10.0')),
        ...legionLauncherCandidates(path.join(nyarvmDir, 'tools', 'legion', 'bin', 'Release', 'net10.0')),
        ...legionLauncherCandidates(path.join(nyarvmDir, 'tools', 'legion', 'bin', 'Debug', 'net10.0')),
    ];
    for (const candidate of candidates) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return null;
}

export function collectFiles(dir, extensions) {
    const results = [];
    if (!fs.existsSync(dir)) {
        return results;
    }
    const extSet = new Set(extensions.map((ext) => ext.toLowerCase()));
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

export function computeFileHash(filePath) {
    const content = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(content).digest('hex');
}

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

/** Flat `-o` dir or legacy `{out}/{triple}/` layout. */
export function resolveArtifactDir(outputDir, targetTriple) {
    const legacyDir = path.join(outputDir, targetTriple);
    if (fs.existsSync(legacyDir)) {
        return legacyDir;
    }
    return outputDir;
}

/** Node track: `legion.mjs` + `legion.wasm` (or partitioned `legion__main_legion.*`). */
export function resolveNodeEntry(artifactDir) {
    const preferredMjs = ['legion.mjs', 'legion__main_legion.mjs'];
    const preferredWasm = ['legion.wasm', 'legion__main_legion.wasm'];

    let legionMjs = null;
    for (const name of preferredMjs) {
        const candidate = path.join(artifactDir, name);
        if (fs.existsSync(candidate)) {
            legionMjs = candidate;
            break;
        }
    }

    let legionWasm = null;
    for (const name of preferredWasm) {
        const candidate = path.join(artifactDir, name);
        if (fs.existsSync(candidate)) {
            legionWasm = candidate;
            break;
        }
    }

    if (!legionMjs && fs.existsSync(artifactDir)) {
        const files = fs
            .readdirSync(artifactDir)
            .filter((name) => name.endsWith('.mjs') && !/__(?:vcc|voa)/i.test(name))
            .sort();
        const mainEntry = files.find((name) => /main_legion/i.test(name)) || files[0];
        if (mainEntry) {
            legionMjs = path.join(artifactDir, mainEntry);
        }
    }

    if (!legionWasm && legionMjs) {
        const stem = path.basename(legionMjs, '.mjs');
        const sibling = path.join(artifactDir, `${stem}.wasm`);
        if (fs.existsSync(sibling)) {
            legionWasm = sibling;
        }
    }

    return { legionMjs, legionWasm };
}
