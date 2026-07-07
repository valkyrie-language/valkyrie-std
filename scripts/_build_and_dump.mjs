#!/usr/bin/env node

/**
 * 构建 v1 jar 并提取失败方法的字节码。
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync, execSync } from 'child_process';

const ROOT = 'e:\\Goddess of Victory\\valkyrie.v';
const LEGION = 'e:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const OUTPUT_DIR = path.join(ROOT, 'dist', 'bootstrap-jvm', 'v1');
const JAR_NAME = 'legion__main_legion.jar';
const CLASS_NAME = 'marker/main_legion';
const OUTPUT_FILE = path.join(ROOT, 'dist', 'bootstrap-jvm', '_failing_methods.txt');

const SEARCH_METHODS = [
    'project_manifest_from_von',
    'collect_publish_targets',
    'workspace_manifest_from_von',
    'parse_workspace_auto_link',
];

function main() {
    // Step 1: Build v1 jar
    console.log('Building v1 jar...');
    if (fs.existsSync(OUTPUT_DIR)) {
        fs.rmSync(OUTPUT_DIR, { recursive: true, force: true });
    }
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });

    try {
        execSync(`"${LEGION}" build "projects/legion._/projects/legion.tools" --target jvm -o "${OUTPUT_DIR}"`, {
            cwd: ROOT,
            stdio: ['ignore', 'pipe', 'pipe'],
            timeout: 300000,
            encoding: 'utf8',
        });
    } catch (err) {
        console.error('Build failed:', err.message);
        if (err.stderr) console.error(err.stderr.slice(0, 2000));
        process.exit(1);
    }

    // Find the jar
    const jarPath = path.join(OUTPUT_DIR, JAR_NAME);
    if (!fs.existsSync(jarPath)) {
        console.error(`Jar not found: ${jarPath}`);
        // List what's in the output dir
        const files = execSync(`dir /s /b "${OUTPUT_DIR}"`, { encoding: 'utf8' });
        console.error('Files:', files.slice(0, 2000));
        process.exit(1);
    }
    console.log(`Jar found: ${jarPath}`);

    // Step 2: Extract and javap
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-dump-'));
    try {
        const classFile = `${CLASS_NAME}.class`;
        execFileSync('jar', ['xf', jarPath, classFile], {
            cwd: tempDir,
            stdio: ['ignore', 'pipe', 'pipe'],
            encoding: 'utf8',
        });

        const classPath = path.join(tempDir, classFile);
        if (!fs.existsSync(classPath)) {
            console.error(`Class not found: ${classFile}`);
            process.exit(1);
        }

        const javapOutput = execFileSync('javap', ['-c', '-p', '-v', classPath], {
            encoding: 'utf8',
            maxBuffer: 128 * 1024 * 1024,
        });

        // Extract methods
        const lines = javapOutput.split(/\r?\n/);
        const results = [];
        const allMethodHeaders = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (/^\s+(public|private|protected|static|final|native|abstract|synthetic|bridge|varargs)/.test(line) && line.includes('(')) {
                allMethodHeaders.push(`${i + 1}: ${line.trim()}`);
            }
        }

        for (const methodName of SEARCH_METHODS) {
            let found = false;
            let current = null;
            let braceDepth = 0;

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                if (current === null) {
                    if (line.includes(methodName) && line.includes('(') && /\{\s*$/.test(line)) {
                        current = [`=== 方法: ${methodName} (行 ${i + 1}) ===`, line];
                        braceDepth = 1;
                        found = true;
                        continue;
                    }
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
        fs.writeFileSync(OUTPUT_FILE, output, 'utf8');
        console.log(`Output written to: ${OUTPUT_FILE}`);
        console.log(`Total methods found: ${allMethodHeaders.length}`);
    } finally {
        try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) { /* ignore */ }
    }
}

main();
