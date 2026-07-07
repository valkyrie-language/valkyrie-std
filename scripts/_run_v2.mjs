#!/usr/bin/env node
import { execSync } from 'child_process';

const v1Exe = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1\\legion__main_legion.exe';
const project = 'E:\\Goddess of Victory\\valkyrie.v\\projects\\legion.tools';
const output = 'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v2';

const cmd = `dotnet "${v1Exe}" build "${project}" --target clr -o "${output}"`;
console.log('Running:', cmd);

try {
    const r = execSync(cmd, { encoding: 'utf8', timeout: 900000, stdio: 'pipe', cwd: 'E:\\Goddess of Victory\\valkyrie.v' });
    console.log('=== STDOUT ===');
    console.log(r);
    console.log('SUCCESS');
} catch (e) {
    console.log('ERR:', e.message);
    console.log('=== STDOUT ===');
    console.log(e.stdout || '(empty)');
    console.log('=== STDERR ===');
    console.log(e.stderr || '(empty)');
    console.log('FAILED with code', e.status);
}
