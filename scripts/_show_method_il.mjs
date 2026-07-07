import fs from 'fs';

const dumpPath = process.argv[2] || 'dist/bootstrap-clr/v1/_dump.il';
const methodFilter = process.argv[3] || 'legion__legion';

const content = fs.readFileSync(dumpPath, 'utf8');
const lines = content.split(/\r?\n/);

// Pass 1: find `.method` line, then check if methodFilter appears within next 5 lines
let methodStart = -1;
for (let i = 0; i < lines.length; i++) {
    if (/\.method\s/.test(lines[i])) {
        for (let j = i; j < Math.min(i + 6, lines.length); j++) {
            if (lines[j].includes(methodFilter)) {
                methodStart = i;
                break;
            }
        }
        if (methodStart >= 0) break;
    }
}

if (methodStart < 0) {
    console.error(`Method "${methodFilter}" not found`);
    process.exit(1);
}

let methodEnd = lines.length;
for (let i = methodStart + 1; i < lines.length; i++) {
    if (lines[i].includes('} // end of method')) {
        methodEnd = i + 1;
        break;
    }
}

const methodLines = lines.slice(methodStart, methodEnd);
process.stdout.write(methodLines.join('\n') + '\n');
process.stderr.write(`Method at lines ${methodStart + 1}-${methodEnd}, total ${methodLines.length} lines\n`);
