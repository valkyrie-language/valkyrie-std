import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const target = process.argv[2];
if (!target) {
    console.error('Usage: node _cleanup.mjs <path>');
    process.exit(1);
}

const resolved = path.resolve(target);
console.log(`Cleaning: ${resolved}`);

if (!fs.existsSync(resolved)) {
    console.log('Path does not exist, nothing to clean.');
    process.exit(0);
}

// Try fs.rmSync first with retries
for (let attempt = 1; attempt <= 3; attempt++) {
    try {
        fs.rmSync(resolved, { recursive: true, force: true });
        console.log(`Cleaned via fs.rmSync on attempt ${attempt}.`);
        process.exit(0);
    } catch (err) {
        console.log(`Attempt ${attempt} failed: ${err.code}`);
        if (attempt < 3) {
            // Wait a bit before retry
            const start = Date.now();
            while (Date.now() - start < 1000) { /* busy wait */ }
        }
    }
}

// Fallback: use cmd rmdir
try {
    execSync(`cmd /c rmdir /s /q "${resolved}"`, { stdio: 'inherit' });
    console.log('Cleaned via cmd rmdir.');
    process.exit(0);
} catch (err) {
    console.error('All cleanup methods failed.');
    process.exit(1);
}
