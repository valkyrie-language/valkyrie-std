#!/usr/bin/env node

/**
 * 清除 CLR 编译缓存层（semantics/staging/tokens/artifact-set）。
 *
 * 不清除 valkyrie.rs/target 目录。
 * 清除目标：
 *   1. .cache/_tokens/                 — 语义 token 缓存
 *   2. .cache/clr_microsoft_unknown_managed/ — CLR 托管产物缓存
 *   3. dist/bootstrap-clr/v1/           — v1 产物
 *   4. dist/bootstrap-clr/v1_new/        — v1_new 产物
 *   5. dist/bootstrap-clr/bootstrap-report.json
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');

const targets = [
    path.join(ROOT_DIR, '.cache', '_tokens'),
    path.join(ROOT_DIR, '.cache', 'clr_microsoft_unknown_managed'),
    path.join(ROOT_DIR, 'dist', 'bootstrap-clr', 'v1'),
    path.join(ROOT_DIR, 'dist', 'bootstrap-clr', 'v1_new'),
    path.join(ROOT_DIR, 'dist', 'bootstrap-clr', 'bootstrap-report.json'),
];

let cleared = 0;
let skipped = 0;

for (const target of targets) {
    if (!fs.existsSync(target)) {
        console.log(`[skip] 不存在: ${path.relative(ROOT_DIR, target)}`);
        skipped++;
        continue;
    }
    const stat = fs.statSync(target);
    if (stat.isDirectory()) {
        const entries = fs.readdirSync(target);
        let removed = 0;
        let locked = 0;
        for (const entry of entries) {
            try {
                fs.rmSync(path.join(target, entry), { recursive: true, force: true });
                removed++;
            } catch {
                locked++;
            }
        }
        console.log(`[cleared] 目录 ${path.relative(ROOT_DIR, target)} (删除 ${removed}, 锁定跳过 ${locked})`);
        cleared++;
    } else {
        try {
            fs.rmSync(target, { force: true });
            console.log(`[cleared] 文件 ${path.relative(ROOT_DIR, target)}`);
            cleared++;
        } catch {
            console.log(`[locked] 文件 ${path.relative(ROOT_DIR, target)} (跳过)`);
            skipped++;
        }
    }
}

console.log(`\n完成: 清除 ${cleared} 项目标, 跳过 ${skipped} 项不存在目标。`);
