#!/usr/bin/env node

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync, execSync } from 'child_process';

const ROOT = 'e:\\Goddess of Victory\\valkyrie.v';
const LEGION = 'e:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const PROJECT = path.join(ROOT, 'projects', 'legion.tools');
const OUTPUT = path.join(ROOT, 'dist', 'bootstrap-jvm', 'v1');
const JAVAP_OUT = path.join(ROOT, 'dist', 'bootstrap-jvm', '_javap_v1.txt');
const CLASS_NAME = 'marker/main_legion';

function main() {
    if (fs.existsSync(OUTPUT)) {
        fs.rmSync(OUTPUT, { recursive: true, force: true });
    }

    console.log('Building v1 jar...');
    const buildResult = execSync(`"${LEGION}" build "${PROJECT}" --target jvm-openjdk-unknown-managed -o "${OUTPUT}"`, {
        cwd: ROOT,
        encoding: 'utf8',
        timeout: 300000,
        stdio: 'pipe',
    });
    console.log(buildResult);

    const jarPath = path.join(OUTPUT, 'legion__main_legion.jar');
    if (!fs.existsSync(jarPath)) {
        console.error('jar not found:', jarPath);
        const files = fs.readdirSync(OUTPUT);
        console.error('files in output:', files);
        process.exit(1);
    }

    console.log('Extracting class and running javap...');
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-dump-'));
    try {
        const classFile = `${CLASS_NAME}.class`;
        execFileSync('jar', ['xf', jarPath, classFile], {
            cwd: tempDir,
            encoding: 'utf8',
            stdio: 'pipe',
        });
        const classPath = path.join(tempDir, classFile);
        const javapOutput = execFileSync('javap', ['-c', '-p', '-v', classPath], {
            encoding: 'utf8',
            maxBuffer: 128 * 1024 * 1024,
        });
        fs.writeFileSync(JAVAP_OUT, javapOutput, 'utf8');
        console.log(`Written ${javapOutput.length} bytes to ${JAVAP_OUT}`);
    } finally {
        try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) {}
    }
}

main();
