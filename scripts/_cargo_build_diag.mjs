#!/usr/bin/env node
/**
 * 单独运行 cargo build 并捕获完整错误输出到文件。
 *
 * 用法: node scripts/_cargo_build_diag.mjs
 */
import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');

const logFile = path.join(ROOT_DIR, 'dist', 'cargo-build-log.txt');
fs.mkdirSync(path.dirname(logFile), { recursive: true });

const result = spawnSync('cargo', ['build', '-p', 'legion', '--release'], {
    cwd: VALKYRIE_RS_DIR,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
});

const stdout = result.stdout || '';
const stderr = result.stderr || '';
const combined = `=== EXIT ${result.status} ===\n=== STDOUT ===\n${stdout}\n=== STDERR ===\n${stderr}\n`;

fs.writeFileSync(logFile, combined, 'utf8');
console.log(`日志已写入: ${logFile}`);
console.log(`exit: ${result.status}`);

// 打印最后的错误行
const lines = combined.split('\n');
const errorLines = lines.filter(l => /^\s*error/i.test(l) || /could not compile/i.test(l) || /Caused by/i.test(l));
console.log('\n=== 错误行 ===');
for (const l of errorLines.slice(0, 30)) {
    console.log(l);
}
