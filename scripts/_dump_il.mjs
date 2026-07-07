import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const exe = process.argv[2];
const methodFilter = process.argv[3] || '';
const outFile = process.argv[4] || path.join(path.dirname(exe), '_dump.il');

let out;
try {
    out = execFileSync('dotnet', ['ildasm', exe], { maxBuffer: 256 * 1024 * 1024, encoding: 'utf8' });
} catch (e) {
    try {
        out = execFileSync('ilspycmd', [exe, '-il'], { maxBuffer: 256 * 1024 * 1024, encoding: 'utf8' });
    } catch (e2) {
        console.error('ildasm failed:', e.message?.slice(0, 300));
        console.error('ilspycmd failed:', e2.message?.slice(0, 300));
        process.exit(1);
    }
}

fs.writeFileSync(outFile, out);
console.log('IL written to', outFile, 'size=', out.length);

if (methodFilter) {
    const lines = out.split(/\r?\n/);
    let start = -1;
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes(methodFilter)) {
            start = i;
            break;
        }
    }
    if (start >= 0) {
        console.log(`\n--- Found "${methodFilter}" at line ${start + 1} ---`);
        for (let i = Math.max(0, start - 5); i < Math.min(lines.length, start + 120); i++) {
            console.log(lines[i]);
        }
    } else {
        console.log(`Method filter "${methodFilter}" not found`);
    }
}
