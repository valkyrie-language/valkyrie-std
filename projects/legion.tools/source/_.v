namespace legion;

using std.command;
using std.data.text.von;
using std.io;
using std.math.graph_theory;

structure BuildRequest {
    project: utf8
    target: utf8
    output: utf8
    verbose: bool
}

micro version_text() -> utf8 {
    return "Legion 构建工具 v0.1.0"
}

micro normalize_path(path: utf8) -> utf8 {
    return path.replace("\\", "/")
}

micro path_join(base: utf8, child: utf8) -> utf8 {
    let left: utf8 = normalize_path(base)
    let right: utf8 = normalize_path(child)
    if len(left) == 0 {
        return right
    }
    if len(right) == 0 {
        return left
    }
    if right.starts_with("/") || right.contains(":/") {
        return right
    }
    if left.ends_with("/") {
        return left + right
    }
    return left + "/" + right
}

micro resolve_project_dir(project: utf8) -> utf8 {
    if len(project.trim()) == 0 {
        return normalize_path(std.io.get_current_directory())
    }

    let normalized: utf8 = normalize_path(project.trim())
    if normalized.starts_with("/") || normalized.contains(":/") {
        return normalized
    }
    return path_join(std.io.get_current_directory(), normalized)
}

micro parse_build_request(args: [utf8]) -> BuildRequest {
    let mut request: BuildRequest = BuildRequest {
        project: "",
        target: "",
        output: "",
        verbose: false
    }

    let mut i: usize = 0
    while i < len(args) {
        let arg: utf8 = args[i]
        if arg == "-t" || arg == "--target" {
            if i + 1 < len(args) {
                request.target = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--target=") {
            request.target = arg.slice(9, len(arg))
            i = i + 1
            continue
        }
        if arg == "-o" || arg == "--output" {
            if i + 1 < len(args) {
                request.output = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--output=") {
            request.output = arg.slice(9, len(arg))
            i = i + 1
            continue
        }
        if arg == "-v" || arg == "--verbose" {
            request.verbose = true
            i = i + 1
            continue
        }
        if !arg.starts_with("-") && len(request.project) == 0 {
            request.project = arg
        }
        i = i + 1
    }

    return request
}

// 尝试从项目目录向上查找 workspace legions.von，返回 workspace 级 auto_link 默认值
micro try_load_workspace_auto_link(project_dir: utf8) -> (bool, bool, bool) {
    let workspace_path: utf8 = path_join(project_dir, "legions.von")
    if !std.io.file_exists(workspace_path) {
        // 向上查找
        let parent_workspace: utf8 = path_join(path_join(project_dir, ".."), "legions.von")
        if !std.io.file_exists(parent_workspace) {
            return (false, false, false)
        }
        workspace_path = parent_workspace
    }
    match legion_read_von_document(workspace_path) {
        case Fine(document):
            return legion_parse_workspace_auto_link(document)
        case Fail(error):
            return (false, false, false)
    }
}

micro emit_single_project_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let manifest_path: utf8 = path_join(project_dir, "legion.von")
    let (ws_auto_core, ws_auto_std, has_ws_default) = try_load_workspace_auto_link(project_dir)
    match legion_read_project_manifest(manifest_path, ws_auto_core, ws_auto_std, has_ws_default) {
        case Fine(manifest):
            let request: BuildRequest = BuildRequest {
                project: project_dir,
                target: requested_target,
                output: output,
                verbose: verbose
            }

            match legion_build_contexts(project_dir, manifest_path, manifest, request) {
                case Fine(contexts):
                    let mut i: usize = 0
                    while i < len(contexts) {
                        let context: LegionBuildContext = contexts[i]
                        std.io.print_line("正在构建 " + context.project_dir + " -> " + context.canonical_target + "...")
                        if context.verbose {
                            std.io.print_line("  清单：" + context.manifest_path)
                            std.io.print_line("  包名：" + context.project_name)
                            std.io.print_line("  输出：" + context.output_dir)
                            if len(context.dependency_names) > 0 {
                                std.io.print_line("  直接依赖：" + len(context.dependency_names) + " 个")
                            }
                            if len(context.dependency_order) > 0 {
                                std.io.print_line("  编译拓扑序：" + len(context.dependency_order) + " 个包")
                                let mut j: usize = 0
                                while j < len(context.dependency_order) {
                                    std.io.print_line("    " + context.dependency_order[j])
                                    j = j + 1
                                }
                            }

                            // 依赖图诊断
                            let dep_graph: DirectedGraph = directed_graph_new()
                            # 添加项目自身
                            directed_graph_add_node(dep_graph, context.project_name)
                            let mut k: usize = 0
                            while k < len(context.dependency_names) {
                                directed_graph_add_edge(dep_graph, context.project_name, context.dependency_names[k])
                                k = k + 1
                            }
                            if has_cycle(dep_graph) {
                                std.io.print_line("  警告：依赖图中存在循环！")
                            }
                        }
                        std.io.print_line("  已完成强类型清单解析与构建上下文生成。")
                        std.io.print_line("  下一阶段直接在该上下文上接入包图与真实编译执行器。")
                        i = i + 1
                    }
                case Fail(error):
                    std.io.error("错误：生成构建上下文失败 - " + error.message)
                    return
            }
        case Fail(error):
            std.io.error("错误：解析 legion.von 失败 - " + error.message)
            return
    }
}

micro emit_workspace_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let manifest_path: utf8 = path_join(project_dir, "legions.von")
    match legion_read_workspace_manifest(manifest_path) {
        case Fine(manifest):
            let members: [utf8] = manifest.members
            if len(members) == 0 {
                std.io.error("错误：legions.von 中无 members")
                return
            }

            std.io.print_line("发现 workspace，共 " + len(members) + " 个成员项目")
            let mut i: usize = 0
            while i < len(members) {
                let member_dir: utf8 = path_join(project_dir, members[i])
                emit_single_project_build(member_dir, requested_target, output, verbose)
                i = i + 1
            }
        case Fail(error):
            std.io.error("错误：解析 legions.von 失败 - " + error.message)
            return
    }
}

