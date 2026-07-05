namespace legion;

using std.data.text.von;
using std.io;
using std.math.graph_theory;

[clr("mscorlib", "System.Console", "WriteLine")]
micro bootstrap_console_write_line(message: utf8): unit

structure BuildRequest {
    project: utf8
    target: utf8
    output: utf8
    verbose: bool
}

structure PublishSelection {
    found: bool
    target: LegionPublishTarget
}

micro version_text() -> utf8 {
    return "Legion 构建工具 v0.1.0"
}

micro empty_publish_target() -> LegionPublishTarget {
    return LegionPublishTarget {
        target: "",
        format_type: "",
        package_id: "",
        version: ""
    }
}

micro normalize_path(path: utf8) -> utf8 {
    return path.replace("\u{5c}", "/")
}

micro path_join(base: utf8, child: utf8) -> utf8 {
    let left: utf8 = normalize_path(base)
    let right: utf8 = normalize_path(child)
    if left.length() == 0 {
        return right
    }
    if right.length() == 0 {
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
    if project.trim().length() == 0 {
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
    while i < args.length() {
        let arg: utf8 = args[i]
        if arg == "-t" || arg == "--target" {
            if i + 1 < args.length() {
                request.target = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--target=") {
            request.target = arg.slice(9, arg.length())
            i = i + 1
            continue
        }
        if arg == "-o" || arg == "--output" {
            if i + 1 < args.length() {
                request.output = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--output=") {
            request.output = arg.slice(9, arg.length())
            i = i + 1
            continue
        }
        if arg == "-v" || arg == "--verbose" {
            request.verbose = true
            i = i + 1
            continue
        }
        if !arg.starts_with("-") && request.project.length() == 0 {
            request.project = arg
        }
        i = i + 1
    }

    return request
}

micro select_publish_target(manifest: LegionProjectManifest, requested_target: utf8, publish_type: utf8) -> PublishSelection {
    let mut selected: Option<LegionPublishTarget> = None
    let mut i: usize = 0
    while i < manifest.publish_targets.length() {
        let target: LegionPublishTarget = manifest.publish_targets[i]
        if target.format_type == publish_type {
            if requested_target.length() == 0 || target.target == requested_target {
                selected = Some(target)
                break
            }
        }
        i = i + 1
    }

    if selected.is_some() {
        return PublishSelection {
            found: true,
            target: selected.unwrap()
        }
    }

    return PublishSelection {
        found: false,
        target: empty_publish_target()
    }
}

micro default_package_output_dir(project_dir: utf8) -> utf8 {
    return path_join(path_join(project_dir, "dist"), "nuget")
}

micro collect_tail_args(args: [utf8], start_index: usize) -> [utf8] {
    return args
        .into_iterator()
        .skip(start_index)
        .collect_array()
}

micro print_root_help() -> unit {
    std.io.print_line("Legion 构建工具")
    std.io.print_line("")
    std.io.print_line("用法：")
    std.io.print_line("  legion build [project] [--target <target>] [--output <dir>] [--verbose]")
    std.io.print_line("  legion check [project] [--target <target>] [--verbose]")
    std.io.print_line("  legion publish [project] [--registry <name>] [--dry-run] [--bump <kind>]")
    std.io.print_line("  legion publish [project] [--target <target>] [--output <dir>]   # nuget 产物信道")
    std.io.print_line("  legion install [package] [--version <ver>] [--registry <name>] [--frozen-lockfile]")
    std.io.print_line("  legion add|remove|update <package>")
    std.io.print_line("  legion search|info <query>")
    std.io.print_line("  legion vendor login|logout|list|whoami")
    std.io.print_line("  legion --help")
    std.io.print_line("  legion --version")
}

micro execute_pack(args: [utf8]) -> unit {
    let request: BuildRequest = parse_build_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let workspace_manifest: utf8 = path_join(project_dir, "legions.von")
    let project_manifest: utf8 = path_join(project_dir, "legion.von")

    if std.io.file_exists(workspace_manifest) && !std.io.file_exists(project_manifest) {
        std.io.error("错误：暂未支持直接对 workspace 执行 pack，请指定具体项目目录")
        return
    }

    if !std.io.file_exists(project_manifest) {
        std.io.error("错误：找不到 legion.von，无法执行 pack")
        return
    }

    let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(project_dir)
    let manifest_result: VonParseResult<LegionProjectManifest> = legion_read_project_manifest(project_manifest, auto_link.core, auto_link.std, auto_link.has_default)
    let manifest_failure: VonDiagnostic? = von_parse_take_fail(manifest_result)
    if manifest_failure.is_some() {
        std.io.error("错误：解析 legion.von 失败 - " + manifest_failure.unwrap().message)
        return
    }
    let manifest: LegionProjectManifest = von_parse_take_fine(manifest_result).unwrap()
    let requested_target: utf8 = if request.target.length() > 0 { request.target } else { "clr" }
    let selected: PublishSelection = select_publish_target(manifest, requested_target, "nuget")
    if !selected.found {
        std.io.error("错误：未找到匹配的 nuget 发布目标，target = " + requested_target)
        return
    }

    let publish_target: LegionPublishTarget = selected.target
    let package_version: utf8 = publish_target.version.trim()
    if package_version.length() == 0 || package_version == "workspace" {
        std.io.error("错误：发布版本无效，请在 legion.von 顶层 version 或 publish.version 中提供具体版本号")
        return
    }

    let package_id: utf8 = publish_target.package_id.trim()
    if package_id.length() == 0 {
        std.io.error("错误：publish.package_id 不能为空")
        return
    }

    let output_dir: utf8 = if request.output.trim().length() > 0 { request.output.trim() } else { default_package_output_dir(project_dir) }

    <% match arch %>
        <% case "clr" %>
        std.io.error("错误：NuGet 打包尚未在 CLR 自举产物中实现")
        return
        <% else %>
        std.io.error("错误：当前宿主暂不支持 nuget 打包，请使用 CLR 目标 legion")
        <% end match %>
}

micro args_has_flag(args: [utf8], flag: utf8) -> bool {
    let mut i: usize = 0
    while i < args.length() {
        let arg: utf8 = args[i]
        if arg == flag || arg.starts_with(flag + "=") {
            return true
        }
        i = i + 1
    }
    return false
}

micro execute_publish(args: [utf8]) -> unit {
    if args_has_flag(args, "--registry") || args_has_flag(args, "--dry-run") || args_has_flag(args, "--bump") {
        std.io.print_line("publish：注册表发布")
        execute_registry_publish(args)
        return
    }
    std.io.print_line("publish：执行 build(验证) -> pack（产物信道）")
    execute_pack(args)
}

# 尝试从项目目录向上查找 workspace legions.von，返回 workspace 级 auto_link 默认值
micro try_load_workspace_auto_link(project_dir: utf8) -> WorkspaceAutoLinkResult {
    let workspace_path: utf8 = find_workspace_manifest_path(project_dir)
    if workspace_path.length() == 0 {
        return WorkspaceAutoLinkResult { core: false, std: false, has_default: false }
    }
    let parsed: VonParseResult<VonValue> = legion_read_von_document(workspace_path)
    let failure: VonDiagnostic? = von_parse_take_fail(parsed)
    if failure.is_some() {
        return WorkspaceAutoLinkResult { core: false, std: false, has_default: false }
    }
    let document: VonValue = von_parse_take_fine(parsed).unwrap()
    return legion_parse_workspace_auto_link(document)
}

micro emit_single_project_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let manifest_path: utf8 = path_join(project_dir, "legion.von")
    let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(project_dir)
    let manifest_result: VonParseResult<LegionProjectManifest> = legion_read_project_manifest(manifest_path, auto_link.core, auto_link.std, auto_link.has_default)
    let manifest_failure: VonDiagnostic? = von_parse_take_fail(manifest_result)
    if manifest_failure.is_some() {
        std.io.error("错误：解析 legion.von 失败 - " + manifest_failure.unwrap().message)
        return
    }
    let manifest: LegionProjectManifest = von_parse_take_fine(manifest_result).unwrap()
    let request: BuildRequest = BuildRequest {
        project: project_dir,
        target: requested_target,
        output: output,
        verbose: verbose
    }

    let contexts_result: VonParseResult<[LegionBuildContext]> = legion_build_contexts(project_dir, manifest_path, manifest, request)
    let contexts_failure: VonDiagnostic? = von_parse_take_fail(contexts_result)
    if contexts_failure.is_some() {
        std.io.error("错误：生成构建上下文失败 - " + contexts_failure.unwrap().message)
        return
    }
    let contexts: [LegionBuildContext] = von_parse_take_fine(contexts_result).unwrap()
    loop context in contexts {
        std.io.print_line("正在构建 " + context.project_dir + " -> " + context.canonical_target + "...")
        if context.verbose {
            std.io.print_line("  清单：" + context.manifest_path)
            std.io.print_line("  包名：" + context.project_name)
            std.io.print_line("  输出：" + context.output_dir)
            std.io.print_line("  后端家族：" + context.backend_family)
            std.io.print_line("  宿主标签：" + context.arch_tag)
            std.io.print_line("  ABI：" + context.abi)
            std.io.print_line("  测试源码：" + if context.include_test_sources { "启用" } else { "关闭" })
            if context.preferred_logical_entry.length() > 0 {
                std.io.print_line("  优先入口：" + context.preferred_logical_entry)
            }
            if context.build_options.source_map || context.build_options.type_script || context.build_options.wat || context.build_options.msil {
                std.io.print_line("  构建选项："
                    + " source_map=" + if context.build_options.source_map { "true" } else { "false" }
                    + ", type_script=" + if context.build_options.type_script { "true" } else { "false" }
                    + ", wat=" + if context.build_options.wat { "true" } else { "false" }
                    + ", msil=" + if context.build_options.msil { "true" } else { "false" })
            }
            if context.dependency_names.length() > 0 {
                std.io.print_line("  直接依赖：" + context.dependency_names.length() + " 个")
            }
            if context.dependency_order.length() > 0 {
                std.io.print_line("  编译拓扑序：" + context.dependency_order.length() + " 个包")
                loop dependency_name in context.dependency_order {
                    std.io.print_line("    " + dependency_name)
                }
            }
        }

        let plan_result: VonParseResult<LegionCompilePlan> = build_compile_plan(context, manifest)
        let plan_failure: VonDiagnostic? = von_parse_take_fail(plan_result)
        if plan_failure.is_some() {
            std.io.error("错误：生成编译计划失败 - " + plan_failure.unwrap().message)
            return
        }
        let compile_plan: LegionCompilePlan = von_parse_take_fine(plan_result).unwrap()
        let execution_request: LegionBackendExecutionRequest = build_backend_execution_request(compile_plan, verbose)
        std.io.create_directory(compile_plan.output_dir)
        if !write_compile_plan_snapshot(compile_plan) {
            std.io.error("错误：写入编译计划快照失败 - " + compile_plan.output_dir)
            return
        }
        if !write_backend_execution_request_snapshot(execution_request) {
            std.io.error("错误：写入后端执行请求快照失败 - " + execution_request.output_dir)
            return
        }
        let execution_result: LegionBackendExecutionResult = execute_backend_request(execution_request)
        if !write_backend_execution_result_snapshot(execution_request.output_dir, execution_result) {
            std.io.error("错误：写入后端执行结果快照失败 - " + execution_request.output_dir)
            return
        }
        std.io.print_line("  源码闭包：" + compile_plan.source_closure.package_names.length() + " 个包，" + compile_plan.source_closure.files.length() + " 个文件")
        if context.verbose {
            loop package_name in compile_plan.source_closure.package_names {
                std.io.print_line("    包：" + package_name)
            }
            std.io.print_line("  计划目标：" + compile_plan.canonical_target)
            std.io.print_line("  计划输出：" + compile_plan.output_dir)
            std.io.print_line("  执行模式：" + execution_request.executor_mode)
            std.io.print_line("  计划快照：" + compile_plan_snapshot_path(compile_plan.output_dir))
            std.io.print_line("  后端请求：" + backend_execution_snapshot_path(execution_request.output_dir))
            std.io.print_line("  执行结果：" + backend_execution_result_snapshot_path(execution_request.output_dir))
            std.io.print_line("  执行器：" + execution_result.executor_kind)
        }

        if !execution_result.success {
            std.io.error("错误：" + execution_result.error)
            return
        }
    }
}

micro emit_workspace_member(member_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let nested_manifest: utf8 = path_join(member_dir, "legions.von")
    if std.io.file_exists(nested_manifest) {
        emit_workspace_build(member_dir, requested_target, output, verbose)
        return
    }

    let project_manifest: utf8 = path_join(member_dir, "legion.von")
    if std.io.file_exists(project_manifest) {
        emit_single_project_build(member_dir, requested_target, output, verbose)
    }
}

micro emit_workspace_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let manifest_path: utf8 = find_workspace_manifest_path(project_dir)
    if manifest_path.length() == 0 {
        std.io.error("错误：找不到 legions.von，无法执行 workspace 构建")
        return
    }

    let workspace_dir: utf8 = workspace_root_dir(manifest_path)
    let workspace_result: VonParseResult<LegionWorkspaceManifest> = legion_read_workspace_manifest(manifest_path)
    let workspace_failure: VonDiagnostic? = von_parse_take_fail(workspace_result)
    if workspace_failure.is_some() {
        std.io.error("错误：解析 legions.von 失败 - " + workspace_failure.unwrap().message)
        return
    }
    let manifest: LegionWorkspaceManifest = von_parse_take_fine(workspace_result).unwrap()
    let members: [utf8] = manifest.members
    if members.length() == 0 {
        std.io.error("错误：legions.von 中无 members")
        return
    }

    std.io.print_line("发现 workspace `" + workspace_dir + "`，共 " + members.length() + " 个成员")
    loop member in members {
        let member_dir: utf8 = path_join(workspace_dir, member)
        emit_workspace_member(member_dir, requested_target, output, verbose)
    }
}

micro execute_build(args: [utf8]) -> unit {
    let request: BuildRequest = parse_build_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let workspace_manifest: utf8 = find_workspace_manifest_path(project_dir)
    let project_manifest: utf8 = path_join(project_dir, "legion.von")

    if workspace_manifest.length() > 0 {
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
    if args.length() == 0 {
        print_root_help()
        return
    }

    let cmd_name: utf8 = args[0]
    if cmd_name == "--version" || cmd_name == "-V" {
        bootstrap_console_write_line("Legion 构建工具 v0.1.0")
        return
    }

    if cmd_name == "--help" || cmd_name == "-h" {
        print_root_help()
        return
    }

    let cmd_args: [utf8] = collect_tail_args(args, 1)

    if cmd_name == "build" {
        execute_build(cmd_args)
        return
    }

    if cmd_name == "check" {
        execute_check(cmd_args)
        return
    }

    if cmd_name == "publish" {
        execute_publish(cmd_args)
        return
    }

    if cmd_name == "install" {
        execute_install(cmd_args)
        return
    }

    if cmd_name == "add" {
        execute_add(cmd_args)
        return
    }

    if cmd_name == "remove" {
        execute_remove(cmd_args)
        return
    }

    if cmd_name == "update" {
        execute_update(cmd_args)
        return
    }

    if cmd_name == "search" {
        execute_search(cmd_args)
        return
    }

    if cmd_name == "info" {
        execute_info(cmd_args)
        return
    }

    if cmd_name == "vendor" {
        execute_vendor(cmd_args)
        return
    }

    std.io.error("未知命令：" + cmd_name)
    print_root_help()
}


# valkyrie 特殊构建工具，暂时保持为空
[main]
micro vcc(args: [utf8]) -> unit {

}


# valkyrie of asgard 框架构建工具，暂时保持为空
[main]
micro voa(args: [utf8]) -> unit {

}
