#!/usr/bin/env node
/**
 * 杀掉残留的 cargo/rustc 进程，然后重试构建。
 *
 * 用法： node scripts/_kill_and_retry.mjs
 */
import { spawnSync } from 'child_process';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const RELEASE_EXE = path.join(VALKYRIE_RS_DIR, 'target', 'release', 'legion.exe');

function run(cmd, cmdArgs, options = {}) {
    console.log(`\n$ ${cmd} ${cmdArgs.join(' ')}`);
    const result = spawnSync(cmd, cmdArgs, {
        stdio: 'inherit',
        encoding: 'utf8',
        ...options,
    });
    return result;
}

function killProcess(name) {
    // 用 taskkill 杀进程，不依赖 pwsh
    const result = spawnSync('taskkill', ['/F', '/IM', name, '/T'], {
        stdio: 'pipe',
        encoding: 'utf8',
    });
    if (result.status === 0) {
        console.log(`✓ 已杀掉 ${name}`);
    } else {
        console.log(`- ${name} 无残留或杀失败 (exit ${result.status})`);
    }
}

// 1. 杀掉残留进程
console.log('══════════════════════════════════════════════════');
console.log('  Step 1: 清理残留 cargo/rustc/link 进程');
console.log('══════════════════════════════════════════════════');
killProcess('cargo.exe');
killProcess('rustc.exe');
killProcess('rustdoc.exe');
killProcess('link.exe');
killProcess('ld.exe');

// 2. 等待文件句柄释放
console.log('\n等待 2 秒让文件句柄释放...');
await new Promise(r => setTimeout(r, 2000));

// 3. 删除可能锁定的 DLL（可选，失败也无所谓）
const dllPath = path.join(VALKYRIE_RS_DIR, 'target', 'release', 'deps', 'thiserror_impl-17cf2d766233429f.dll');
if (fs.existsSync(dllPath)) {
    try {
        fs.unlinkSync(dllPath);
        console.log(`✓ 已删除残留 DLL: ${path.basename(dllPath)}`);
    } catch (e) {
        console.log(`- 无法删除 ${path.basename(dllPath)}: ${e.message}`);
    }
}

// 4. 重新构建（先 cargo clean 避免 rustc 增量缓存导致诊断与源码不一致）
console.log('\n══════════════════════════════════════════════════');
console.log('  Step 2: cargo clean && cargo build -p legion --release');
console.log('══════════════════════════════════════════════════');
const cleanResult = run('cargo', ['clean'], { cwd: VALKYRIE_RS_DIR, timeout: 120000 });
if (cleanResult.status !== 0) {
    console.error(`\n⚠ cargo clean 失败 (exit ${cleanResult.status})，继续 build`);
}
const buildResult = run('cargo', ['build', '-p', 'legion', '--release'], {
    cwd: VALKYRIE_RS_DIR,
    timeout: 900000,
});
if (buildResult.status !== 0) {
    console.error(`\n✗ cargo build 失败 (exit ${buildResult.status})`);
    process.exit(buildResult.status ?? 1);
}
console.log(`\n✓ legion.exe 已更新: ${RELEASE_EXE}`);

// 5. 验证 seed 可用
console.log('\n══════════════════════════════════════════════════');
console.log('  Step 3: legion --version (seed 自检)');
console.log('══════════════════════════════════════════════════');
const versionResult = run(RELEASE_EXE, ['--version'], { timeout: 10000 });
if (versionResult.status !== 0) {
    console.error(`\n✗ seed 不可用 (exit ${versionResult.status})`);
    process.exit(versionResult.status ?? 1);
}

// 6. 跑自举
console.log('\n══════════════════════════════════════════════════');
console.log('  Step 4: node scripts/bootstrap-node.mjs --verbose');
console.log('══════════════════════════════════════════════════');
const bootstrapScript = path.join(SCRIPT_DIR, 'bootstrap-node.mjs');
const bootstrapResult = run('node', [bootstrapScript, '--verbose'], {
    cwd: ROOT_DIR,
    timeout: 600000,
});
process.exit(bootstrapResult.status ?? 0);
