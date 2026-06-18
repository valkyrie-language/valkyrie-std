#!/usr/bin/env node

/**
 * JVM 自举验证脚本
 *
 * 执行 JVM 端的真实自举验收：
 *   1. 上一代编译器可用
 *   2. 源码 -> v1.jvm
 *   3. v1.jvm 本身可运行最小命令
 *   4. v1.jvm -> v2.jvm
 *   5. v1 / v2 可比较
 *
 * 流程：
 *   1. 用上一代编译器（NyarVM.cs legion）编译 valkyrie.v/projects/legion.tools → v1
 *   2. 验证 v1 产物的 `--version` / `--help`
 *   3. 用 v1 产物再次编译同一份源码 → v2
 *   4. 比对 v1 与 v2 的产物
 *
 * 用法：
 *   node scripts/bootstrap-jvm.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * 当前状态：
 *   - 本脚本用于“诚实失败”的真实验收，不再把半完成状态记为成功
 *   - 只要 v1 运行失败、v2 未接线或比对跳过，脚本都会返回非零退出码
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import crypto from 'crypto';

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]):\//, '$1:/'));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

// ─────────────────────────────────────────────────────────────
// 配置
// ─────────────────────────────────────────────────────────────

const BOOTSTRAP_PROJECT = 'projects/legion.tools';
const BOOTSTRAP_PROJECT_DIR = path.join(ROOT_DIR, BOOTSTRAP_PROJECT);
const TARGET_TRIPLE = 'jvm-openjdk-unknown-managed';
const EXPECTED_ARTIFACT_BASENAME = 'legion';
const KNOWN_WRONG_ARTIFACT_BASENAME = 'legion_tools';

// ─────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: options.silent ? 'pipe' : 'inherit',
        });
        return { success: true, stdout: result || '' };
    } catch (error) {
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

function findLegion() {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }

    const candidates = [
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion')),
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion-tool')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Release', 'net10.0')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'bin', 'Debug', 'net10.0')),
    ];
    for (const c of candidates) {
        if (fs.existsSync(c)) {
            return c;
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

function resolveJvmArtifacts(targetDir) {
    return {
        expectedJar: path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.jar`),
        expectedClass: path.join(targetDir, `${EXPECTED_ARTIFACT_BASENAME}.class`),
        knownWrongJar: path.join(targetDir, `${KNOWN_WRONG_ARTIFACT_BASENAME}.jar`),
        knownWrongClass: path.join(targetDir, `${KNOWN_WRONG_ARTIFACT_BASENAME}.class`),
    };
}

function probeJarRuntime(jarPath, label) {
    console.log(`\n验证 ${label} 产物...`);

    const version = runCommand(`java -jar "${jarPath}" --version`, { silent: true, timeout: 10000 });
    if (version.success) {
        console.log(`  ${label} --version：${version.stdout.trim()}`);
    } else {
        console.error(`  ${label} --version 失败：${version.stderr?.slice(0, 300)}`);
    }

    const help = runCommand(`java -jar "${jarPath}" --help`, { silent: true, timeout: 10000 });
    if (help.success) {
        console.log(`  ${label} --help：退出码 0`);
    } else {
        console.error(`  ${label} --help 失败：${help.stderr?.slice(0, 300)}`);
    }

    return { version, help };
}

// ─────────────────────────────────────────────────────────────
// Level 1：源码 → v1.jvm
// ─────────────────────────────────────────────────────────────

function compileV1(legionPath, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 1：源码 → v1.jvm');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`上一代编译器：${legionPath}`);
    console.log(`源码项目：${BOOTSTRAP_PROJECT_DIR}`);
    console.log(`输出目录：${outputDir}\n`);

    const versionCheck = runCommand(`"${legionPath}" --version`, { silent: true, timeout: 10000 });
    if (!versionCheck.success) {
        console.error('错误：上一代编译器不可用');
        console.error(versionCheck.stderr);
        return null;
    }
    console.log(`上一代编译器版本：${versionCheck.stdout.trim()}`);

    if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
    }

    console.log('\n编译中...');
    const buildResult = runCommand(
        `"${legionPath}" build "${BOOTSTRAP_PROJECT_DIR}" --target jvm -o "${outputDir}"`,
        { cwd: ROOT_DIR, timeout: 300000 }
    );

    if (!buildResult.success) {
        console.error('错误：v1 编译失败');
        if (buildResult.stderr) {
            console.error(buildResult.stderr.slice(0, 2000));
        }
        return null;
    }

    const targetDir = path.join(outputDir, TARGET_TRIPLE);
    if (!fs.existsSync(targetDir)) {
        console.error(`错误：v1 输出目录不存在：${targetDir}`);
        return null;
    }

    const artifacts = resolveJvmArtifacts(targetDir);
    const expectedJarExists = fs.existsSync(artifacts.expectedJar);
    const expectedClassExists = fs.existsSync(artifacts.expectedClass);
    const knownWrongJarExists = fs.existsSync(artifacts.knownWrongJar);
    const knownWrongClassExists = fs.existsSync(artifacts.knownWrongClass);

    const v1Artifacts = collectFiles(targetDir, ['.jar', '.class', '.txt', '.ps1', '.sh']);
    console.log(`\nv1 产物清单（${v1Artifacts.length} 个文件）：`);
    for (const artifact of v1Artifacts) {
        console.log(`  ${path.relative(targetDir, artifact)}`);
    }

    const blockers = [];

    if (!expectedJarExists) {
        blockers.push(`正确目标产物不存在：${path.basename(artifacts.expectedJar)}`);
    }
    if (!expectedClassExists) {
        blockers.push(`正确目标 class 不存在：${path.basename(artifacts.expectedClass)}`);
    }
    if (knownWrongJarExists || knownWrongClassExists) {
        blockers.push(`当前仍产出已知错误命名：${KNOWN_WRONG_ARTIFACT_BASENAME}.*（正确目标应为 ${EXPECTED_ARTIFACT_BASENAME}.*）`);
    }

    let runtime = null;
    let runtimeProbeJar = null;
    let runtimeProbeLabel = null;

    if (expectedJarExists) {
        runtimeProbeJar = artifacts.expectedJar;
        runtimeProbeLabel = path.basename(artifacts.expectedJar);
    } else if (knownWrongJarExists) {
        runtimeProbeJar = artifacts.knownWrongJar;
        runtimeProbeLabel = `${path.basename(artifacts.knownWrongJar)}（当前实际产物，仅用于诊断）`;
    }

    if (runtimeProbeJar) {
        runtime = probeJarRuntime(runtimeProbeJar, runtimeProbeLabel);
    } else {
        blockers.push('当前未找到任何可执行的 jar 产物，无法进行运行诊断');
    }

    return {
        outputDir: targetDir,
        legionJar: artifacts.expectedJar,
        legionClass: artifacts.expectedClass,
        actualJar: runtimeProbeJar,
        actualClass: expectedClassExists ? artifacts.expectedClass : (knownWrongClassExists ? artifacts.knownWrongClass : null),
        artifacts: v1Artifacts,
        hash: computeDirHash(targetDir, ['.class']),
        runtime,
        blockers,
        expectedArtifactExists: expectedJarExists && expectedClassExists,
        actualArtifactName: runtimeProbeJar ? path.basename(runtimeProbeJar) : null,
        usedDiagnosticArtifact: runtimeProbeJar === artifacts.knownWrongJar,
    };
}

// ─────────────────────────────────────────────────────────────
// Level 2：v1.jvm → v2.jvm（待接线）
// ─────────────────────────────────────────────────────────────

function compileV2(v1Result, outputDir, verbose) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  Level 2：v1.jvm → v2.jvm');
    console.log('══════════════════════════════════════════════════\n');

    console.log('状态：未接线');
    if (!v1Result.expectedArtifactExists) {
        console.log('原因：当前连正确的 v1 目标产物 `legion.jar` 都未产出，');
        console.log('      仍停留在错误命名产物或不完整产物阶段，无法作为真实二编入口。');
    } else {
        console.log('原因：v1 产物（valkyrie.v legion）当前尚未形成可复用的 JVM 编译器入口，');
        console.log('      还不能稳定承担第二轮 `.v` 源码编译。');
    }
    console.log('');
    console.log('待完成工作：');
    console.log('  1. 先产出正确命名且可运行的 `legion.jar`');
    console.log('  2. 让 v1 JVM 产物具备真实可调用的编译器入口');
    console.log('  3. 用 v1 产物编译 valkyrie.v/projects/legion.tools → v2');
    console.log('  4. 比对 v1 与 v2 的 .class 产物');
    console.log('');
    console.log('命令（待 v1 编译器后端就绪后启用）：');
    console.log(`  java -jar "${v1Result.legionJar}" build "${BOOTSTRAP_PROJECT_DIR}" --target jvm -o "${outputDir}"`);

    return null;
}

// ─────────────────────────────────────────────────────────────
// 比对
// ─────────────────────────────────────────────────────────────

⍝ v1 / v2 比对规则（固化结论）
///
⍝ 必须比对（不一致则阻断）：
⍝   - .class 文件：核心 JVM 字节码产物，是自举一致性的主要判定依据
⍝   - run-contract.txt：运行契约，必须完全一致
///
⍝ 允许差异（不阻断）：
⍝   - .jar：ZIP 封装可能带时间戳或打包顺序差异
⍝   - .ps1 / .sh：运行包装脚本不作为核心一致性依据
///
⍝ 阻断条件：
⍝   - 任一 .class 文件哈希不一致 → 阻断
⍝   - run-contract.txt 不一致 → 阻断
⍝   - 产物清单结构不一致（多了或少了 .class 文件）→ 阻断

function compareArtifacts(v1Result, v2Result) {
    console.log('\n══════════════════════════════════════════════════');
    console.log('  v1 / v2 比对');
    console.log('══════════════════════════════════════════════════\n');

    if (!v1Result || !v2Result) {
        console.log('比对跳过：v1 或 v2 产物缺失');
        return { match: false, skipped: true };
    }

    const mustCompareExtensions = ['.class'];
    const mustCompareFiles = ['run-contract.txt'];
    const allowedDiffExtensions = ['.jar', '.ps1', '.sh'];

    console.log('比对规则：');
    console.log('  必须一致：.class 文件、run-contract.txt');
    console.log('  允许差异：.jar、.ps1、.sh');
    console.log('');

    const v1ClassFiles = collectFiles(v1Result.outputDir, mustCompareExtensions);
    const v2ClassFiles = collectFiles(v2Result.outputDir, mustCompareExtensions);

    const v1ClassNames = new Set(v1ClassFiles.map(f => path.basename(f)));
    const v2ClassNames = new Set(v2ClassFiles.map(f => path.basename(f)));

    let allMatch = true;
    const details = [];

    const onlyInV1 = [...v1ClassNames].filter(n => !v2ClassNames.has(n));
    const onlyInV2 = [...v2ClassNames].filter(n => !v1ClassNames.has(n));

    if (onlyInV1.length > 0) {
        console.log(`  [阻断] 仅在 v1 中存在的 .class 文件：${onlyInV1.join(', ')}`);
        details.push({ type: 'missing_in_v2', files: onlyInV1 });
        allMatch = false;
    }
    if (onlyInV2.length > 0) {
        console.log(`  [阻断] 仅在 v2 中存在的 .class 文件：${onlyInV2.join(', ')}`);
        details.push({ type: 'extra_in_v2', files: onlyInV2 });
        allMatch = false;
    }

    const common = [...v1ClassNames].filter(n => v2ClassNames.has(n));
    for (const name of common) {
        const v1File = v1ClassFiles.find(f => path.basename(f) === name);
        const v2File = v2ClassFiles.find(f => path.basename(f) === name);
        if (v1File && v2File) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${name}：哈希不一致`);
                console.log(`    v1: ${h1}`);
                console.log(`    v2: ${h2}`);
                details.push({ type: 'class_hash_mismatch', file: name, v1Hash: h1, v2Hash: h2 });
                allMatch = false;
            } else {
                console.log(`  [通过] ${name}：一致`);
            }
        }
    }

    for (const fileName of mustCompareFiles) {
        const v1File = path.join(v1Result.outputDir, fileName);
        const v2File = path.join(v2Result.outputDir, fileName);

        const v1Exists = fs.existsSync(v1File);
        const v2Exists = fs.existsSync(v2File);

        if (v1Exists && v2Exists) {
            const h1 = computeFileHash(v1File);
            const h2 = computeFileHash(v2File);
            if (h1 !== h2) {
                console.log(`  [阻断] ${fileName}：不一致`);
                details.push({ type: 'contract_mismatch', file: fileName });
                allMatch = false;
            } else {
                console.log(`  [通过] ${fileName}：一致`);
            }
        } else if (v1Exists !== v2Exists) {
            console.log(`  [阻断] ${fileName}：${v1Exists ? '仅 v1 存在' : '仅 v2 存在'}`);
            details.push({ type: 'contract_missing', file: fileName });
            allMatch = false;
        }
    }

    const allowedFiles = collectFiles(v1Result.outputDir, allowedDiffExtensions);
    if (allowedFiles.length > 0) {
        console.log(`\n允许差异的文件（${allowedFiles.length} 个，不参与比对）：`);
        for (const f of allowedFiles) {
            console.log(`  ${path.relative(v1Result.outputDir, f)}`);
        }
    }

    return { match: allMatch, skipped: false, details };
}

// ─────────────────────────────────────────────────────────────
// 主入口
// ─────────────────────────────────────────────────────────────

function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        legion: null,
        output: null,
        verbose: false,
    };

    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--legion':
                options.legion = args[++i];
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
JVM 自举验证脚本

用法：node scripts/bootstrap-jvm.mjs [选项]

选项：
  --legion <path>     上一代编译器路径（默认自动查找）
  --output, -o <dir>  输出根目录（默认 ./dist/bootstrap-jvm）
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
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-jvm'));
    const v1OutputDir = path.join(outputRoot, 'v1');
    const v2OutputDir = path.join(outputRoot, 'v2');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║             JVM 自举验证                                ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');

    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：${BOOTSTRAP_PROJECT}`);
    console.log(`目标三元组：${TARGET_TRIPLE}\n`);

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        console.error('错误：找不到上一代 legion CLI');
        console.error('请设置 --legion / LEGION_PATH，或保证 NyarVM.cs 可用以便脚本自动构建上一代 legion');
        process.exit(1);
    }

    const v1Result = compileV1(legionPath, v1OutputDir, options.verbose);
    if (!v1Result) {
        console.error('\nLevel 1（源码 → v1.jvm）失败');
        process.exit(1);
    }
    console.log('\nLevel 1（源码 → v1.jvm）已完成编译尝试');
    console.log(`v1 产物目录：${v1Result.outputDir}`);
    console.log(`v1 .class 哈希：${v1Result.hash}`);
    if (v1Result.actualArtifactName) {
        console.log(`v1 运行诊断产物：${v1Result.actualArtifactName}`);
    }

    const v1VersionPassed = Boolean(v1Result.runtime?.version?.success);
    const v1HelpPassed = Boolean(v1Result.runtime?.help?.success);
    const v1RuntimePassed = v1VersionPassed && v1HelpPassed;

    const v2Result = compileV2(v1Result, v2OutputDir, options.verbose);
    const compareResult = compareArtifacts(v1Result, v2Result);

    console.log('\n══════════════════════════════════════════════════');
    console.log('  自举验证总结');
    console.log('══════════════════════════════════════════════════\n');

    console.log(`Level 1（源码 → v1.jvm 编译命令）：通过`);
    console.log(`Level 1 正确产物（legion.jar / legion.class）：${v1Result.expectedArtifactExists ? '通过' : '未通过'}`);
    console.log(`Level 1 运行验收（${v1Result.actualArtifactName || '无可执行 jar'} --version / --help）：${v1RuntimePassed ? '通过' : '未通过'}`);
    console.log(`Level 2（v1.jvm → v2.jvm）：${v2Result ? (compareResult.match ? '通过' : '未通过（产物不一致）') : '未接线'}`);
    console.log(`v1 / v2 比对：${compareResult.skipped ? '跳过' : (compareResult.match ? '一致' : '不一致')}`);

    const blockers = [...v1Result.blockers];
    if (!v1VersionPassed) {
        blockers.push('v1 --version 仍失败');
    }
    if (!v1HelpPassed) {
        blockers.push('v1 --help 仍失败');
    }
    if (!v2Result) {
        blockers.push('v1 -> v2 尚未接线');
    } else if (compareResult.skipped) {
        blockers.push('v1 / v2 比对被跳过');
    } else if (!compareResult.match) {
        blockers.push('v1 / v2 产物比对不一致');
    }

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
