import { execFileSync } from 'node:child_process';
import { existsSync, rmSync, mkdirSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, basename, extname } from 'node:path';

const ROOT = 'E:\\Goddess of Victory\\valkyrie.v';
const LEGION_EXE = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const OUTPUT_DIR = join(ROOT, 'dist', 'bootstrap-clr', 'v1_new');
const PROJECT_DIR = join(ROOT, 'projects', 'legion.tools');

if (existsSync(OUTPUT_DIR)) {
    rmSync(OUTPUT_DIR, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
}
mkdirSync(OUTPUT_DIR, { recursive: true });

console.log('=== Compiling v1 (CLR) ===');
console.log(`seed: ${LEGION_EXE}`);
console.log(`project: ${PROJECT_DIR}`);
console.log(`output: ${OUTPUT_DIR}`);

try {
    const stdout = execFileSync(LEGION_EXE, [
        'build', PROJECT_DIR, '--target', 'clr', '-o', OUTPUT_DIR
    ], {
        cwd: ROOT,
        timeout: 300000,
        encoding: 'utf8',
        maxBuffer: 10 * 1024 * 1024,
    });
    console.log(stdout);
    console.log('=== BUILD SUCCESS ===');
} catch (err) {
    console.error('=== BUILD FAILED ===');
    console.error('stdout:', err.stdout || '');
    console.error('stderr:', err.stderr || err.message);
    process.exit(1);
}

console.log('\n=== Output directory listing ===');
function listDir(dir, prefix = '') {
    for (const entry of readdirSync(dir)) {
        const fullPath = join(dir, entry);
        const st = statSync(fullPath);
        if (st.isDirectory()) {
            console.log(`${prefix}[DIR] ${entry}/`);
            listDir(fullPath, prefix + '  ');
        } else {
            const sizeKB = (st.size / 1024).toFixed(1);
            console.log(`${prefix}${entry} (${sizeKB} KB)`);
        }
    }
}
listDir(OUTPUT_DIR);

console.log('\n=== .msil files ===');
function findMsilFiles(dir) {
    const results = [];
    for (const entry of readdirSync(dir)) {
        const fullPath = join(dir, entry);
        const st = statSync(fullPath);
        if (st.isDirectory()) {
            results.push(...findMsilFiles(fullPath));
        } else if (extname(entry) === '.msil') {
            results.push(fullPath);
        }
    }
    return results;
}

const msilFiles = findMsilFiles(OUTPUT_DIR);
if (msilFiles.length === 0) {
    console.log('No .msil files found!');
} else {
    for (const file of msilFiles) {
        console.log(`\n--- ${basename(file)} ---`);
    }
}

console.log(`\nFound ${msilFiles.length} .msil files`);
