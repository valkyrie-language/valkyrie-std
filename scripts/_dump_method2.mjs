#!/usr/bin/env node

/**
 * 从 jar 中提取指定 class 并用 javap 反编译，输出完整字节码。
 * 相比 _dump_method.mjs，本脚本不做方法级切分，直接输出整个 class 的
 * javap 结果（用分隔符标记目标方法），便于人工定位 VerifyError。
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

function main() {
    const argv = process.argv.slice(2);
    if (argv.length < 2) {
        console.error('用法: node _dump_method2.mjs <jarPath> <className> [methodName]');
        process.exit(2);
    }
    const [jarPath, className, methodName] = argv;
    const jarAbs = path.resolve(jarPath);
    if (!fs.existsSync(jarAbs)) {
        console.error(`jar 不存在: ${jarAbs}`);
        process.exit(1);
    }
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-jvm-dump2-'));
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
            if (err.stderr) console.error(err.stderr);
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
                maxBuffer: 64 * 1024 * 1024,
            });
        } catch (err) {
            console.error(`javap 失败: ${err.message}`);
            process.exit(1);
        }
        if (methodName) {
            // 按方法块切分：以 "  <modifiers>... <name>(...);" 形式为方法头，
            // 后续直到下一个同级方法头或文件末尾。javap -v 中方法块包含
            // descriptor/flags/Code/异常表等。这里采用简单策略：找到包含
            // methodName 的行，输出该行到下一个方法头之间的内容。
            const lines = javapOutput.split(/\r?\n/);
            // 方法头：以两空格开头，包含 "(" 且以 ";" 结尾
            const methodHeaderRe = /^  (?:public|private|protected|static|final|native|abstract|synthetic|bridge|varargs|\w+(?:\(\s*\w+\))?)\b.*\(.*\);.*$/;
            const headerIdxs = [];
            for (let i = 0; i < lines.length; i += 1) {
                if (methodHeaderRe.test(lines[i]) && lines[i].includes('(') && lines[i].includes(');')) {
                    headerIdxs.push(i);
                }
            }
            let targetStart = -1;
            for (let i = 0; i < headerIdxs.length; i += 1) {
                if (lines[headerIdxs[i]].includes(methodName)) {
                    targetStart = headerIdxs[i];
                    break;
                }
            }
            if (targetStart < 0) {
                console.error(`未找到方法: ${methodName}`);
                console.error('已识别的方法头:');
                for (const idx of headerIdxs) {
                    console.error(`  L${idx + 1}: ${lines[idx]}`);
                }
                process.exit(1);
            }
            const targetEnd = headerIdxs.find((idx) => idx > targetStart);
            const end = targetEnd !== undefined ? targetEnd : lines.length;
            console.log(lines.slice(targetStart, end).join('\n'));
        } else {
            console.log(javapOutput);
        }
    } finally {
        try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) { /* 忽略 */ }
    }
}

main();
