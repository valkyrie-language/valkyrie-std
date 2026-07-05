namespace nyar.language.valkyrie;

using std.io;

[clr("System", "System.Diagnostics.Process", "Start")]
micro smoke_process_start(file_name: utf8, arguments: utf8) -> i32

micro dq() -> utf8 {
    return '''"'''
}

micro append_msil_line(buffer: utf8, line: utf8) -> utf8 {
    return buffer + line + "\n"
}

micro build_smoke_msil(output: SmokeBuildOutput) -> utf8 {
    let symbol: utf8 = output.namespace_symbol
    let mut msil: utf8 = ""
    msil = append_msil_line(msil, ".assembly extern mscorlib {}")
    msil = append_msil_line(msil, ".assembly extern System.Console {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".assembly " + output.assembly_name + " {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".method public hidebysig static int32 " + symbol + "__helper_label() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .maxstack 1")
    msil = append_msil_line(msil, "        ldc.i4.0")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".method public hidebysig static int32 " + symbol + "__console_write_line() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .maxstack 1")
    msil = append_msil_line(msil, "        ldc.i4.0")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".method public hidebysig static int32 " + symbol + "__version_text() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .maxstack 1")
    msil = append_msil_line(msil, "        ldc.i4.0")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".method public hidebysig static int32 " + symbol + "__main() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .maxstack 1")
    msil = append_msil_line(msil, "        ldstr " + dq() + output.console_message + dq())
    msil = append_msil_line(msil, "        call void [mscorlib]System.Console::WriteLine(string)")
    msil = append_msil_line(msil, "        ldc.i4.0")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".method public hidebysig static int32 entry_" + symbol + "__main() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .entrypoint")
    msil = append_msil_line(msil, "    .maxstack 1")
    msil = append_msil_line(msil, "        call int32 " + symbol + "__main()")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    return msil
}

micro build_runtime_config(artifact_name: utf8) -> utf8 {
    let q: utf8 = dq()
    let mut content: utf8 = "{\n"
    content = content + "  runtimeOptions: {\n"
    content = content + "    tfm: " + q + "net8.0" + q + ",\n"
    content = content + "    framework: {\n"
    content = content + "      name: " + q + "Microsoft.NETCore.App" + q + ",\n"
    content = content + "      version: " + q + "8.0.0" + q + "\n"
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

micro wait_for_file(path: utf8, attempts: i32) -> bool {
    let mut i: i32 = 0
    while i < attempts {
        if std.io.file_exists(path) {
            return true
        }
        i = i + 1
    }
    return false
}

micro quote_path(path: utf8) -> utf8 {
    return dq() + path + dq()
}

micro emit_smoke_clr_artifacts(plan: SmokeCompilePlan, build_output: SmokeBuildOutput) -> Option<utf8> {
    if !std.io.create_directory(plan.output_dir) {
        return Some("无法创建输出目录：" + plan.output_dir)
    }

    let artifact_name: utf8 = plan.project_name
    let msil_path: utf8 = path_join(plan.output_dir, artifact_name + ".msil")
    let exe_path: utf8 = path_join(plan.output_dir, artifact_name + ".exe")
    let runtime_path: utf8 = path_join(plan.output_dir, artifact_name + ".runtimeconfig.json")
    let contracts_path: utf8 = path_join(plan.output_dir, "run-contracts.txt")
    let contract_legacy_path: utf8 = path_join(plan.output_dir, "run-contract.txt")

    let msil: utf8 = build_smoke_msil(build_output)
    if !std.io.write_file_text(msil_path, msil) {
        return Some("写入 MSIL 失败：" + msil_path)
    }

    let runtime_config: utf8 = build_runtime_config(artifact_name)
    if !std.io.write_file_text(runtime_path, runtime_config) {
        return Some("写入 runtimeconfig 失败：" + runtime_path)
    }

    let contracts: utf8 = build_run_contracts(artifact_name)
    if !std.io.write_file_text(contracts_path, contracts) {
        return Some("写入 run-contracts.txt 失败")
    }
    if !std.io.write_file_text(contract_legacy_path, build_run_contract_legacy(artifact_name)) {
        return Some("写入 run-contract.txt 失败")
    }

    let ilasm_args: utf8 = "/c ilasm /nologo /exe /output=" + quote_path(exe_path) + " " + quote_path(msil_path)
    smoke_process_start("cmd.exe", ilasm_args)
    if !wait_for_file(exe_path, 500000) {
        return Some("ilasm 未产出可执行文件：" + exe_path + "（请确认 PATH 中存在 ilasm）")
    }

    return None
}
