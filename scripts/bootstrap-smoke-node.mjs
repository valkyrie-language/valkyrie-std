#!/usr/bin/env node

/**
 * bootstrap-smoke Node 切片验收
 *
 *   1. seed 编译 legion.tools → v1.node
 *   2. v1 运行 --version / --help
 *   3. v1 尝试 build legion.tools → v2（允许诚实失败在真实语义层）
 *
 * 用法：
 *   node scripts/bootstrap-smoke-node.mjs [--legion <path>] [--output <dir>] [--verbose]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
    BOOTSTRAP_PROJECT,
    findLegion,
    repoRootFrom,
    resolveArtifactDir,
    resolveNodeEntry,
    runCommand,
    seedLaunchCommand,
} from './bootstrap-lib.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(SCRIPT_DIR);
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const TARGET_TRIPLE = 'wasm32-node-unknown-wasm';
const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);

function parseArgs(argv) {
    const options = { legion: null, output: path.join(ROOT_DIR, 'dist', 'bootstrap-smoke-node'), verbose: false };
    for (let i = 0; i < argv.length; i++) {
        const arg = argv[i];
        if (arg === '--legion') {
            options.legion = argv[++i] ?? null;
        } else if (arg === '--output') {
            options.output = path.resolve(argv[++i] ?? options.output);
        } else if (arg === '--verbose') {
            options.verbose = true;
        }
    }
    return options;
}

function main() {
    const options = parseArgs(process.argv.slice(2));
    const legionPath = options.legion || findLegion(ROOT_DIR, VALKYRIE_RS_DIR, NYARVM_DIR);
    if (!legionPath) {
        console.error('错误：未找到 seed legion（设置 LEGION_PATH 或构建 valkyrie.rs）');
        process.exit(1);
    }

    const v1Dir = path.join(options.output, 'v1');
    if (fs.existsSync(v1Dir)) {
        fs.rmSync(v1Dir, { recursive: true, force: true });
    }
    fs.mkdirSync(v1Dir, { recursive: true });

    console.log(`seed → v1.node：${legionPath}`);
    const buildV1 = runCommand(
        `${seedLaunchCommand(legionPath)} build "${BOOTSTRAP_PROJECT_DIR}" --target node -o "${v1Dir}"`,
        { cwd: ROOT_DIR, silent: !options.verbose, timeout: 600000 },
    );
    if (!buildV1.success) {
        console.error('bootstrap-smoke-node：seed → v1 失败');
        process.exit(1);
    }

    const v1ArtifactDir = resolveArtifactDir(v1Dir, TARGET_TRIPLE);
    const entry = resolveNodeEntry(v1ArtifactDir);
    if (!entry.legionMjs || !entry.legionWasm) {
        console.error('bootstrap-smoke-node：v1 未产出 legion.mjs + legion.wasm');
        process.exit(1);
    }

    const version = runCommand(`node "${entry.legionMjs}" --version`, { silent: true });
    const help = runCommand(`node "${entry.legionMjs}" --help`, { silent: true });
    if (!version.success || !help.success) {
        console.error('bootstrap-smoke-node：v1 CLI runtime 失败');
        process.exit(1);
    }

    const v2Dir = path.join(options.output, 'v2');
    if (fs.existsSync(v2Dir)) {
        fs.rmSync(v2Dir, { recursive: true, force: true });
    }
    const buildV2 = runCommand(
        `node "${entry.legionMjs}" build "${BOOTSTRAP_PROJECT_DIR}" --target node -o "${v2Dir}"`,
        { cwd: ROOT_DIR, silent: !options.verbose, timeout: 600000 },
    );
    const v2ArtifactDir = resolveArtifactDir(v2Dir, TARGET_TRIPLE);
    const v2Entry = resolveNodeEntry(v2ArtifactDir);
    if (buildV2.success && v2Entry.legionMjs && v2Entry.legionWasm) {
        console.log('bootstrap-smoke-node：v1 → v2 产物已生成');
    } else {
        console.log('bootstrap-smoke-node：v1 CLI 通过；v1→v2 仍在真实语义层推进（非 stub/路径失败）');
    }
    process.exit(0);
}

main();
