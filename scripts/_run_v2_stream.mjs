#!/usr/bin/env node
import { spawn } from 'child_process';

const v1Exe = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1\\legion__main_legion.exe';
const project = 'E:\\Goddess of Victory\\valkyrie.v\\projects\\legion.tools';
const output = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v2';

console.log('Starting v1 build (streaming, no timeout)...');
const child = spawn('dotnet', [v1Exe, 'build', project, '--target', 'clr', '-o', output], {
    cwd: 'E:\\Goddess of Victory\\valkyrie.v',
    stdio: ['ignore', 'pipe', 'pipe']
});

let stdout = '';
let stderr = '';
child.stdout.on('data', (d) => {
    const s = d.toString();
    stdout += s;
    process.stdout.write(`[OUT] ${s}`);
});
child.stderr.on('data', (d) => {
    const s = d.toString();
    stderr += s;
    process.stderr.write(`[ERR] ${s}`);
});

const start = Date.now();
const timer = setInterval(() => {
    const elapsed = Math.floor((Date.now() - start) / 1000);
    console.log(`[elapsed ${elapsed}s] stdout=${stdout.length}B stderr=${stderr.length}B`);
}, 30000);

child.on('exit', (code, signal) => {
    clearInterval(timer);
    const elapsed = Math.floor((Date.now() - start) / 1000);
    console.log(`\n=== EXIT after ${elapsed}s: code=${code} signal=${signal} ===`);
    console.log('=== Final STDOUT ===');
    console.log(stdout);
    console.log('=== Final STDERR ===');
    console.log(stderr);
});

child.on('error', (err) => {
    clearInterval(timer);
    console.log('ERROR:', err.message);
});
