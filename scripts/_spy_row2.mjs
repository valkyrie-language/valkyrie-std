import { execFileSync } from 'node:child_process';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

// List all methods and find rows 1-5
console.log('=== Finding MethodDef rows 1-5 ===');
const listOutput = execFileSync(SPY, ['spy', 'clr', '-l', EXE], {
    timeout: 30000,
    encoding: 'utf8',
    maxBuffer: 30 * 1024 * 1024,
});

const lines = listOutput.split('\n');
let inMethodDef = false;
const earlyMethods = [];

for (const line of lines) {
    if (line.includes('--- MethodDef table ---')) {
        inMethodDef = true;
        continue;
    }
    if (inMethodDef) {
        // Match method rows like [1], [2], [3] etc.
        const match = line.match(/\[\s*(\d+)\]\s+RVA=(\S+)\s+.*Name="([^"]+)"/);
        if (match) {
            const rowNum = parseInt(match[1]);
            if (rowNum <= 10) {
                earlyMethods.push({ row: rowNum, name: match[3], line: line.trim() });
            }
        }
        // Also check for the next table header
        if (line.includes('--- Param table ---') || line.includes('--- MemberRef')) {
            break;
        }
    }
}

console.log('Early methods:');
for (const m of earlyMethods) {
    console.log(`  Row ${m.row}: ${m.name}`);
}

// Find row 2's name
const row2 = earlyMethods.find(m => m.row === 2);
if (row2) {
    console.log(`\n=== Row 2 is: ${row2.name} ===`);

    // Disassemble row 2
    console.log(`\n=== Disassembling: ${row2.name} ===`);
    try {
        const methodOutput = execFileSync(SPY, ['spy', 'clr', '-m', row2.name, EXE], {
            timeout: 30000,
            encoding: 'utf8',
            maxBuffer: 50 * 1024 * 1024,
        });
        const methodLines = methodOutput.split('\n');
        for (let j = 0; j < methodLines.length; j++) {
            if (methodLines[j].includes('=== 方法体反汇编')) {
                // Print until the next section or end
                let end = j + 1;
                while (end < methodLines.length && !methodLines[end].includes('=== 方法体反汇编') && !methodLines[end].includes('=== ')) {
                    end++;
                }
                // For large methods, print first 120 lines of IL
                const ilSection = methodLines.slice(j, end);
                if (ilSection.length > 130) {
                    console.log(`(IL has ${ilSection.length} lines, showing first 120)`);
                    console.log(ilSection.slice(0, 120).join('\n'));
                    console.log('...');
                    console.log(`(last 10 lines:)`);
                    console.log(ilSection.slice(-10).join('\n'));
                } else {
                    console.log(ilSection.join('\n'));
                }
                console.log('---');
            }
        }
    } catch (err) {
        console.error('spy method dump failed:', err.message);
    }
}