micro execute_build(args: [utf8]) -> unit {
    let request: BuildRequest = parse_build_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let workspace_manifest: utf8 = path_join(project_dir, "legions.von")
    let project_manifest: utf8 = path_join(project_dir, "legion.von")

    if std.io.file_exists(workspace_manifest) {
        emit_workspace_build(project_dir, request.target, request.output, request.verbose)
        return
    }

    if std.io.file_exists(project_manifest) {
        emit_single_project_build(project_dir, request.target, request.output, request.verbose)
        return
    }

    std.io.error("错误：找不到项目清单，请确认目录中存在 legion.von 或 legions.von")
}

[main]
micro legion(args: [utf8]) -> unit {
    let mut app: CommandApp = command_app_new("legion", "Legion 构建工具")

    let build_cmd: CommandModel = CommandModel {
        name: "build",
        description: "构建项目",
        arguments: [
            ArgumentDef { name: "project", description: "项目路径", required: false }
        ],
        options: [
            OptionDef { name: "target", short_name: "t", description: "编译目标", required: false, takes_value: true },
            OptionDef { name: "output", short_name: "o", description: "输出目录", required: false, takes_value: true },
            OptionDef { name: "verbose", short_name: "v", description: "详细输出", required: false, takes_value: false }
        ]
    }
    app = command_app_register(app, build_cmd)

    let test_cmd: CommandModel = CommandModel {
        name: "test",
        description: "运行测试",
        arguments: [
            ArgumentDef { name: "filter", description: "测试过滤器", required: false }
        ],
        options: []
    }
    app = command_app_register(app, test_cmd)

    let doc_cmd: CommandModel = CommandModel {
        name: "doc",
        description: "生成文档",
        arguments: [
            ArgumentDef { name: "project", description: "项目路径", required: false }
        ],
        options: []
    }
    app = command_app_register(app, doc_cmd)

    let bench_cmd: CommandModel = CommandModel {
        name: "bench",
        description: "运行基准测试",
        arguments: [
            ArgumentDef { name: "filter", description: "基准测试过滤器", required: false }
        ],
        options: []
    }
    app = command_app_register(app, bench_cmd)

    let result: ParsedCommand = command_app_run(app, args)
    let cmd_name: utf8 = result.command_name

    if cmd_name == "__version__" {
        std.io.print_line(version_text())
        return
    }

    if cmd_name == "__help__" || len(cmd_name) == 0 {
        std.io.print_line(generate_root_help(app.name, app.description, app.commands))
        return
    }

    if cmd_name == "build" {
        execute_build(result.positional)
        return
    }

    if cmd_name == "test" {
        std.io.print_line("test 子命令尚未接入。")
        return
    }

    if cmd_name == "doc" {
        std.io.print_line("doc 子命令尚未接入。")
        return
    }

    if cmd_name == "bench" {
        std.io.print_line("bench 子命令尚未接入。")
        return
    }

    std.io.error("未知命令：" + cmd_name)
}


// valkyrie 特殊构建工具，暂时保持为空
[main]
micro vcc(args: [utf8]) -> unit {

}


// valkyrie of asgard 框架构建工具，暂时保持为空
[main]
micro voa(args: [utf8]) -> unit {

}