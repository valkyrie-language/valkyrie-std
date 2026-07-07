namespace nyar.language.valkyrie;

using std.io;

micro compile_smoke_project(plan_path: utf8, dependency_count: i32) -> SmokeCompileResult {
    let plan = parse_compile_plan_snapshot(plan_path)
    if plan.output_dir.length() == 0 {
        return SmokeCompileResult {
            ok: false,
            error: "无法读取 compile-plan.txt：" + plan_path,
            output: SmokeBuildOutput {
                assembly_name: "",
                namespace_symbol: "",
                console_message: "",
                source_files: []
            }
        }
    }
    if dependency_count > 0 {
        return SmokeCompileResult {
            ok: false,
            error: "依赖闭包超出 smoke 子集：暂不支持 workspace 依赖包",
            output: SmokeBuildOutput {
                assembly_name: "",
                namespace_symbol: "",
                console_message: "",
                source_files: []
            }
        }
    }
    let combined = load_source_files(plan.source_files)
    let frontend = compile_source_to_build_output(combined, plan.source_files.length())
    if !frontend.ok {
        return frontend
    }
    let emit_error = emit_smoke_clr_artifacts(plan, frontend.output)
    if emit_error.is_some() {
        return SmokeCompileResult {
            ok: false,
            error: emit_error.unwrap(),
            output: frontend.output
        }
    }
    return SmokeCompileResult {
        ok: true,
        error: "",
        output: frontend.output
    }
}

micro digit_value(ch: utf8) -> i32 {
    if ch == "0" { return 0 }
    if ch == "1" { return 1 }
    if ch == "2" { return 2 }
    if ch == "3" { return 3 }
    if ch == "4" { return 4 }
    if ch == "5" { return 5 }
    if ch == "6" { return 6 }
    if ch == "7" { return 7 }
    if ch == "8" { return 8 }
    if ch == "9" { return 9 }
    return -1
}

micro count_dependency_names(plan_path: utf8) -> i32 {
    if !std.io.file_exists(plan_path) {
        return -1
    }
    let text = std.io.read_file_text(plan_path)
    let lines = text.split("\n")
    # `utf8.slice(start, count)` — second arg is count, not end (CLR → Substring).
    let prefix_len: i32 = 17
    loop line in lines {
        let trimmed = line.trim()
        if trimmed.starts_with("dependency_names:") {
            let mut count: i32 = trimmed.length() - prefix_len
            if count < 0 {
                count = 0
            }
            let tail = trimmed.slice(prefix_len, count).trim()
            let mut value = 0
            let mut i = 0
            while i < tail.length() {
                let digit = digit_value(tail⁅i⁆)
                if digit < 0 {
                    break
                }
                value = value * 10 + digit
                i = i + 1
            }
            return value
        }
    }
    return 0
}
