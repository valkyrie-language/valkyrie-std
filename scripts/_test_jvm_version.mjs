#!/usr/bin/env node

/**
 * 快速验证 JVM --version/--help 退出码。
 * 构建 jar -> 运行 --version -> 运行 --help -> 报告结果。
 */

import fs from 'fs';
import path from 'path';
import { execFileSync, spawnSync } from 'child_process';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const LEGION_EXE = path.join(VALKYRIE_RS_DIR, 'target', 'release', 'legion.exe');
const BOOTSTRAP_DIR = path.join(ROOT_DIR, 'projects', 'legion.tools');
const OUTPUT_DIR = path.join(ROOT_DIR, 'dist', 'bootstrap-jvm', 'v1');

console.log('=== JVM --version/--help 快速验证 ===\n');

// 1. 检查 legion.exe
if (!fs.existsSync(LEGION_EXE)) {
    console.error(`legion.exe 不存在: ${LEGION_EXE}`);
    process.exit(1);
}
console.log(`legion: ${LEGION_EXE}`);

// 2. 清理输出目录
if (fs.existsSync(OUTPUT_DIR)) {
    fs.rmSync(OUTPUT_DIR, { recursive: true, force: true });
}
fs.mkdirSync(OUTPUT_DIR, { recursive: true });

// 3. 用 legion 编译 bootstrap 项目 (JVM target)
console.log('\n--- 编译 bootstrap -> JVM ---');
const buildCmd = `"${LEGION_EXE}" build "${BOOTSTRAP_DIR}" --target jvm -o "${OUTPUT_DIR}"`;
console.log(`> ${buildCmd}`);
const compileResult = spawnSync(LEGION_EXE, [
    'build', BOOTSTRAP_DIR,
    '--target', 'jvm',
    '-o', OUTPUT_DIR,
], {
    encoding: 'utf8',
    timeout: 120000,
    cwd: ROOT_DIR,
});
if (compileResult.stdout) console.log(compileResult.stdout);
if (compileResult.stderr) console.error(compileResult.stderr);
if (compileResult.status !== 0) {
    console.error(`编译失败，退出码: ${compileResult.status}`);
    process.exit(1);
}
console.log('编译完成');

// 4. 查找产物目录（可能是 OUTPUT_DIR 或 OUTPUT_DIR/{targetTriple}）
let artifactDir = OUTPUT_DIR;
const targetTriple = 'jvm-openjdk-unknown-managed';
const nested = path.join(OUTPUT_DIR, targetTriple);
if (fs.existsSync(nested)) {
    artifactDir = nested;
}

// 优先找 legion.jar，否则找任何 .jar
let jarPath = path.join(artifactDir, 'legion.jar');
if (!fs.existsSync(jarPath)) {
    const jarFiles = fs.readdirSync(artifactDir).filter((f) => f.endsWith('.jar'));
    if (jarFiles.length === 0) {
        console.error(`产物目录未找到 .jar 文件: ${artifactDir}`);
        console.error('目录内容:', fs.readdirSync(artifactDir));
        process.exit(1);
    }
    jarPath = path.join(artifactDir, jarFiles[0]);
}
console.log(`\njar: ${jarPath}`);

// 5. 测试 --version
console.log('\n--- java -jar --version ---');
const versionResult = spawnSync('java', ['-jar', jarPath, '--version'], {
    encoding: 'utf8',
    timeout: 15000,
});
console.log('stdout:', versionResult.stdout || '(空)');
console.log('stderr:', versionResult.stderr || '(空)');
console.log(`退出码: ${versionResult.status}`);

// 6. 测试 --help
console.log('\n--- java -jar --help ---');
const helpResult = spawnSync('java', ['-jar', jarPath, '--help'], {
    encoding: 'utf8',
    timeout: 15000,
});
console.log('stdout:', helpResult.stdout || '(空)');
console.log('stderr:', helpResult.stderr || '(空)');
console.log(`退出码: ${helpResult.status}`);

// 7. 总结
console.log('\n=== 总结 ===');
const versionOk = versionResult.status === 0;
const helpOk = helpResult.status === 0;
console.log(`--version: ${versionOk ? 'PASS' : 'FAIL'} (退出码 ${versionResult.status})`);
console.log(`--help:     ${helpOk ? 'PASS' : 'FAIL'} (退出码 ${helpResult.status})`);
if (versionOk && helpOk) {
    console.log('\n全部通过！');
    process.exit(0);
} else {
    console.log('\n仍有失败项，需要继续排查。');
    process.exit(1);
}
