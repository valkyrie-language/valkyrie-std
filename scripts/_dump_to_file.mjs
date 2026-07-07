#!/usr/bin/env node
/**
 * 从 jar 中提取指定 class，用 javap 反编译，将完整输出写入文件。
 * 用于在 Windows 下规避 PowerShell 重定向问题。
 *
 * 用法: node _dump_to_file.mjs <jarPath> <className> <outputFile>
 */
import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

const [jarPath, className, outputFile] = process.argv.slice(2);
if (!jarPath || !className || !outputFile) {
    console.error('用法: node _dump_to_file.mjs <jarPath> <className> <outputFile>');
    process.exit(2);
}
const jarAbs = path.resolve(jarPath);
if (!fs.existsSync(jarAbs)) {
    console.error(`jar 不存在: ${jarAbs}`);
    process.exit(1);
}
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'vk-dump-file-'));
try {
    const classFile = `${className}.class`;
    execFileSync('jar', ['xf', jarAbs, classFile], {
        cwd: tempDir,
        stdio: ['ignore', 'pipe', 'pipe'],
        encoding: 'utf8',
    });
    const classFilePath = path.join(tempDir, classFile);
    if (!fs.existsSync(classFilePath)) {
        console.error(`提取后未找到 class 文件: ${classFile}`);
        const list = execFileSync('jar', ['tf', jarAbs], { encoding: 'utf8' });
        const matches = list.split(/\r?\n/).filter((l) => l.includes(className.split('/').pop()));
        console.error('jar 中相关条目:');
        for (const m of matches) console.error('  ' + m);
        process.exit(1);
    }
    const out = execFileSync('javap', ['-c', '-p', '-v', classFilePath], {
        encoding: 'utf8',
        maxBuffer: 256 * 1024 * 1024,
    });
    const outAbs = path.resolve(outputFile);
    fs.writeFileSync(outAbs, out, 'utf8');
    console.log(`已写入 ${out.length} 字节到 ${outAbs}`);
} finally {
    try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) {}
}
