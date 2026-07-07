#!/usr/bin/env node

/**
 * 从 jar 中提取指定 class 并用 javap 反编译指定方法的字节码。
 *
 * 用法：
 *   node scripts/_dump_method.mjs <jarPath> <className> <methodName> [methodSignature]
 *
 * 示例：
 *   node scripts/_dump_method.mjs dist/test-jvm/legion__main_legion.jar marker/main_legion legion__legion_project_manifest_from_von
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

function main() {
    const argv = process.argv.slice(2);
    if (argv.length < 3) {
        console.error('用法: node _dump_method.mjs <jarPath> <className> <methodName> [methodSignature]');
        process.exit(1);
    }
    const [jarPath, className, methodName, methodSignature] = argv;
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'javap-'));
    try {
        const classFile = className.replace(/\./g, '/') + '.class';
        execFileSync('jar', ['xf', path.resolve(jarPath), classFile], { cwd: tmpDir, stdio: 'pipe' });
        const extractedPath = path.join(tmpDir, classFile);
        if (!fs.existsSync(extractedPath)) {
            console.error(`未找到 class 文件: ${classFile}`);
            process.exit(1);
        }
        const javapArgs = ['-c', '-p', extractedPath];
        const output = execFileSync('javap', javapArgs, { encoding: 'utf8', stdio: 'pipe' });
        const lines = output.split('\n');
        let inTargetMethod = false;
        let methodHeader = '';
        let methodBody = [];
        for (const line of lines) {
            const isMethodHeader = /^\s+(public|private|protected|static|final|synchronized|native|abstract)\s+.*\(.*\);?\s*$/.test(line) && line.trim().endsWith(';');
            if (isMethodHeader) {
                if (inTargetMethod && methodBody.length > 0) {
                    break;
                }
                if (line.includes(methodName) && (!methodSignature || line.includes(methodSignature))) {
                    inTargetMethod = true;
                    methodHeader = line;
                    methodBody = [line];
                }
                else {
                    inTargetMethod = false;
                }
            }
            else if (inTargetMethod) {
                methodBody.push(line);
            }
        }
        if (methodBody.length === 0) {
            console.error(`未找到方法: ${methodName}`);
            console.error('所有方法列表:');
            for (const line of lines) {
                if (/^\s+(public|private|protected|static|final)\s+.*\(.*\);?\s*$/.test(line) && line.trim().endsWith(';')) {
                    console.error('  ' + line.trim());
                }
            }
            process.exit(1);
        }
        console.log(methodBody.join('\n'));
    }
    finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
    }
}

main();
