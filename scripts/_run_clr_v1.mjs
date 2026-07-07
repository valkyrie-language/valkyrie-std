import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

if (!existsSync(EXE)) {
    console.error('exe not found:', EXE);
    process.exit(1);
}

console.log('=== Running v1 --version (5s timeout) ===');
console.log(`exe: ${EXE}`);

const child = spawn('dotnet', [EXE, '--version'], {
    stdio: ['pipe', 'pipe', 'pipe'],
    timeout: 5000,
});

let stdout = '';
let stderr = '';

child.stdout.on('data', (data) => { stdout += data.toString(); });
child.stderr.on('data', (data) => { stderr += data.toString(); });

const timer = setTimeout(() => {
    console.log('\n=== TIMEOUT (5s) - killing process ===');
    child.kill('SIGKILL');
}, 5000);

child.on('exit', (code, signal) => {
    clearTimeout(timer);
    console.log(`\nexit code: ${code}`);
    console.log(`signal: ${signal}`);
    console.log(`stdout: "${stdout}"`);
    console.log(`stderr: "${stderr}"`);
    if (signal === 'SIGKILL' || signal === 'SIGTERM') {
        console.log('RESULT: HANG (process was killed after timeout)');
    } else if (code === 0) {
        console.log('RESULT: SUCCESS');
    } else {
        console.log('RESULT: FAILURE (non-zero exit)');
    }
});

child.on('error', (err) => {
    clearTimeout(timer);
    console.error('spawn error:', err.message);
});
