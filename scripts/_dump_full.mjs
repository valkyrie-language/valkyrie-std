#!/usr/bin/env node

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

const jarPath = path.resolve(process.argv[2]);
const className = process.argv[3];
const outputFile = process.argv[4];

const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valkyrie-dump-'));
try {
    const classFile = `${className}.class`;
    execFileSync('jar', ['xf', jarPath, classFile], { cwd: tempDir, encoding: 'utf8' });
    const classPath = path.join(tempDir, classFile);
    const javapOutput = execFileSync('javap', ['-c', '-p', '-v', classPath], {
        encoding: 'utf8',
        maxBuffer: 128 * 1024 * 1024,
    });
    fs.writeFileSync(outputFile, javapOutput, 'utf8');
    console.log(`Written ${javapOutput.length} bytes to ${outputFile}`);
} finally {
    try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch (_) {}
}
