import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

const methods = [
    'legion__bootstrap_console_write_line',
    'legion',
];

for (const method of methods) {
    console.log(`\n=== Spy: ${method} ===`);
    try {
        const stdout = execFileSync(SPY, ['spy', 'clr', '-m', method, EXE], {
            timeout: 30000,
            encoding: 'utf8',
            maxBuffer: 20 * 1024 * 1024,
        });
        // Only print the last 60 lines (the method disassembly part)
        const lines = stdout.split('\n');
        const start = Math.max(0, lines.length - 60);
        console.log(`(total ${lines.length} lines, showing last ${lines.length - start})`);
        console.log(lines.slice(start).join('\n'));
    } catch (err) {
        console.error('spy failed:', err.message);
        if (err.stdout) {
            const lines = err.stdout.split('\n');
            const start = Math.max(0, lines.length - 80);
            console.log(`(stdout: ${lines.length} lines, showing last ${lines.length - start})`);
            console.log(lines.slice(start).join('\n'));
        }
        if (err.stderr) {
            console.error('stderr:', err.stderr.slice(0, 2000));
        }
    }
}
