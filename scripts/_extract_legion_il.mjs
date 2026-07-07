import fs from 'fs';
import path from 'path';

const dumpPath = process.argv[2] || 'dist/bootstrap-clr/v1/_dump.il';
const methodFilter = process.argv[3] || 'legion__legion';
const outPath = process.argv[4] || 'dist/bootstrap-clr/v1/_legion_method.il';

const content = fs.readFileSync(dumpPath, 'utf8');
const lines = content.split(/\r?\n/);

// Find the method definition line (not call sites)
let methodStart = -1;
for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Look for method declaration containing the filter
    if (line.includes(methodFilter) && /\.method\s/.test(line)) {
        methodStart = i;
        break;
    }
    // Also check next-line pattern: ".method ..." on one line, signature on next
    if (line.includes(methodFilter) && i > 0 && /\.method\s/.test(lines[i - 1])) {
        methodStart = i - 1;
        break;
    }
}

if (methodStart < 0) {
    // Fallback: find by scanning for method with the name in its body
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes(methodFilter) && lines[i].includes('(')) {
            // walk backward to find .method
            for (let j = i; j >= Math.max(0, i - 5); j--) {
                if (/\.method\s/.test(lines[j])) {
                    methodStart = j;
                    break;
                }
            }
            if (methodStart >= 0) break;
        }
    }
}

if (methodStart < 0) {
    console.error(`Method "${methodFilter}" not found in ${dumpPath}`);
    process.exit(1);
}

// Find method end: next ".method" at same brace depth, or closing "} // end of method"
let methodEnd = lines.length;
for (let i = methodStart + 1; i < lines.length; i++) {
    if (/^\.method\s/.test(lines[i].trim())) {
        methodEnd = i;
        break;
    }
    if (lines[i].includes('} // end of method')) {
        methodEnd = i + 1;
        break;
    }
}

const methodText = lines.slice(methodStart, methodEnd).join('\n');
fs.writeFileSync(outPath, methodText);
console.log(`Method extracted: lines ${methodStart + 1}-${methodEnd}`);
console.log(`Written to: ${outPath}`);
console.log(`Total lines: ${methodEnd - methodStart}`);

// Print first 60 and last 40 lines as preview
const preview = lines.slice(methodStart, Math.min(methodStart + 60, methodEnd));
console.log('\n--- HEAD (first 60 lines) ---');
console.log(preview.join('\n'));

if (methodEnd - methodStart > 60) {
    const tailStart = Math.max(methodStart + 60, methodEnd - 40);
    console.log('\n--- TAIL (last 40 lines) ---');
    console.log(lines.slice(tailStart, methodEnd).join('\n'));
}
