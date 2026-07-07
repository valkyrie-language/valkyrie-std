#!/usr/bin/env node
/**
 * 重建 seed 编译器（legion.exe）并跑 node 轨自举。
 *
 * 流程：
 *   1. cargo build --release -p legion  （让 Rust 修改生效）
 *   2. node scripts/bootstrap-node.mjs --verbose
 *
 * 用法： node scripts/_rebuild_and_bootstrap.mjs [--skip-build]
 */
import { spawnSync } from 'child_process';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const RELEASE_EXE = path.join(VALKYRIE_RS_DIR, 'target', 'release', 'legion.exe');

const args = process.argv.slice(2);
const skipBuild = args.includes('--skip-build');

function run(cmd, cmdArgs, options = {}) {
    console.log(`\n$ ${cmd} ${cmdArgs.join(' ')}`);
    const result = spawnSync(cmd, cmdArgs, {
        stdio: 'inherit',
        encoding: 'utf8',
        cwd: VALKYRIE_RS_DIR,
        ...options,
    });
    return result;
}

// 1. cargo build -p legion --release
if (!skipBuild) {
    console.log('══════════════════════════════════════════════════');
    console.log('  Step 1: cargo clean && cargo build -p legion --release');
    console.log('══════════════════════════════════════════════════');
    // 完全清理，避免 rustc 增量缓存导致诊断与源码不一致
    const cleanResult = run('cargo', ['clean'], { timeout: 120000 });
    if (cleanResult.status !== 0) {
        console.error(`\n⚠ cargo clean 失败 (exit ${cleanResult.status})，继续 build`);
    }
    const buildResult = run('cargo', ['build', '-p', 'legion', '--release'], {
        timeout: 900000,
    });
    if (buildResult.status !== 0) {
        console.error(`\n✗ cargo build 失败 (exit ${buildResult.status})`);
        process.exit(buildResult.status ?? 1);
    }
    console.log(`\n✓ legion.exe 已更新: ${RELEASE_EXE}`);
} else {
    console.log(`跳过 cargo build，使用现有 legion.exe: ${RELEASE_EXE}`);
}

if (!fs.existsSync(RELEASE_EXE)) {
    console.error(`✗ 找不到 legion.exe: ${RELEASE_EXE}`);
    process.exit(1);
}

// 2. 检查 legion --version
console.log('\n══════════════════════════════════════════════════');
console.log('  Step 2: legion --version (seed 自检)');
console.log('══════════════════════════════════════════════════');
const versionResult = run(RELEASE_EXE, ['--version'], { timeout: 10000 });
if (versionResult.status !== 0) {
    console.error(`\n✗ seed 不可用 (exit ${versionResult.status})`);
    process.exit(versionResult.status ?? 1);
}

// 3. node scripts/bootstrap-node.mjs --verbose
console.log('\n══════════════════════════════════════════════════');
console.log('  Step 3: node scripts/bootstrap-node.mjs --verbose');
console.log('══════════════════════════════════════════════════');
const bootstrapScript = path.join(SCRIPT_DIR, 'bootstrap-node.mjs');
const bootstrapResult = run('node', [bootstrapScript, '--verbose'], {
    cwd: ROOT_DIR,
    timeout: 600000,
});
process.exit(bootstrapResult.status ?? 0);
