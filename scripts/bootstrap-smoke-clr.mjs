#!/usr/bin/env node

/**
 * bootstrap-smoke CLR 切片验收
 *
 * 验证 v1 真编译 bootstrap-smoke（非 bridge、非 seed 代劳）：
 *   1. seed 编译 legion.tools → v1.clr
 *   2. v1 运行 --version / --help
 *   3. v1 编译 examples/bootstrap-smoke
 *   4. 校验 main.exe / main.msil / run-contract(s).txt 与 dotnet exec
 *
 * 用法：
 *   node scripts/bootstrap-smoke-clr.mjs [--legion <path>] [--output <dir>] [--verbose]
 *
 * 注意：完整 L2（legion.tools v1→v2）仍由 bootstrap-clr.mjs 验收。
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const VALKYRIE_RS_DIR = path.resolve(ROOT_DIR, '..', 'valkyrie.rs');
const NYARVM_DIR = path.resolve(ROOT_DIR, '..', 'NyarVM.cs');
const LEGION_CSPROJ = path.join(NYARVM_DIR, 'tools', 'legion', 'Legion.CLI.csproj');

const LEGION_TOOLS_DIR = path.join(ROOT_DIR, 'projects', 'legion.tools');
const SMOKE_PROJECT_DIR = path.join(ROOT_DIR, 'examples', 'bootstrap-smoke');

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, {
            encoding: 'utf8',
            timeout: options.timeout || 300000,
            cwd: options.cwd,
            stdio: options.silent ? 'pipe' : 'inherit',
            env: options.env ? { ...process.env, ...options.env } : process.env,
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

function resolveBuiltLegionCli(artifactDir) {
    const preferred = ['legion__main_legion.exe', 'legion.exe', 'legion__main_legion.dll', 'legion.dll'];
    for (const name of preferred) {
        const candidate = path.join(artifactDir, name);
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    if (!fs.existsSync(artifactDir)) {
        return null;
    }
    const files = fs
        .readdirSync(artifactDir)
        .filter((name) => /^legion.+\.(exe|dll)$/i.test(name) && !/__(?:vcc|voa)/i.test(name))
        .sort();
    const mainEntry = files.find((name) => /main_legion/i.test(name));
    if (mainEntry) {
        return path.join(artifactDir, mainEntry);
    }
    return files[0] ? path.join(artifactDir, files[0]) : null;
}

function findLegion() {
    const envPath = process.env.LEGION_PATH;
    if (envPath && fs.existsSync(envPath)) {
        return envPath;
    }
    const candidates = [
        ...legionLauncherCandidates(path.join(VALKYRIE_RS_DIR, 'target', 'release')),
        ...legionLauncherCandidates(path.join(VALKYRIE_RS_DIR, 'target', 'debug')),
        ...legionLauncherCandidates(path.join(ROOT_DIR, 'dist', 'legion')),
        ...legionLauncherCandidates(path.join(NYARVM_DIR, 'tools', 'legion', 'publish')),
    ];
    for (const candidate of candidates) {
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
    const publishResult = runCommand(
        `dotnet publish "${LEGION_CSPROJ}" -c Release --nologo -o "${toolOutputDir}" -p:UseAppHost=true`,
        { cwd: NYARVM_DIR, silent: !verbose, timeout: 300000 }
    );
    if (!publishResult.success) {
        return null;
    }
    return resolveLegionLauncher(toolOutputDir);
}

function parseArgs() {
    const args = process.argv.slice(2);
    const options = { legion: null, output: null, verbose: false };
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '--verbose' || arg === '-v') {
            options.verbose = true;
        } else if ((arg === '--legion' || arg === '-l') && i + 1 < args.length) {
            options.legion = args[++i];
        } else if ((arg === '--output' || arg === '-o') && i + 1 < args.length) {
            options.output = args[++i];
        }
    }
    return options;
}

function dotnetExec(artifact, cliArgs, options = {}) {
    const quoted = `"${artifact}"`;
    const argText = cliArgs.map((item) => `"${item}"`).join(' ');
    return runCommand(`dotnet exec ${quoted} ${argText}`, {
        silent: true,
        timeout: options.timeout || 120000,
        cwd: options.cwd,
    });
}

function main() {
    const options = parseArgs();
    const outputRoot = path.resolve(options.output || path.join(ROOT_DIR, 'dist', 'bootstrap-smoke-clr'));
    const v1Dir = path.join(outputRoot, 'v1');
    const smokeDir = path.join(outputRoot, 'smoke');

    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║        bootstrap-smoke CLR 切片验收                      ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');
    console.log(`输出根目录：${outputRoot}`);
    console.log(`自举项目：projects/legion._/projects/legion.tools`);
    console.log(`smoke 项目：examples/bootstrap-smoke\n`);

    const legionPath = options.legion ? path.resolve(options.legion) : ensurePreviousLegion(outputRoot, options.verbose);
    if (!legionPath) {
        console.error('错误：找不到 seed legion');
        process.exit(1);
    }
    console.log(`seed：${legionPath}`);

    if (fs.existsSync(v1Dir)) {
        fs.rmSync(v1Dir, { recursive: true, force: true });
    }
    console.log('\n[1/4] seed → v1（legion.tools）...');
    const v1Build = runCommand(
        `"${legionPath}" build "${LEGION_TOOLS_DIR}" --target clr -o "${v1Dir}"`,
        { cwd: ROOT_DIR, silent: !options.verbose, timeout: 300000 }
    );
    if (!v1Build.success) {
        console.error('错误：seed 编译 legion.tools 失败');
        process.exit(1);
    }

    const v1Exe = resolveBuiltLegionCli(v1Dir);
    if (!v1Exe) {
        console.error('错误：v1 产物不存在');
        process.exit(1);
    }
    console.log(`v1 入口：${v1Exe}`);

    console.log('\n[2/4] v1 CLI 契约...');
    const versionCheck = dotnetExec(v1Exe, ['--version'], { verbose: options.verbose });
    const helpCheck = dotnetExec(v1Exe, ['--help'], { verbose: options.verbose });
    if (!versionCheck.success || !helpCheck.success) {
        console.error('错误：v1 --version / --help 未通过');
        process.exit(1);
    }
    if (!String(versionCheck.stdout || '').includes('Legion')) {
        console.error('错误：v1 --version 未输出预期版本文本（CLR 仅外调路径）');
        process.exit(1);
    }

    if (fs.existsSync(smokeDir)) {
        fs.rmSync(smokeDir, { recursive: true, force: true });
    }
    console.log('\n[3/4] v1 → bootstrap-smoke（真 emitter）...');
    const smokeBuild = dotnetExec(
        v1Exe,
        ['build', SMOKE_PROJECT_DIR, '--target', 'clr', '-o', smokeDir, '--verbose'],
        { cwd: ROOT_DIR, verbose: options.verbose, timeout: 300000 }
    );
    if (!smokeBuild.success) {
        console.error('错误：v1 编译 bootstrap-smoke 失败');
        if (smokeBuild.stderr) {
            console.error(smokeBuild.stderr.slice(0, 2000));
        }
        process.exit(1);
    }

    const required = [
        path.join(smokeDir, 'main.exe'),
        path.join(smokeDir, 'main.msil'),
        path.join(smokeDir, 'run-contracts.txt'),
    ];
    for (const filePath of required) {
        if (!fs.existsSync(filePath)) {
            console.error(`错误：缺少产物 ${filePath}`);
            console.error('说明：v1 已能通过 [clr] 外调输出 --version，但 legion build 仍需 CLR 分支/内部调用降低；');
            console.error('      emitter smoke 链已在 V 侧实现，待 CLR 前端补齐后即可通过本门。');
            const backendResult = path.join(smokeDir, 'backend-result.txt');
            if (fs.existsSync(backendResult)) {
                console.error(fs.readFileSync(backendResult, 'utf8').slice(0, 1500));
            }
            process.exit(1);
        }
    }

    console.log('\n[4/4] dotnet exec main.exe ...');
    const runCheck = runCommand(`dotnet exec "${path.join(smokeDir, 'main.exe')}"`, {
        silent: false,
        timeout: 30000,
    });
    if (!runCheck.success) {
        console.error('错误：smoke 产物运行失败');
        process.exit(1);
    }

    const reportPath = path.join(outputRoot, 'bootstrap-smoke-report.json');
    fs.mkdirSync(outputRoot, { recursive: true });
    fs.writeFileSync(
        reportPath,
        `${JSON.stringify(
            {
                success: true,
                seed: legionPath,
                v1_exe: v1Exe,
                smoke_dir: smokeDir,
                artifacts: required.map((item) => path.basename(item)),
            },
            null,
            2
        )}\n`,
        'utf8'
    );

    console.log('\n══════════════════════════════════════════════════');
    console.log('  bootstrap-smoke 切片验收通过');
    console.log('══════════════════════════════════════════════════\n');
    console.log(`报告：${reportPath}`);
}

main();
