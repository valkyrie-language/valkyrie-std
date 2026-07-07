#!/usr/bin/env node
import fs from 'fs';
import { execSync } from 'child_process';

const targets = [
    'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v1',
    'E:\\Goddess of Victory\\valkyrie.v\\dist\\bootstrap-clr\\v2',
    'E:\\Goddess of Victory\\valkyrie.v\\.cache',
];

for (const t of targets) {
    if (!fs.existsSync(t)) continue;
    try {
        fs.rmSync(t, { recursive: true, force: true });
        console.log('removed:', t);
    } catch (e) {
        console.log('fs.rmSync failed, trying attrib+rmdir:', t);
        try {
            execSync(`attrib -r -s -h "${t}\\*.*" /s /d`, { stdio: 'ignore' });
        } catch {}
        try {
            fs.rmSync(t, { recursive: true, force: true });
            console.log('removed after attrib:', t);
        } catch (e2) {
            console.log('STILL FAILED:', t, e2.message);
        }
    }
}
console.log('clean done');
