import { execFileSync } from 'node:child_process';

const SPY = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const EXE = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1_new\\legion__main_legion.exe';

// First, list all methods to find row 1 (the entry point)
console.log('=== Finding entry point (MethodDef row 1) ===');
const listOutput = execFileSync(SPY, ['spy', 'clr', '-l', EXE], {
    timeout: 30000,
    encoding: 'utf8',
    maxBuffer: 20 * 1024 * 1024,
});

// Find the MethodDef table section and look for row 1
const lines = listOutput.split('\n');
let inMethodDef = false;
let foundEntry = false;
const entryMethods = [];

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('--- MethodDef table ---') || line.includes('MethodDef table')) {
        inMethodDef = true;
    }
    if (inMethodDef) {
        // Look for row 1
        if (line.match(/\[\s*1\]/) && line.includes('RVA=')) {
            console.log('Found MethodDef row 1:');
            console.log(line);
            // Extract the method name
            const nameMatch = line.match(/Name="([^"]+)"/);
            if (nameMatch) {
                const methodName = nameMatch[1];
                console.log(`\nEntry point method name: "${methodName}"`);

                // Now disassemble this specific method
                console.log(`\n=== Disassembling entry point: ${methodName} ===`);
                try {
                    const methodOutput = execFileSync(SPY, ['spy', 'clr', '-m', methodName, EXE], {
                        timeout: 30000,
                        encoding: 'utf8',
                        maxBuffer: 50 * 1024 * 1024,
                    });
                    // Find the method body disassembly section
                    const methodLines = methodOutput.split('\n');
                    // Find all "=== 方法体反汇编" sections
                    for (let j = 0; j < methodLines.length; j++) {
                        if (methodLines[j].includes('=== 方法体反汇编')) {
                            // Print this section and the next 80 lines
                            const sectionEnd = Math.min(j + 100, methodLines.length);
                            console.log(methodLines.slice(j, sectionEnd).join('\n'));
                            console.log('---');
                        }
                    }
                } catch (err) {
                    console.error('spy method dump failed:', err.message);
                }
            }
            foundEntry = true;
            break;
        }
    }
}

if (!foundEntry) {
    console.log('Could not find MethodDef row 1. Searching for first 5 MethodDef entries...');
    inMethodDef = false;
    let count = 0;
    for (const line of lines) {
        if (line.includes('MethodDef table') || line.includes('--- MethodDef')) {
            inMethodDef = true;
        }
        if (inMethodDef && line.includes('RVA=') && line.match(/\[\d+\]/)) {
            console.log(line.trim());
            count++;
            if (count >= 5) break;
        }
    }
}
