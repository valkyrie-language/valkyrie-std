import { execFileSync } from 'node:child_process';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

// Get full method list
const listOutput = execFileSync(SPY, ['spy', 'clr', '-l', EXE], {
    timeout: 30000,
    encoding: 'utf8',
    maxBuffer: 30 * 1024 * 1024,
});

const lines = listOutput.split('\n');
let inMethodDef = false;
const targetRows = [1, 2, 3, 4, 5];

for (const line of lines) {
    if (line.includes('--- MethodDef table ---')) {
        inMethodDef = true;
        continue;
    }
    if (inMethodDef) {
        if (line.includes('--- Param table ---') || line.includes('--- MemberRef')) {
            break;
        }
        const match = line.match(/\[\s*(\d+)\]/);
        if (match) {
            const row = parseInt(match[1]);
            if (targetRows.includes(row)) {
                console.log(line.trim());
            }
        }
    }
}

// Now I need to find row 2's name and disassemble it
// From the listing, I'll extract row 2's name
console.log('\n--- Extracting row 2 name ---');
inMethodDef = false;
let row2Name = null;

for (const line of lines) {
    if (line.includes('--- MethodDef table ---')) {
        inMethodDef = true;
        continue;
    }
    if (inMethodDef) {
        if (line.includes('--- Param table ---') || line.includes('--- MemberRef')) {
            break;
        }
        if (line.match(/\[\s*2\]/) && line.includes('Name=')) {
            const nameMatch = line.match(/Name="([^"]+)"/);
            if (nameMatch) {
                row2Name = nameMatch[1];
                console.log(`Row 2 name: ${row2Name}`);
            }
            break;
        }
    }
}

if (row2Name) {
    console.log(`\n=== Disassembling row 2: ${row2Name} ===`);
    const methodOutput = execFileSync(SPY, ['spy', 'clr', '-m', row2Name, EXE], {
        timeout: 30000,
        encoding: 'utf8',
        maxBuffer: 50 * 1024 * 1024,
    });

    const methodLines = methodOutput.split('\n');
    // Find the FIRST method body disassembly section
    for (let j = 0; j < methodLines.length; j++) {
        if (methodLines[j].includes('=== 方法体反汇编')) {
            // Print until the next section or 200 lines
            let end = j + 1;
            while (end < methodLines.length && !methodLines[end].includes('=== 方法体反汇编')) {
                end++;
            }
            const section = methodLines.slice(j, Math.min(end, j + 200));
            console.log(`(IL section: ${end - j} lines)`);
            console.log(section.join('\n'));
            break; // Only first match
        }
    }
}
