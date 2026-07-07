#!/usr/bin/env node

/**
 * 诊断 v1.exe build 命令挂起问题
 * 逐步测试不同子命令，定位挂起点
 */

import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const V1_EXE = path.join(ROOT_DIR, 'dist', 'bootstrap-clr-run2', 'v1', 'legion__main_legion.exe');
const LEGION_TOOLS_DIR = path.join(ROOT_DIR, 'projects', 'legion.tools');

function runWithTimeout(args, timeoutMs, cwd) {
    return new Promise((resolve) => {
        const stdoutChunks = [];
        const stderrChunks = [];
        const start = Date.now();
        let exited = false;
        let timedOut = false;

        const child = spawn('dotnet', [V1_EXE, ...args], {
            cwd: cwd || ROOT_DIR,
            env: { ...process.env, DOTNET_TRACE: '0' },
            stdio: ['ignore', 'pipe', 'pipe'],
        });

        child.stdout.on('data', (chunk) => stdoutChunks.push(chunk));
        child.stderr.on('data', (chunk) => stderrChunks.push(chunk));

        const timer = setTimeout(() => {
            if (!exited) {
                timedOut = true;
                try { child.kill('SIGKILL'); } catch (_) {}
            }
        }, timeoutMs);

        child.on('exit', (code, signal) => {
            exited = true;
            clearTimeout(timer);
            resolve({
                args,
                exitCode: code,
                signal,
                timedOut,
                durationMs: Date.now() - start,
                stdout: Buffer.concat(stdoutChunks).toString('utf8'),
                stderr: Buffer.concat(stderrChunks).toString('utf8'),
            });
        });

        child.on('error', (err) => {
            exited = true;
            clearTimeout(timer);
            resolve({
                args,
                error: err.message,
                timedOut: false,
                durationMs: Date.now() - start,
                stdout: Buffer.concat(stdoutChunks).toString('utf8'),
                stderr: Buffer.concat(stderrChunks).toString('utf8'),
            });
        });
    });
}

async function main() {
    const tests = [
        { label: 'no args (help)', args: [], timeout: 15000 },
        { label: 'unknown cmd', args: ['unknown_cmd_xyz'], timeout: 15000 },
        { label: 'build (no path)', args: ['build'], timeout: 15000 },
        { label: 'build nonexistent', args: ['build', path.join(ROOT_DIR, 'nonexistent_dir_xyz'), '--target', 'clr'], timeout: 15000 },
        { label: 'build legion.tools --target clr (short)', args: ['build', LEGION_TOOLS_DIR, '--target', 'clr'], timeout: 30000 },
        { label: 'build legion.tools --target clr --verbose', args: ['build', LEGION_TOOLS_DIR, '--target', 'clr', '--verbose'], timeout: 30000 },
    ];

    console.log('V1_EXE:', V1_EXE);
    console.log('exists:', fs.existsSync(V1_EXE));
    console.log('');

    for (const test of tests) {
        console.log('══════════════════════════════════════════════════════════');
        console.log(`测试: ${test.label}`);
        console.log(`参数: dotnet v1.exe ${test.args.map(a => `"${a}"`).join(' ')}`);
        console.log(`超时: ${test.timeout}ms`);
        const result = await runWithTimeout(test.args, test.timeout);
        console.log(`结果: ${result.timedOut ? '⏱ 超时' : '退出'}  exitCode=${result.exitCode}  signal=${result.signal}  duration=${result.durationMs}ms`);
        if (result.stdout) {
            console.log('--- stdout (前 2000 字符) ---');
            console.log(result.stdout.slice(0, 2000));
        } else {
            console.log('--- stdout: 空 ---');
        }
        if (result.stderr) {
            console.log('--- stderr (前 2000 字符) ---');
            console.log(result.stderr.slice(0, 2000));
        } else {
            console.log('--- stderr: 空 ---');
        }
        console.log('');
    }
}

main().catch((err) => {
    console.error('诊断脚本异常:', err);
    process.exit(1);
});
