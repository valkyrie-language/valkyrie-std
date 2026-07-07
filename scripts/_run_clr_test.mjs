import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';

const BASE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new';

const tests = [
    { name: 'vcc (empty main)', exe: `${BASE}\\vcc__main_vcc.exe`, args: [] },
    { name: 'voa (empty main)', exe: `${BASE}\\voa__main_voa.exe`, args: [] },
    { name: 'legion --version', exe: `${BASE}\\legion__main_legion.exe`, args: ['--version'] },
    { name: 'legion (no args)', exe: `${BASE}\\legion__main_legion.exe`, args: [] },
];

for (const test of tests) {
    if (!existsSync(test.exe)) {
        console.log(`[${test.name}] SKIP - exe not found`);
        continue;
    }
    console.log(`\n=== ${test.name} ===`);
    await new Promise((resolve) => {
        const child = spawn('dotnet', [test.exe, ...test.args], {
            stdio: ['pipe', 'pipe', 'pipe'],
        });
        let stdout = '';
        let stderr = '';
        child.stdout.on('data', (d) => { stdout += d.toString(); });
        child.stderr.on('data', (d) => { stderr += d.toString(); });
        const timer = setTimeout(() => {
            child.kill('SIGKILL');
            console.log(`  RESULT: HANG (killed after 3s)`);
            console.log(`  stdout: "${stdout}"`);
            console.log(`  stderr: "${stderr}"`);
            resolve();
        }, 3000);
        child.on('exit', (code, signal) => {
            clearTimeout(timer);
            console.log(`  exit code: ${code}, signal: ${signal}`);
            console.log(`  stdout: "${stdout}"`);
            console.log(`  stderr: "${stderr}"`);
            if (code === 0) {
                console.log(`  RESULT: SUCCESS`);
            } else if (signal) {
                console.log(`  RESULT: KILLED (${signal})`);
            } else {
                console.log(`  RESULT: FAILURE (exit ${code})`);
            }
            resolve();
        });
        child.on('error', (err) => {
            clearTimeout(timer);
            console.log(`  RESULT: ERROR - ${err.message}`);
            resolve();
        });
    });
}
