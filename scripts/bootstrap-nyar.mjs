#!/usr/bin/env node

/**
 * Nyar VM 自举验证脚本
 *
 * 执行 Nyar VM 路线的当前可测验证：
 *   1. 上一代编译器可用
 *   2. 源码 -> v1.nyar
 *   3. v1.nyar 本身可运行最小命令（通过 vcc 运行 .nyar 字节码）
 *   4. 在 v1 运行验收通过后，再由同一 seed 对同一源码做第二次编译，得到 v2.nyar
 *   5. 比较 v1 与第二次编译产物的 .nyar 是否一致
 *
 * 流程：
 *   1. 用上一代编译器（NyarVM.cs legion）编译 valkyrie.v/projects/legion.tools --target nyar → v1
 *   2. 验证 v1 产物的运行（vcc run --nyar <file> --function legion.version_text）
 *   3. 若 v1 运行通过，再由同一 seed 再次编译同一份源码 → v2
 *   4. 比对 v1 与第二次编译产物
 *
 * 用法：
 *   node scripts/bootstrap-nyar.mjs [--legion <path>] [--vcc <path>] [--output <dir>] [--verbose]
 *
 * 当前状态：
 *   - 本脚本用于"诚实失败"的真实验收，不再把半完成状态记为成功
 *   - 第二轮仅测量同一 seed 的重复编译确定性，不把它表述为"v1 已独立驱动编译"
 *   - 只要 v1 编译失败、v1 运行失败、第二次编译失败或比对失败，脚本都会返回非零退出码
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]):\//, '$1:/'));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');
const VCC_CSPROJ = path.join(NYARVM_DIR, 'tools', 'vcc', 'Valkyrie.CLI.csproj');
const SECOND_COMPILE_NOTE = '第二轮产物来自同一 seed 对同一源码的再次编译，只用于测量当前确定性，不代表 v1 已独立驱动编译。';

// ─────────────────────────────────────────────────────────────
// 配置
// ─────────────────────────────────────────────────────────────

const BOOTSTRAP_PROJECT = 'projects/legion.tools';
const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = 'nyar-unknown-unknown-managed';
const EXPECTED_ARTIFACT_BASENAME = 'legion_tools';

// ─────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: 'pipe',
        });
        if (!options.silent && result) {
            process.stdout.write(result);
        }
        return { success: true, stdout: result || '' };
    } catch (error) {
        if (!options.silent) {
            if (error.stdout) {
                process.stdout.write(error.stdout);
            }
            if (error.stderr) {
                process.stderr.write(error.stderr);
            }
        }
        return {
            success: false,
            stdout: error.stdout || '',
            stderr: error.stderr || error.message || '',
        };
    }
}

function legionLauncherCandidates(baseDir) {
    return [
        path.join(baseDir, 'legion.exe'),
        path.join(baseDir, 'legion'),
        path.join(baseDir, 'legion.dll'),
    ];
}

function resolveLegionLauncher(baseDir) {
    for (const candidate of legionLauncherCandidates(baseDir)) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }

    return null;
}

// 扫描指定 dist 目录下所有 `legion*` 子目录，收集存在的 legion 启动器。
// 用于在存在多个历史 seed 构建时按修改时间挑选最新的一份。
function collectLegionLaunchersFromDist(distDir) {
    const results = [];
    if (!fs.existsSync(distDir)) {
        return results;
    }
    for (const entry of fs.readdirSync(distDir, { withFileTypes: true })) {
        if (!entry.isDirectory()) {
            continue;
        }
        if (!/^legion/i.test(entry.name)) {
            continue;
        }
        for (const candidate of legionLauncherCandidates(path.join(distDir, entry.name))) {
            if (fs.existsSync(candidate)) {
                results.push(candidate);
            }
        }
    }
    return results;
}

function findLegion() {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    // 优先在 dist/ 下挑选发布产物：工作区 dist/ 与上级 dist/ 下的 legion* 目录。
    // 按修改时间降序，优先使用最新的 seed 构建，
    // 避免误用被覆盖前的旧 `dist/legion/` 导致语法不支持。
    const distCandidates = [
        ...collectLegionLaunchersFromDist(path.join(ROOT_DIR, 'dist')),
        ...collectLegionLaunchersFromDist(path.resolve(ROOT_DIR, '..', 'dist')),
    ];
    if (distCandidates.length > 0) {
        distCandidates.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
        return distCandidates[0];
    }

    // 仅当 dist/ 下没有任何发布产物时，才回退到 NyarVM.cs 的 build 输出。
    // 注意：bin/Debug 属于开发构建，不保证与发布 seed 行为一致，仅作兜底。
    const buildCandidates = [
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Release', 'net10.0')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Debug', 'net10.0')),
    ].filter(c => fs.existsSync(c));

    return buildCandidates.length > 0 ? buildCandidates[0] : null;
}

function vccLauncherCandidates(baseDir) {
    return [
        path.join(baseDir, 'vcc.exe'),
        path.join(baseDir, 'vcc'),
        path.join(baseDir, 'vcc.dll'),
    ];
}

function findVcc() {
    const envPath = process.env.VCC_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidates = [
        ...vccLauncherCandidates(path.join(ROOT_DIR, 'dist', 'vcc')),
        ...vccLauncherCandidates(path.resolve(ROOT_DIR, '..', 'dist', 'vcc')),
        ...vccLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'vcc', 'bin', 'Release', 'net10.0')),
        ...vccLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'vcc', 'bin', 'Debug', 'net10.0')),
    ];
    for (const c of candidates) {
        if (fs.existsSync(c)) {
            return c;
        }
    }
    return null;
}

function ensureVcc(outputRoot, verbose) {
    const existing = findVcc();
    if (existing) {
        return existing;
    }

    if (!fs.existsSync(NYARVM_DIR) || !fs.existsSync(VCC_CSPROJ)) {
        return null;
    }

    const toolOutputDir = path.join(outputRoot, '_vcc');
    if (fs.existsSync(toolOutputDir)) {
        fs.rmSync(toolOutputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(toolOutputDir, { recursive: true });

    console.log('未找到现成的 vcc，正在从 NyarVM.cs 构建...');
    const publishResult = runCommand(
        `dotnet publish "${VCC_CSPROJ}" -c Release --nologo -o "${toolOutputDir}" -p:UseAppHost=true -p:PublishAot=false`,
        { cwd: NYARVM_DIR, silent: !verbose, timeout: 300000 }
    );

    if (!publishResult.success) {
        console.error('错误：自动构建 vcc 失败');
        if (publishResult.stderr) {
            console.error(publishResult.stderr.slice(0, 4000));
        }
        return null;
    }

    for (const candidate of vccLauncherCandidates(toolOutputDir)) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return null;
}

function ensurePreviousLegion(outputRoot, verbose) {
    const existing = findLegion();
    if (existing) {
        return existing;
    }

    if (!fs.existsSync(NYARVM_DIR) || !fs.existsSync(LEGION_CSPROJ)) {
        return null;
    }

    const toolOutputDir = path.join(outputRoot, '_previous_legion');
    if (fs.existsSync(toolOutputDir)) {
        fs.rmSync(toolOutputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(toolOutputDir, { recursive: true });

    console.log('未找到现成的上一代 legion，正在从 NyarVM.cs 构建...');
    const publishResult = runCommand(
        `dotnet publish "${LEGION_CSPROJ}" -c Release --nologo -o "${toolOutputDir}" -p:UseAppHost=true`,
        { cwd: NYARVM_DIR, silent: !verbose, timeout: 300000 }
    );

    if (!publishResult.success) {
        console.error('错误：自动构建上一代 legion 失败');
        if (publishResult.stderr) {
            console.error(publishResult.stderr.slice(0, 4000));
        }
        return null;
    }

    return resolveLegionLauncher(toolOutputDir);
}

function collectFiles(dir, extensions) {
    const results = [];
    if (!fs.existsSync(dir)) {
        return results;
    }
    const extSet = new Set(extensions.map(e => e.toLowerCase()));
    for (const entry of fs.readdirSync(dir, { withFileTypes: true, recursive: true })) {
        if (!entry.isFile()) {
            continue;
        }
        const ext = path.extname(entry.name).toLowerCase();
        if (extSet.has(ext)) {
            results.push(path.join(entry.parentPath || entry.path, entry.name));
        }
    }
    return results.sort();
}

function computeFileHash(filePath) {
    const content = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(content).digest('hex');
}

function computeDirHash(dir, extensions) {
    const files = collectFiles(dir, extensions);
    if (files.length === 0) {
        return null;
    }
    const hash = crypto.createHash('sha256');
    for (const file of files) {
        hash.update(path.relative(dir, file));
        hash.update('\0');
        hash.update(computeFileHash(file));
        hash.update('\0');
    }
    return hash.digest('hex');
}

function shortenText(value, maxChars = 240) {
    const text = String(value || '').trim();
    if (text.length <= maxChars) {
        return text;
    }
    return `${text.slice(0, maxChars)}...`;
}

function summarizeFailureOutput(result, fallback) {
    const stdoutLines = String(result?.stdout || '').split(/\r?\n/).map(line => line.trim()).filter(Boolean);
    const stderrLines = String(result?.stderr || '').split(/\r?\n/).map(line => line.trim()).filter(Boolean);
    const allLines = [...stdoutLines, ...stderrLines];
    const combinedText = allLines.join('\n');
    const fileMatches = [...combinedText.matchAll(/[A-Za-z]:\\[^\r\n"]+?\.v/g)].map(match => match[0]);
    const uniqueFiles = [...new Set(fileMatches)];
    const hints = [];

    if (/u32/.test(combinedText) && /char/.test(combinedText)) {
        hints.push('观测到 `u32 -> char` 转换相关错误');
    }
    if (/\("\.\."\)/.test(combinedText) || /Token/.test(combinedText)) {
        hints.push('观测到 `..` 相关解析错误');
    }
    if (uniqueFiles.length > 0) {
        hints.push(`涉及文件：${uniqueFiles.slice(0, 4).join(', ')}`);
    }
    if (hints.length > 0) {
        return shortenText(hints.join(' | '), 800);
    }

    const importantLines = allLines.filter(line => /解析错误|语义错误|构建失败|error[:：]|错误[:：]/i.test(line));
    const selected = (importantLines.length > 0 ? importantLines : allLines).slice(-6);
    return shortenText(selected.join(' | ') || fallback, 800);
}

function createGate(name, status, detail) {
    return { name, status, detail };
}

function printSection(title) {
    console.log('\n==================================================');
    console.log(`  ${title}`);
    console.log('==================================================\n');
}

function printGateSummary(gates) {
    printSection('门级状态');

    for (const gate of gates) {
        console.log(`- ${gate.name}：${gate.status}`);
        if (gate.detail) {
            console.log(`  ${gate.detail}`);
        }
    }
}

function writeReport(outputRoot, payload) {
    fs.mkdirSync(outputRoot, { recursive: true });
    const reportPath = path.join(outputRoot, 'bootstrap-report.json');
    fs.writeFileSync(reportPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
    return reportPath;
}

// ─────────────────────────────────────────────────────────────
// Level 1：源码 → v1.nyar
// ─────────────────────────────────────────────────────────────

function compileV1(legionPath, vccPath, outputDir, verbose) {
    printSection('Level 1：源码 -> v1.nyar');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`nyar 运行时：${vccPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);
    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    const nyarFile = path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.nyar`);

    // 验证上一代编译器可用
    const versionCheck = runCommand(`"${legionPath}" --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        console.error('错误：上一代编译器不可用');
        console.error(versionCheck.stderr);
        return {
            success: false,
            stage: 'previous_compiler_check',
            error: summarizeFailureOutput(versionCheck, '上一代编译器不可用'),
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
            },
        };
    }
    console.log(`上一代编译器版本：${versionCheck.stdout.trim()}`);

    // 清理旧产物
    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    // 执行编译
    console.log('\n编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target nyar -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000, silent: !verbose }
    );

    if (!buildResult.success) {
        console.error('错误：v1 编译失败');
        if (buildResult.stderr) {
            console.error(buildResult.stderr.slice(0, 2000));
        }
        const errorSummary = summarizeFailureOutput(buildResult, 'v1 编译失败');
        return {
            success: false,
            stage: 'source_to_v1',
            error: errorSummary,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 检查产物
    if (!fs.existsSync(nyarFile)) {
        console.error(`错误：v1 产物不存在：${nyarFile}`);
        return {
            success: false,
            stage: 'v1_artifact',
            error: `v1 产物不存在：${nyarFile}`,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
            runtime: {
                run: { success: false, stdout: '', stderr: '' },
            },
        };
    }

    // 验证 v1 产物可运行（通过 vcc 运行 .nyar 字节码，调用 legion.version_text 做 smoke test）
    console.log('\n验证 v1 产物（vcc run，smoke test：legion.version_text）...');
    const v1RunCheck = runCommand(
        `"${vccPath}" run "${nyarFile}" --function legion.version_text`,
        { silent: true, timeout: 60000 }
    );
    if (v1RunCheck.success) {
        console.log('  vcc run：退出码 0');
        if (v1RunCheck.stdout) {
            const lines = v1RunCheck.stdout.trim().split('\n').slice(-5);
            for (const line of lines) {
                console.log(`  ${line}`);
            }
        }
    } else {
        console.error(`  警告：vcc run 失败：${v1RunCheck.stderr?.slice(0, 300)}`);
    }

    // 收集 v1 产物清单
    const v1Artifacts = collectFiles(targetDir, ['.nyar', '.txt', '.json']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'source_to_v1',
        outputDir: targetDir,
        nyarFile,
        artifacts: v1Artifacts,
        hash: computeFileHash(nyarFile),
        runtime: {
            run: v1RunCheck,
        },
    };
}

// ─────────────────────────────────────────────────────────────
// Level 2：第二次 seed 编译 → v2.nyar
// ─────────────────────────────────────────────────────────────

function compileV2(legionPath, outputDir, verbose) {
    printSection('Level 2：第二次 seed 编译 -> v2.nyar');

    console.log('方式：使用同一 seed 对同一源码再次编译');
    console.log(`说明：${SECOND_COMPILE_NOTE}\n`);

    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    const nyarFile = path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.nyar`);

    // 清理旧产物
    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    // 用 seed 编译器编译同一份源码 → v2
    console.log('编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target nyar -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000, silent: !verbose }
    );

    if (!buildResult.success) {
        console.error('错误：v2 编译失败');
        if (buildResult.stderr) {
            console.error(buildResult.stderr.slice(0, 2000));
        }
        const errorSummary = summarizeFailureOutput(buildResult, '第二次 seed 编译失败');
        return {
            success: false,
            stage: 'second_seed_compile_to_v2',
            error: errorSummary,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
        };
    }

    // 检查产物
    if (!fs.existsSync(nyarFile)) {
        console.error(`错误：v2 产物不存在：${nyarFile}`);
        return {
            success: false,
            stage: 'v2_artifact',
            error: `v2 产物不存在：${nyarFile}`,
            outputDir: targetDir,
            nyarFile,
            artifacts: [],
            hash: null,
        };
    }

    // 收集 v2 产物清单
    const v2Artifacts = collectFiles(targetDir, ['.nyar', '.txt', '.json']);
    console.log(`\nv2 产物清单（${v2Artifacts.length} 个文件）：`);
    for (const artifact of v2Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    return {
        success: true,
        stage: 'second_seed_compile_to_v2',
        outputDir: targetDir,
        nyarFile,
        artifacts: v2Artifacts,
        hash: computeFileHash(nyarFile),
    };
}

// ─────────────────────────────────────────────────────────────
// 比对
// ─────────────────────────────────────────────────────────────

// v1 / v2 比对规则（固化结论）
//
// 必须比对（不一致则阻断）：
//   - .nyar 文件：核心字节码产物，是自举一致性的唯一判定依据
//
// 允许差异（不阻断）：
//   - .txt / .json：运行契约和元数据文件可能含非确定性时间戳
//
// 阻断条件：
//   - .nyar 文件哈希不一致 → 阻断
//   - 产物清单结构不一致（多了或少了 .nyar 文件）→ 阻断

function compareArtifacts(v1Result, v2Result, skipReason = null) {
    printSection('v1 / 第二次编译产物比对');

    if (!v1Result || !v2Result) {
        console.log(`比对跳过：${skipReason || 'v1 或 v2 产物缺失'}`);
        return { match: false, skipped: true, reason: skipReason || 'v1 或 v2 产物缺失' };
    }

    const mustCompareExtensions = ['.nyar'];
    const allowedDiffExtensions = ['.txt', '.json'];

    console.log('比对规则：');
    console.log('  必须一致：.nyar 文件');
    console.log('  允许差异：.txt、.json（含非确定性元数据）');
    console.log('');

    const v1NyarFiles = collectFiles(v1Result.outputDir, mustCompareExtensions);
    const v2NyarFiles = collectFiles(v2Result.outputDir, mustCompareExtensions);

    const v1NyarNames = new Set(v1NyarFiles.map(f => path.basename(f)));
    const v2NyarNames = new Set(v2NyarFiles.map(f => path.basename(f)));

    let allMatch = true;
    const details = [];

    const onlyInV1 = [...v1NyarNames].filter(n => !v2NyarNames.has(n));
    const onlyInV2 = [...v2NyarNames].filter(n => !v1NyarNames.has(n));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的 .nyar 文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的 .nyar 文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    const common = [...v1NyarNames].filter(n => v2NyarNames.has(n));
    for (const name of common) {
        const v1File = v1NyarFiles.find(f => path.basename(f) === name);
        const v2File = v2NyarFiles.find(f => path.basename(f) === name);
        if (v1File && v2File) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${name}：哈希不一致`);
                console.log(`    v1: ${h1}`);
                console.log(`    v2: ${h2}`);
                details.push({ type: 'nyar_hash_mismatch', file: name, v1Hash: h1, v2Hash: h2 });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：一致`);
            }
        }
    }

    const allowedFiles = collectFiles(v1Result.outputDir, allowedDiffExtensions);
    if (allowedFiles.length > 0) {
        console.log(`\n允许差异的文件（${allowedFiles.length} 个，不参与比对）：`);
        for (const f of allowedFiles) {
            console.log(`  ${path.relative(v1Result.outputDir, f)}`);
        }
    }

    return { match: allMatch, skipped: false, details, reason: null };
}

// ─────────────────────────────────────────────────────────────
// 主入口
// ─────────────────────────────────────────────────────────────

function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        legion: null,
        vcc: null,
        output: null,
        verbose: false,
    };

    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--legion':
                options.legion = args[++i];
                break;
            case '--vcc':
                options.vcc = args[++i];
                break;
            case '--output':
            case '-o':
                options.output = args[++i];
                break;
            case '--verbose':
            case '-v':
                options.verbose = true;
                break;
            case '--help':
            case '-h':
                console.log(`
Nyar VM 自举验证脚本

用法：node scripts/bootstrap-nyar.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --vcc <path>        nyar 运行时路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-nyar）
  --verbose, -v       详细输出
  --help, -h          显示帮助信息
`);
                process.exit(0);
        }
    }

    return options;
}

function main() {
    const options = parseArgs();
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-nyar'));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('==========================================================');
    console.log(' Nyar VM 自举验证');
    console.log('==========================================================\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    // 查找 legion
    const autoBuiltLegionRoot = path.join(outputRoot, '_previous_legion');
    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        const gates = [
            createGate('上一代编译器入口', '未通过', '未找到可用 `legion`，且无法从 `NyarVM.cs` 自动构建'),
            createGate('源码 -> v1.nyar', '跳过', '上一代编译器入口未就绪'),
            createGate('v1 运行验收', '跳过', '源码 -> v1.nyar 未完成'),
            createGate('第二次 seed 编译 -> v2.nyar', '跳过', '上游门禁未就绪'),
            createGate('v1 / 第二次编译产物比对', '跳过', '上游门禁未就绪'),
        ];
        const blockers = ['上一代编译器入口未就绪'];
        const reportPath = writeReport(outputRoot, { success: false, gates, blockers, notes: [SECOND_COMPILE_NOTE] });
        printGateSummary(gates);
        console.error('\n错误：找不到上一代 legion CLI');
        console.error('请设置 --legion / LEGION_PATH，或保证 NyarVM.cs 可用以便脚本自动构建上一代 legion');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    // 查找 vcc（nyar 运行时）
    const vccPath = options.vcc ? path.resolve(options.vcc) : ensureVcc(outputRoot, options.verbose);
    if (!vccPath) {
        const gates = [
            createGate('上一代编译器入口', '通过', `使用现成入口：${legionPath}`),
            createGate('nyar 运行时入口', '未通过', '未找到可用 `vcc`，且无法从 `NyarVM.cs` 自动构建'),
            createGate('源码 -> v1.nyar', '跳过', 'nyar 运行时入口未就绪'),
            createGate('v1 运行验收', '跳过', '源码 -> v1.nyar 未完成'),
            createGate('第二次 seed 编译 -> v2.nyar', '跳过', '上游门禁未就绪'),
            createGate('v1 / 第二次编译产物比对', '跳过', '上游门禁未就绪'),
        ];
        const blockers = ['nyar 运行时入口未就绪'];
        const reportPath = writeReport(outputRoot, { success: false, gates, blockers, notes: [SECOND_COMPILE_NOTE] });
        printGateSummary(gates);
        console.error('\n错误：找不到 vcc CLI');
        console.error('请设置 --vcc / VCC_PATH，或保证 NyarVM.cs 可用以便脚本自动构建 vcc');
        console.log(`\n报告已写入：${reportPath}`);
        process.exit(1);
    }

    const previousCompilerDetail = legionPath.startsWith(autoBuiltLegionRoot)
        ? '已从 `NyarVM.cs` 自动构建上一代 `legion`'
        : `使用现成入口：${legionPath}`;

    // Level 1：源码 → v1.nyar
    const v1Result = compileV1(legionPath, vccPath, v1OutputDir, options.verbose);
    if (v1Result.success) {
        console.log('\nLevel 1（源码 → v1.nyar）成功');
        console.log(`v1 产物目录：${v1Result.outputDir}`);
        console.log(`v1 .nyar 哈希：${v1Result.hash}`);
    } else {
        console.error('\nLevel 1（源码 → v1.nyar）失败');
    }

    const v1RunPassed = Boolean(v1Result.success && v1Result.runtime?.run?.success);
    const v2SkipReason = !v1Result.success
        ? '源码 -> v1.nyar 未通过'
        : (!v1RunPassed ? 'v1 运行验收未通过，因此未执行第二次 seed 编译' : null);

    // Level 2：第二次 seed 编译 → v2.nyar
    const v2Result = v2SkipReason ? null : compileV2(legionPath, v2OutputDir, options.verbose);

    // 比对
    const compareResult = compareArtifacts(v1Result, v2Result, v2SkipReason);

    printSection('自举验证总结');

    console.log(`上一代编译器入口：通过`);
    console.log(`nyar 运行时入口：通过`);
    console.log(`源码 -> v1.nyar：${v1Result.success ? '通过' : '未通过'}`);
    console.log(`v1 运行验收（vcc run）：${v1Result.success ? (v1RunPassed ? '通过' : '未通过') : '跳过'}`);
    console.log(`第二次 seed 编译 -> v2.nyar：${v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过'}`);
    console.log(`v1 / 第二次编译产物比对：${compareResult.skipped ? '跳过' : (compareResult.match ? '一致' : '不一致')}`);
    console.log(`说明：${SECOND_COMPILE_NOTE}`);

    const blockers = [];
    if (!v1Result.success) {
        blockers.push(`源码 -> v1 失败：${v1Result.error}`);
    }
    if (v1Result.success && !v1RunPassed) {
        blockers.push(`v1 运行验收失败：${summarizeFailureOutput(v1Result.runtime?.run, 'vcc run 执行失败')}`);
    }
    if (v2Result && !v2Result.success) {
        blockers.push(`第二次 seed 编译失败：${v2Result.error}`);
    } else if (v2Result && compareResult.skipped) {
        blockers.push(`v1 / 第二次编译产物比对被跳过：${compareResult.reason}`);
    } else if (v2Result && !compareResult.match) {
        blockers.push('v1 / 第二次编译产物比对不一致');
    }

    const gates = [
        createGate('上一代编译器入口', '通过', previousCompilerDetail),
        createGate('nyar 运行时入口', '通过', `使用现成入口：${vccPath}`),
        createGate('源码 -> v1.nyar', v1Result.success ? '通过' : '未通过', v1Result.success ? `产物目录：${v1Result.outputDir}` : v1Result.error),
        createGate('v1 运行验收', v1Result.success ? (v1RunPassed ? '通过' : '未通过') : '跳过', v1Result.success ? (v1RunPassed ? 'vcc run 退出码 0' : summarizeFailureOutput(v1Result.runtime?.run, 'vcc run 执行失败')) : '源码 -> v1.nyar 未通过'),
        createGate('第二次 seed 编译 -> v2.nyar', v2Result ? (v2Result.success ? '通过' : '未通过') : '跳过', v2Result ? (v2Result.success ? `v2 哈希：${v2Result.hash}` : v2Result.error) : v2SkipReason),
        createGate('v1 / 第二次编译产物比对', compareResult.skipped ? '跳过' : (compareResult.match ? '通过' : '未通过'), compareResult.skipped ? compareResult.reason : (compareResult.match ? '`.nyar` 一致' : '产物比对不一致')),
    ];

    const reportPath = writeReport(outputRoot, {
        success: blockers.length === 0,
        notes: [SECOND_COMPILE_NOTE],
        gates,
        blockers,
        previousLegion: legionPath,
        vcc: vccPath,
        v1: {
            success: v1Result.success,
            outputDir: v1Result.outputDir,
            hash: v1Result.hash,
            runtime: {
                run: v1RunPassed,
            },
        },
        v2: {
            executed: v2Result !== null,
            method: 'repeat_seed_compile',
            note: SECOND_COMPILE_NOTE,
            success: v2Result?.success ?? false,
            compared: !compareResult.skipped,
            match: compareResult.match,
            hash: v2Result?.hash ?? null,
        },
    });

    printGateSummary(gates);
    console.log(`\n报告已写入：${reportPath}`);

    if (blockers.length > 0) {
        console.log('\n当前仍未满足真实自举验收，阻断项如下：');
        for (const blocker of blockers) {
            console.log(`  - ${blocker}`);
        }
        process.exit(1);
    }

    process.exit(0);
}

main();
