import { execFileSync } from 'node:child_process';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

const methodOutput = execFileSync(SPY, ['spy', 'clr', '-m', 'legion__legion', EXE], {
    timeout: 30000,
    encoding: 'utf8',
    maxBuffer: 50 * 1024 * 1024,
});

const methodLines = methodOutput.split('\n');

// Find the FIRST method body disassembly section
for (let j = 0; j < methodLines.length; j++) {
    if (methodLines[j].includes('=== 方法体反汇编')) {
        let end = j + 1;
        while (end < methodLines.length && !methodLines[end].includes('=== 方法体反汇编')) {
            end++;
        }
        const section = methodLines.slice(j, end);
        console.log(`(IL section: ${section.length} lines)`);
        // Print from line 190 onwards (to see offsets 900+)
        const start = Math.max(0, section.length - 100);
        console.log(`--- showing lines ${start} to ${section.length} ---`);
        console.log(section.slice(start).join('\n'));
        break;
    }
}
