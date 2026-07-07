namespace legion;

using nyar.language.valkyrie;
using std.io;

micro emitter_compile_project(project_dir: utf8, target: utf8, output: utf8, verbose: bool) -> i32 {
    let plan_path: utf8 = output + "/compile-plan.txt"
    if !std.io.file_exists(plan_path) {
        std.io.error("错误：找不到 compile-plan.txt，无法执行 emitter 编译")
        if verbose {
            std.io.print_line("  期望路径：" + plan_path)
        }
        return 1
    }

    let dependency_count: i32 = count_dependency_names(plan_path)
    let result: CompileResult = compile_project_from_plan(plan_path, dependency_count)
    if !result.ok {
        if verbose {
            std.io.print_line("emitter 编译失败：" + result.error)
            std.io.print_line("  项目：" + project_dir)
            std.io.print_line("  目标：" + target)
            std.io.print_line("  输出：" + output)
        }
        std.io.error("错误：" + result.error)
        return 1
    }

    if verbose {
        std.io.print_line("emitter 编译完成")
        std.io.print_line("  程序集：" + result.output.assembly_name)
        std.io.print_line("  消息：" + result.output.console_message)
    }
    return 0
}
