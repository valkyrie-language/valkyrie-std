namespace nyar.language.valkyrie;

using std.io;

# Node/wasm 自举：由宿主 glue 读取 compile-plan.txt 并执行真实 legion build，产出 legion.wasm / legion.mjs。
[wasm("env", "host_legion_compile_from_plan")]
private micro host_legion_compile_from_plan(plan_path: utf8) -> i32;

micro target_uses_wasm_node_backend(canonical_target: utf8) -> bool {
    if canonical_target == "node" {
        return true
    }
    if canonical_target.starts_with("wasm32-node") {
        return true
    }
    if canonical_target.starts_with("wasm32-") && canonical_target.contains("wasm") {
        return true
    }
    return false
}

micro compile_wasm_node_from_plan(plan_path: utf8) -> CompileResult {
    let plan: SmokeCompilePlan = parse_compile_plan_snapshot(plan_path)
    if plan.output_dir.length() == 0 {
        return CompileResult {
            ok: false,
            error: "无法读取 compile-plan.txt：" + plan_path,
            output: empty_compile_output()
        }
    }
    if plan.source_files.length() == 0 {
        return CompileResult {
            ok: false,
            error: "compile-plan 未包含源码文件",
            output: empty_compile_output()
        }
    }

    let exit_code: i32 = host_legion_compile_from_plan(plan_path)
    if exit_code != 0 {
        return CompileResult {
            ok: false,
            error: "host wasm 编译失败，退出码 = " + format("{}", exit_code),
            output: CompileOutput {
                assembly_name: plan.project_name,
                namespace_symbol: plan.project_name,
                console_message: "",
                source_files: plan.source_files
            }
        }
    }

    let wasm_path: utf8 = path_join(plan.output_dir, plan.project_name + ".wasm")
    let mjs_path: utf8 = path_join(plan.output_dir, plan.project_name + ".mjs")
    if !std.io.file_exists(wasm_path) {
        let alt_wasm: utf8 = path_join(plan.output_dir, "legion.wasm")
        let alt_mjs: utf8 = path_join(plan.output_dir, "legion.mjs")
        if !std.io.file_exists(alt_wasm) || !std.io.file_exists(alt_mjs) {
            return CompileResult {
                ok: false,
                error: "host 编译完成但未产出 legion.wasm / legion.mjs：" + plan.output_dir,
                output: CompileOutput {
                    assembly_name: plan.project_name,
                    namespace_symbol: plan.project_name,
                    console_message: "",
                    source_files: plan.source_files
                }
            }
        }
    }

    return CompileResult {
        ok: true,
        error: "",
        output: CompileOutput {
            assembly_name: plan.project_name,
            namespace_symbol: plan.project_name,
            console_message: "wasm-node host compile ok",
            source_files: plan.source_files
        }
    }
}
