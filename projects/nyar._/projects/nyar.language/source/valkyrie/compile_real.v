namespace nyar.language.valkyrie;

using std.io;

# Parent directory of a file path (slash-normalized). Empty if none.
micro file_parent_dir(path: utf8) -> utf8 {
    let p: utf8 = path.replace("\u{5c}", "/")
    let mut i: i32 = p.length() - 1
    while i >= 0 {
        if p.slice(i, 1) == "/" {
            if i == 0 {
                return "/"
            }
            return p.slice(0, i)
        }
        i = i - 1
    }
    return ""
}

micro push_unique_path(acc: [utf8], path: utf8) -> [utf8] {
    let p: utf8 = path.replace("\u{5c}", "/")
    let mut j: usize = 0
    while j < acc.length() {
        if acc⁅j⁆ == p {
            return acc
        }
        j = j + 1
    }
    return push(acc, p)
}

# CLR planner / GetFiles sometimes drops siblings (e.g. kind.v, build_planner.v).
# Re-scan project source plus every directory already present in the plan.
micro ensure_project_sources(files: [utf8], project_dir: utf8) -> [utf8] {
    let mut acc: [utf8] = []
    let mut dirs: [utf8] = []
    if project_dir.length() > 0 {
        let source_dir: utf8 = path_join(project_dir, "source")
        if std.io.directory_exists(source_dir) {
            dirs = push_unique_path(dirs, source_dir)
        }
    }
    let mut fi: usize = 0
    while fi < files.length() {
        let parent: utf8 = file_parent_dir(files⁅fi⁆)
        if parent.length() > 0 && std.io.directory_exists(parent) {
            dirs = push_unique_path(dirs, parent)
        }
        fi = fi + 1
    }
    # Prefer project sources first so `[main]` / `legion` are parsed before deps.
    let mut di: usize = 0
    while di < dirs.length() {
        let discovered: [utf8] = std.io.get_files(dirs⁅di⁆, "*.v", false)
        let mut i: usize = 0
        while i < discovered.length() {
            acc = push_unique_path(acc, discovered⁅i⁆)
            i = i + 1
        }
        di = di + 1
    }
    fi = 0
    while fi < files.length() {
        acc = push_unique_path(acc, files⁅fi⁆)
        fi = fi + 1
    }
    # Seed GetFiles has dropped short sibling names (kind.v); force-add if parent was seen.
    di = 0
    while di < dirs.length() {
        let forced: utf8 = path_join(dirs⁅di⁆, "kind.v")
        if std.io.file_exists(forced) {
            acc = push_unique_path(acc, forced)
        }
        let forced2: utf8 = path_join(dirs⁅di⁆, "build_planner.v")
        if std.io.file_exists(forced2) {
            acc = push_unique_path(acc, forced2)
        }
        let forced3: utf8 = path_join(dirs⁅di⁆, "build_context.v")
        if std.io.file_exists(forced3) {
            acc = push_unique_path(acc, forced3)
        }
        di = di + 1
    }
    return acc
}

