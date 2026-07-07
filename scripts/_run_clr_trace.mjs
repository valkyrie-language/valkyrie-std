import { spawn } from 'node:child_process';
import { existsSync, writeFileSync, readFileSync } from 'node:fs';

const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

if (!existsSync(EXE)) {
    console.error('exe not found');
    process.exit(1);
}

console.log('=== Running v1 --version with COREHOST_TRACE (10s timeout) ===');

const child = spawn('dotnet', [EXE, '--version'], {
    stdio: ['pipe', 'pipe', 'pipe'],
    env: {
        ...process.env,
        COREHOST_TRACE: '1',
        COREHOST_TRACEFILE: 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\corehost_trace.log',
    },
});

let stdout = '';
let stderr = '';

child.stdout.on('data', (data) => { stdout += data.toString(); });
child.stderr.on('data', (data) => { stderr += data.toString(); });

const timer = setTimeout(() => {
    console.log('\n=== TIMEOUT (10s) - killing ===');
    child.kill('SIGKILL');
}, 10000);

child.on('exit', (code, signal) => {
    clearTimeout(timer);
    console.log(`exit code: ${code}, signal: ${signal}`);
    console.log(`stdout: "${stdout}"`);
    console.log(`stderr (first 3000 chars): "${stderr.slice(0, 3000)}"`);

    // Check if trace file was created
    const tracePath = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\corehost_trace.log';
    if (existsSync(tracePath)) {
        const trace = readFileSync(tracePath, 'utf8');
        // Show last 3000 chars of trace
        console.log(`\n=== CoreHost trace (last 3000 chars) ===`);
        console.log(trace.slice(-3000));
    }
});

child.on('error', (err) => {
    clearTimeout(timer);
    console.error('spawn error:', err.message);
});
