#!/usr/bin/env node

/**
 * 运行四目标 runtime fixture 矩阵并输出 JSON 结果。
 *
 * 用法：
 *   node scripts/run-runtime-matrix.mjs [--output <path>]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { repoRootFrom, runCommand } from './bootstrap-lib.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const VALKYRIE_RS_DIR = path.resolve(repoRootFrom(SCRIPT_DIR), '..', 'valkyrie.rs');

function parseArgs() {
    const options = {
        output: path.join(repoRootFrom(SCRIPT_DIR), 'dist', 'monthly-matrix', 'runtime-matrix.json'),
    };
    const argv = process.argv.slice(2);
    for (let index = 0; index < argv.length; index += 1) {
        if (argv[index] === '--output' && argv[index + 1]) {
            options.output = path.resolve(argv[++index]);
        }
    }
    return options;
}

function main() {
    const options = parseArgs();
    const result = runCommand('cargo test -p legion --test cmds_run -- --nocapture', {
        cwd: VALKYRIE_RS_DIR,
        timeout: 900000,
        silent: true,
    });
    const payload = {
        generatedAt: new Date().toISOString(),
        success: result.success,
        command: 'cargo test -p legion --test cmds_run',
        stdoutTail: result.stdout.slice(-4000),
        stderrTail: result.stderr.slice(-4000),
    };
    fs.mkdirSync(path.dirname(options.output), { recursive: true });
    fs.writeFileSync(options.output, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
    console.log(`runtime 矩阵结果：${result.success ? '通过' : '失败'}`);
    console.log(`已写入：${options.output}`);
    process.exit(result.success ? 0 : 1);
}

main();