micro compile_project_from_plan(plan_path: utf8, dependency_count: i32) -> CompileResult {
    std.io.print_line("[v1-debug] compile_project_from_plan enter")
    let plan: SmokeCompilePlan = parse_compile_plan_snapshot(plan_path)
    std.io.print_line("[v1-debug] plan parsed, output_dir=" + plan.output_dir)
    if plan.output_dir.length() == 0 {
        return CompileResult {
            ok: false,
            error: "无法读取 compile-plan.txt：" + plan_path,
            output: empty_compile_output()
        }
    }
    if target_uses_wasm_node_backend(plan.canonical_target) {
        return compile_wasm_node_from_plan(plan_path)
    }
    let merged_files: [utf8] = ensure_project_sources(plan.source_files, plan.project_dir)
    let source_count_u: usize = merged_files.length()
    let source_count: i32 = source_count_u as i32
    std.io.print_line("[v1-debug] source_count=" + format("{}", source_count))
    if source_count == 0 {
        return CompileResult {
            ok: false,
            error: "compile-plan 未包含源码文件",
            output: empty_compile_output()
        }
    }

    let probe: utf8 = merged_files⁅0⁆
    std.io.print_line("[v1-debug] first_file=" + probe)
    if std.io.file_exists(probe) {
        std.io.print_line("[v1-debug] first_file_exists=1")
    }
    else {
        std.io.print_line("[v1-debug] first_file_exists=0")
    }
    let underscore: utf8 = path_join(path_join(plan.project_dir, "source"), "_.v")
    std.io.print_line("[v1-debug] underscore_path=" + underscore)
    if std.io.file_exists(underscore) {
        let undersrc: utf8 = std.io.read_file_text(underscore)
        let under_len: i32 = undersrc.length()
        std.io.print_line("[v1-debug] underscore_len=" + format("{}", under_len))
        if undersrc.contains("micro legion") {
            std.io.print_line("[v1-debug] underscore_has_legion=1")
        }
        else {
            std.io.print_line("[v1-debug] underscore_has_legion=0")
        }
    }
    else {
        std.io.print_line("[v1-debug] underscore_missing=1")
    }
    std.io.print_line("[v1-debug] before build_fragment_from_files")
    let mut submission: FragmentSubmission = build_fragment_from_files(merged_files, source_count_u, plan.project_name)
    std.io.print_line("[v1-debug] after build_fragment_from_files")
    let export_count: i32 = submission.exported_operations.length() as i32
    std.io.print_line("[v1-debug] export_count=" + format("{}", export_count))
    # Keep length in a dedicated local — CLR SSA home reuse has overwritten
    # `plan_path` (arg local) with `get_Length` results (InvalidProgram).
    let mut entry: utf8 = submission.entry_operation
    let mut entry_len: i32 = entry.length()
    std.io.print_line("[v1-debug] entry_len=" + format("{}", entry_len))
    if entry_len > 0 {
        std.io.print_line("[v1-debug] entry=" + entry)
    }
    # Prefer `legion` when scan landed on sibling mains (voa/vcc); never rewrite smoke `main`.
    if entry == "voa" || entry == "vcc" || entry.ends_with(".voa") || entry.ends_with(".vcc") {
        submission.entry_operation = "legion"
        entry = submission.entry_operation
        entry_len = entry.length()
        std.io.print_line("[v1-debug] entry forced to legion from sibling main")
    }
    if entry_len == 0 {
        return CompileResult {
            ok: false,
            error: "未找到 [main] 入口函数",
            output: empty_compile_output()
        }
    }
    let blockers: [utf8] = collect_body_emit_blockers(submission)
    if blockers.length() > 0 {
        let mut detail: utf8 = "fail-closed: body→MSIL 无法如实 emit"
        if entry_is_legion(entry) {
            detail = detail + "（legion.tools 自举仍缺完整 MIR 覆盖）"
        }
        let mut bi: usize = 0
        let bn: usize = blockers.length()
        let mut show: usize = bn
        if show > 24 {
            show = 24
        }
        while bi < show {
            detail = detail + " | " + blockers⁅bi⁆
            bi = bi + 1
        }
        if bn > show {
            detail = detail + " | …共 " + format("{}", bn as i32) + " 项"
        }
        return CompileResult {
            ok: false,
            error: detail,
            output: empty_compile_output()
        }
    }
    let edge_count: i32 = submission.external_call_edges.length() as i32
    std.io.print_line("[v1-debug] edge_count=" + format("{}", edge_count))

    let mut lowered: LoweredClrModule = LoweredClrModule {
        assembly_name: "",
        msil: "",
        console_message: ""
    }
    if fragment_supports_executable_module_emit(submission) {
        std.io.print_line("[v1-debug] before ExecutableModule emit")
        lowered = lower_fragment_via_executable_module(submission)
        if lowered.msil.length() > 0 {
            std.io.print_line("[v1-debug] after ExecutableModule emit")
        }
        else {
            std.io.print_line("[v1-debug] ExecutableModule emit empty; legacy body→MSIL bypass")
            std.io.print_line("[v1-debug] before lower_fragment_to_clr")
            lowered = lower_fragment_to_clr(submission)
            std.io.print_line("[v1-debug] after lower_fragment_to_clr")
        }
    }
    else {
        std.io.print_line("[v1-debug] before lower_fragment_to_clr")
        lowered = lower_fragment_to_clr(submission)
        std.io.print_line("[v1-debug] after lower_fragment_to_clr")
    }
    let emit_error: utf8 = emit_clr_artifacts(plan, lowered)
    std.io.print_line("[v1-debug] after emit_clr_artifacts")
    if emit_error.length() > 0 {
        return CompileResult {
            ok: false,
            error: emit_error,
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
