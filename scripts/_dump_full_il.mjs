import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';
const OUT = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\full_il.txt';

console.log('=== Dumping full IL of legion__legion ===');

const output = execFileSync(SPY, ['spy', 'clr', '-m', 'legion__legion', EXE], {
    timeout: 30000,
    encoding: 'utf8',
    maxBuffer: 50 * 1024 * 1024,
});

writeFileSync(OUT, output, 'utf8');
console.log(`Written ${output.length} chars to ${OUT}`);

// Parse and print just the IL disassembly section
const lines = output.split('\n');
let inIl = false;
let ilLines = [];
for (const line of lines) {
    if (line.includes('=== 方法体反汇编') || line.includes('Method body disassembly')) {
        inIl = true;
        ilLines.push(line);
        continue;
    }
    if (inIl) {
        if (line.startsWith('===') && !line.includes('方法体反汇编') && !line.includes('disassembly')) {
            break;
        }
        ilLines.push(line);
    }
}

console.log(`\nIL section: ${ilLines.length} lines`);
for (const line of ilLines) {
    console.log(line);
}
