namespace nyar.language.valkyrie;

using std.io;

micro compile_project_from_plan(plan_path: utf8, dependency_count: i32) -> CompileResult {
    let plan_opt: Option<SmokeCompilePlan> = parse_compile_plan_snapshot(plan_path)
    if plan_opt.is_none() {
        return CompileResult {
            ok: false,
            error: "无法读取 compile-plan.txt：" + plan_path,
            output: empty_compile_output()
        }
    }
    let plan: SmokeCompilePlan = plan_opt.unwrap()
    if dependency_count > 0 {
        return CompileResult {
            ok: false,
            error: "依赖闭包超出 smoke 子集：暂不支持 workspace 依赖包",
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

    let submission: FragmentSubmission = build_fragment_from_files(plan.source_files, plan.project_name)
    if submission.entry_operation.length() == 0 {
        return CompileResult {
            ok: false,
            error: "未找到 [main] 入口函数",
            output: empty_compile_output()
        }
    }
    if submission.external_call_edges.length() == 0 {
        return CompileResult {
            ok: false,
            error: "未找到可降低的外部调用边",
            output: empty_compile_output()
        }
    }

    let lowered: LoweredClrModule = lower_fragment_to_clr(submission)
    let emit_error: Option<utf8> = emit_clr_artifacts(plan, lowered)
    if emit_error.is_some() {
        return CompileResult {
            ok: false,
            error: emit_error.unwrap(),
            output: CompileOutput {
                assembly_name: lowered.assembly_name,
                namespace_symbol: submission.module_name,
                console_message: lowered.console_message,
                source_files: plan.source_files
            }
        }
    }

    return CompileResult {
        ok: true,
        error: "",
        output: CompileOutput {
            assembly_name: lowered.assembly_name,
            namespace_symbol: submission.module_name,
            console_message: lowered.console_message,
            source_files: plan.source_files
        }
    }
}
