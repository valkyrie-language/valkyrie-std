#!/usr/bin/env node
import { execSync } from 'child_process';
import fs from 'fs';

const rustLegion = 'E:\\Goddess of Victory\\valkyrie.rs\\target\\release\\legion.exe';
const project = 'E:\\Goddess of Victory\\valkyrie.v\\projects\\legion.tools';
const output = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1';

// Clean cache and old v1
try { fs.rmSync('E:\\Goddess of Victory\\valkyrie.v\\.cache', { recursive: true, force: true }); } catch {}
try { fs.rmSync(output, { recursive: true, force: true }); } catch {}

console.log('Rebuilding v1 with Rust seed (with debug output)...');
const cmd = `"${rustLegion}" build "${project}" --target clr -o "${output}"`;
try {
    execSync(cmd, { encoding: 'utf8', timeout: 300000, stdio: 'inherit', cwd: 'E:\\Goddess of Victory\\valkyrie.v' });
    console.log('v1 rebuilt successfully');
} catch (e) {
    console.log('v1 build failed:', e.message);
    process.exit(1);
}
