namespace nyar.language.valkyrie;

using std.io;

# BCL returns Process; seed CLR emitter must DiscardRef when desired is unit.
[clr("System", "System.Diagnostics.Process", "Start")]
micro clr_process_start(file_name: utf8, arguments: utf8) -> unit

# Avoid busy-spin in wait_for_file (Unity/PATH ilasm hang otherwise pegs CPU).
# Bind mscorlib — System.Runtime Thread fails TypeLoad under Framework-produced hosts.
[clr("mscorlib", "System.Threading.Thread", "Sleep")]
micro clr_thread_sleep(millisecondsTimeout: i32) -> unit

micro dq() -> utf8 {
    return '''"'''
}

micro quote_path(path: utf8) -> utf8 {
    return dq() + path + dq()
}

micro build_clr_runtime_config() -> utf8 {
    let q: utf8 = dq()
    let mut content: utf8 = "{\n"
    content = content + "  " + q + "runtimeOptions" + q + ": {\n"
    content = content + "    " + q + "tfm" + q + ": " + q + "net8.0" + q + ",\n"
    content = content + "    " + q + "framework" + q + ": {\n"
    content = content + "      " + q + "name" + q + ": " + q + "Microsoft.NETCore.App" + q + ",\n"
    content = content + "      " + q + "version" + q + ": " + q + "8.0.0" + q + "\n"
    content = content + "    }\n"
    content = content + "  }\n"
    content = content + "}\n"
    return content
}

micro build_run_contracts(artifact_name: utf8) -> utf8 {
    let q: utf8 = dq()
    let physical: utf8 = artifact_name + ".exe"
    let mut content: utf8 = "{\n"
    content = content + "    artifacts: [\n"
    content = content + "        { path: " + q + physical + q + " },\n"
    content = content + "        { path: " + q + artifact_name + ".msil" + q + " },\n"
    content = content + "        { path: " + q + artifact_name + ".runtimeconfig.json" + q + " }\n"
    content = content + "    ],\n"
    content = content + "    project_name: " + q + artifact_name + q + ",\n"
    content = content + "    run_contracts: [\n"
    content = content + "        {\n"
    content = content + "            invocation: " + q + "dotnet" + q + ",\n"
    content = content + "            logical_entry: " + q + "Main" + q + ",\n"
    content = content + "            physical_entry: " + q + physical + q + ",\n"
    content = content + "            validate: " + q + "dotnet exec " + physical + q + "\n"
    content = content + "        }\n"
    content = content + "    ],\n"
    content = content + "    schema_version: 1,\n"
    content = content + "    target: " + q + "clr-microsoft-unknown-managed" + q + "\n"
    content = content + "}\n"
    return content
}

micro build_run_contract_legacy(artifact_name: utf8) -> utf8 {
    let q: utf8 = dq()
    let physical: utf8 = artifact_name + ".exe"
    let mut content: utf8 = "{\n"
    content = content + "    invocation: " + q + "dotnet" + q + ",\n"
    content = content + "    logical_entry: " + q + "Main" + q + ",\n"
    content = content + "    physical_entry: " + q + physical + q + ",\n"
    content = content + "    validate: " + q + "dotnet exec " + physical + q + "\n"
    content = content + "}\n"
    return content
}

# Poll with sleep — never busy-spin. Default ~ attempts * 50ms wall time.
micro wait_for_file(path: utf8, attempts: i32) -> bool {
    let mut i: i32 = 0
    while i < attempts {
        if std.io.file_exists(path) {
            return true
        }
        clr_thread_sleep(50)
        i = i + 1
    }
    return false
}

# Replace non-ASCII code units with '?' so .msil stays Framework-ilasm-safe.
micro msil_force_ascii(text: utf8) -> utf8 {
    let mut ascii: utf8 = "\t\n\r !#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{}~"
    ascii = ascii + dq()
    ascii = ascii + "\u{5c}"
    ascii = ascii + "\u{27}"
    ascii = ascii + "\u{60}"
    ascii = ascii + "|"
    let mut out: utf8 = ""
    let mut i: i32 = 0
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if ascii.contains(ch) {
            out = out + ch
        }
        else {
            out = out + "?"
        }
        i = i + 1
    }
    return out
}

# Force Framework ilasm only — never PATH/Unity Mono ilasm.
micro resolve_ilasm_exe() -> utf8 {
    let a: utf8 = "C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\ilasm.exe"
    if std.io.file_exists(a) {
        return a
    }
    let b: utf8 = "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\ilasm.exe"
    if std.io.file_exists(b) {
        return b
    }
    return ""
}

micro emit_clr_artifacts(plan: SmokeCompilePlan, lowered: LoweredClrModule) -> utf8 {
    if !std.io.create_directory(plan.output_dir) {
        return "无法创建输出目录：" + plan.output_dir
    }

    let artifact_name: utf8 = plan.project_name
    let msil_path: utf8 = path_join(plan.output_dir, artifact_name + ".msil")
    let exe_path: utf8 = path_join(plan.output_dir, artifact_name + ".exe")
    let runtime_path: utf8 = path_join(plan.output_dir, artifact_name + ".runtimeconfig.json")
    let contracts_path: utf8 = path_join(plan.output_dir, "run-contracts.txt")
    let contract_legacy_path: utf8 = path_join(plan.output_dir, "run-contract.txt")

    # Bind utf8 locals before write — CLR must not emit WriteAllText(string, object).
    # Do not ASCII-scrub the whole buffer here — CLR SSA clobbers huge `out = out + ch` loops.
    # Non-ASCII ldstr must go through msil_quote_string at emit sites.
    let msil_text: utf8 = lowered.msil
    if !std.io.write_file_text(msil_path, msil_text) {
        return "写入 MSIL 失败：" + msil_path
    }

    let runtime_text: utf8 = build_clr_runtime_config()
    if !std.io.write_file_text(runtime_path, runtime_text) {
        return "写入 runtimeconfig 失败：" + runtime_path
    }

    let contracts_text: utf8 = build_run_contracts(artifact_name)
    if !std.io.write_file_text(contracts_path, contracts_text) {
        return "写入 run-contracts.txt 失败"
    }
    let contract_legacy_text: utf8 = build_run_contract_legacy(artifact_name)
    if !std.io.write_file_text(contract_legacy_path, contract_legacy_text) {
        return "写入 run-contract.txt 失败"
    }

    let ilasm: utf8 = resolve_ilasm_exe()
    if ilasm.length() == 0 {
        return "缺少 Framework ilasm（Framework64 v4.0.30319）"
    }
    # cmd /c ""exe" args" — Framework path only; never PATH/Unity ilasm
    let q: utf8 = dq()
    let ilasm_args: utf8 = "/c " + q + q + ilasm + q + " /nologo /exe /output=" + quote_path(exe_path) + " " + quote_path(msil_path) + q
    clr_process_start("cmd.exe", ilasm_args)
    # ~60s cap (1200 * 50ms); no busy-spin
    if !wait_for_file(exe_path, 1200) {
        return "ilasm 未产出可执行文件：" + exe_path + "（Framework ilasm=" + ilasm + "）"
    }

    return ""
}
