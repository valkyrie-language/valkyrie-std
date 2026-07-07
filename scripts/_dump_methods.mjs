#!/usr/bin/env node

/**
 * 从 jar 中提取指定 class 并用 javap 反编译指定方法的字节码。
 * 支持多个方法名过滤。
 *
 * 用法：node _dump_methods.mjs <jarPath> <className> <methodName> [methodName2 ...]
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

const argv = process.argv.slice(2);
if (argv.length < 3) {
    console.error('用法: node _dump_methods.mjs <jarPath> <className> <methodName> [methodName2 ...]');
    process.exit(2);
}

const [jarPath, className, ...methodNames] = argv;
const jarAbs = path.resolve(jarPath);
if (!fs.existsSync(jarAbs)) {
    console.error(`jar 不存在: ${jarAbs}`);
    process.exit(1);
}

const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-jvm-dump-'));
try {
    const classFileInJar = `${className}.class`;
    try {
        execFileSync('jar', ['xf', jarAbs, classFileInJar], {
            cwd: tempDir,
            stdio: ['ignore', 'pipe', 'pipe'],
            encoding: 'utf8',
        });
    } catch (err) {
        console.error(`jar xf 失败: ${err.message}`);
        process.exit(1);
    }

    const classFilePath = path.join(tempDir, classFileInJar);
    if (!fs.existsSync(classFilePath)) {
        console.error(`提取后未找到 class 文件: ${classFileInJar}`);
        process.exit(1);
    }

    let javapOutput;
    try {
        javapOutput = execFileSync('javap', ['-c', '-p', classFilePath], {
            encoding: 'utf8',
            maxBuffer: 128 * 1024 * 1024,
        });
    } catch (err) {
        console.error(`javap 失败: ${err.message}`);
        process.exit(1);
    }

    // 按方法切分（方法头以 public/private/protected 开头，以 ; 结尾）
    const lines = javapOutput.split(/\r?\n/);
    const methodBlocks = [];
    let current = null;
    for (const line of lines) {
        const isMethodHeader = /^\s+(public|private|protected)\s+.*\(.*\);\s*$/.test(line);
        if (isMethodHeader) {
            if (current !== null) {
                methodBlocks.push(current.join('\n'));
            }
            current = [line];
            continue;
        }
        if (current !== null) {
            current.push(line);
        }
    }
    if (current !== null) {
        methodBlocks.push(current.join('\n'));
    }

    // 过滤并输出匹配的方法（只匹配方法头第一行）
    for (const methodName of methodNames) {
        const matched = methodBlocks.filter((b) => {
            const firstLine = b.split('\n')[0];
            return firstLine.includes(methodName);
        });
        if (matched.length > 0) {
            console.log(`\n${'='.repeat(80)}`);
            console.log(`方法: ${methodName}`);
            console.log(`${'='.repeat(80)}`);
            console.log(matched.join('\n\n'));
        } else {
            console.error(`\n未找到方法: ${methodName}`);
        }
    }
} finally {
    try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) { /* 忽略 */ }
}
