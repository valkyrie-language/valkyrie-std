#!/usr/bin/env node

/**
 * 从 jar 中提取指定 class 的 javap 输出，按方法名搜索并输出匹配的方法块。
 * 支持多个方法名搜索，输出到指定文件。
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

function main() {
    const argv = process.argv.slice(2);
    if (argv.length < 3) {
        console.error('用法: node _extract_methods.mjs <jarPath> <className> <outputFile> [methodName...]');
        process.exit(2);
    }

    const [jarPath, className, outputFile, ...methodNames] = argv;
    const jarAbs = path.resolve(jarPath);
    if (!fs.existsSync(jarAbs)) {
        console.error(`jar 不存在: ${jarAbs}`);
        process.exit(1);
    }

    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-jvm-extract-'));
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
            javapOutput = execFileSync('javap', ['-c', '-p', '-v', classFilePath], {
                encoding: 'utf8',
                maxBuffer: 128 * 1024 * 1024,
            });
        } catch (err) {
            console.error(`javap 失败: ${err.message}`);
            process.exit(1);
        }

        if (methodNames.length === 0) {
            fs.writeFileSync(outputFile, javapOutput, 'utf8');
            console.log(`完整 javap 输出已写入: ${outputFile}`);
            return;
        }

        const lines = javapOutput.split(/\r?\n/);
        const results = [];
        const allMethodHeaders = [];

        // 先收集所有方法头以供诊断
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (/^\s+(public|private|protected|static|final|native|abstract|synthetic|bridge|varargs)/.test(line) && line.includes('(')) {
                allMethodHeaders.push(`${i + 1}: ${line.trim()}`);
            }
        }

        // 按方法名搜索：找到包含 methodName 的方法块
        for (const methodName of methodNames) {
            let found = false;
            let current = null;
            let braceDepth = 0;

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                if (current === null) {
                    // 寻找方法头：包含 methodName 且以 { 结尾
                    if (line.includes(methodName) && line.includes('(') && /\{\s*$/.test(line)) {
                        current = [`=== 方法: ${methodName} (行 ${i + 1}) ===`, line];
                        braceDepth = 1;
                        found = true;
                        continue;
                    }
                    // 也匹配方法头后一行跟 { 的情况
                    if (line.includes(methodName) && line.includes('(') && !line.includes('{')) {
                        if (i + 1 < lines.length && lines[i + 1].trim() === '{') {
                            current = [`=== 方法: ${methodName} (行 ${i + 1}) ===`, line, lines[i + 1]];
                            braceDepth = 1;
                            found = true;
                            i += 1;
                            continue;
                        }
                    }
                } else {
                    current.push(line);
                    const opens = (line.match(/\{/g) || []).length;
                    const closes = (line.match(/\}/g) || []).length;
                    braceDepth += opens - closes;
                    if (braceDepth <= 0) {
                        results.push(current.join('\n'));
                        current = null;
                        braceDepth = 0;
                    }
                }
            }

            if (current !== null) {
                results.push(current.join('\n'));
            }

            if (!found) {
                results.push(`=== 方法 ${methodName} 未找到 ===`);
            }
        }

        const output = results.join('\n\n') + '\n\n=== 所有方法头列表 ===\n' + allMethodHeaders.join('\n');
        fs.writeFileSync(outputFile, output, 'utf8');
        console.log(`已提取 ${methodNames.length} 个方法到: ${outputFile}`);
    } finally {
        try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) { /* 忽略 */ }
    }
}

main();
