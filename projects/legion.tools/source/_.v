namespace legion;

using std.data.text.von;
using std.io;
using std.math.graph_theory;

[clr("LoL.Legion.HostBridge", "Legion.Bootstrap.HostBridge", "BuildProject")]
micro clr_host_build_project(project_dir: utf8, target: utf8, output: utf8, verbose: bool) -> i32

[clr("LoL.Legion.HostBridge", "Legion.Bootstrap.HostBridge", "PackProject")]
micro clr_host_pack_project(project_dir: utf8, target: utf8, output: utf8, package_id: utf8, version: utf8, verbose: bool) -> utf8

# NyarVM 宿主委托：通过 [vm] 属性绑定到运行时注册的 host.build_project intrinsic
[vm("host.build_project")]
micro nyar_host_build_project(project_dir: utf8, target: utf8, output: utf8) -> bool

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

structure LegionSourceClosurePlan {
    package_names: [utf8]
    package_dirs: [utf8]
    files: [utf8]
}

micro version_text() -> utf8 {
    return "Legion 构建工具 v0.1.0"
}

micro empty_publish_target() -> LegionPublishTarget {
    return LegionPublishTarget {
        target: "",
        type: "",
        package_id: "",
        version: ""
    }
}

micro normalize_path(path: utf8) -> utf8 {
    return path.replace("\\", "/")
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

micro push_unique_text(mut items: [utf8], value: utf8) -> unit {
    if !items.contains(value) {
        push(items, value)
    }
}

micro parent_path(path: utf8) -> utf8 {
    let normalized: utf8 = normalize_path(path)
    let parts: [utf8] = normalized.split("/")
    let mut last_index: i32 = parts.length() as i32 - 1
    while last_index >= 0 {
        if parts[last_index as usize].length() > 0 {
            break
        }
        last_index = last_index - 1
    }

    if last_index <= 0 {
        return ""
    }

    let mut result: utf8 = ""
    let mut i: usize = 0
    while i < last_index as usize {
        let part: utf8 = parts[i]
        if part.length() > 0 {
            if result.length() == 0 {
                result = part
            }
            else {
                result = path_join(result, part)
            }
        }
        i = i + 1
    }
    return result
}

micro find_workspace_manifest_path(project_dir: utf8) -> utf8 {
    let mut current: utf8 = normalize_path(project_dir)
    while current.length() > 0 {
        let candidate: utf8 = path_join(current, "legions.von")
        if std.io.file_exists(candidate) {
            return candidate
        }

        let parent: utf8 = parent_path(current)
        if parent.length() == 0 || parent == current {
            return ""
        }
        current = parent
    }
    return ""
}

micro workspace_root_dir(workspace_manifest_path: utf8) -> utf8 {
    return parent_path(workspace_manifest_path)
}

micro collect_directory_files(directory: utf8, pattern: utf8) -> [utf8] {
    if !std.io.directory_exists(directory) {
        return []
    }
    return std.io.get_files(directory, pattern, true)
}

micro collect_project_source_files(project_dir: utf8, include_test_sources: bool) -> [utf8] {
    let mut result: [utf8] = []

    let source_dir: utf8 = path_join(project_dir, "source")
    loop file in collect_directory_files(source_dir, "*.v") {
        push_unique_text(result, normalize_path(file))
    }
    loop file in collect_directory_files(source_dir, "*.ggs") {
        push_unique_text(result, normalize_path(file))
    }

    let script_dir: utf8 = path_join(project_dir, "script")
    loop file in collect_directory_files(script_dir, "*.v") {
        push_unique_text(result, normalize_path(file))
    }
    loop file in collect_directory_files(script_dir, "*.ggs") {
        push_unique_text(result, normalize_path(file))
    }

    if include_test_sources {
        let test_dir: utf8 = path_join(project_dir, "test")
        loop file in collect_directory_files(test_dir, "*.v") {
            push_unique_text(result, normalize_path(file))
        }
        loop file in collect_directory_files(test_dir, "*.ggs") {
            push_unique_text(result, normalize_path(file))
        }
    }

    return result
}

micro empty_source_closure_plan() -> LegionSourceClosurePlan {
    return LegionSourceClosurePlan {
        package_names: [],
        package_dirs: [],
        files: []
    }
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

micro try_load_workspace_auto_link(project_dir: utf8) -> WorkspaceAutoLinkResult {
    let workspace_path: utf8 = find_workspace_manifest_path(project_dir)
    if workspace_path.length() == 0 {
        return WorkspaceAutoLinkResult { core: false, std: false, has_default: false }
    }
    match legion_read_von_document(workspace_path) {
        case Fine(document):
            return legion_parse_workspace_auto_link(document)
        case Fail(error):
            return WorkspaceAutoLinkResult { core: false, std: false, has_default: false }
    }
}

micro resolve_workspace_member_dir(project_dir: utf8, dependency_name: utf8) -> utf8 {
    let workspace_manifest_path: utf8 = find_workspace_manifest_path(project_dir)
    if workspace_manifest_path.length() == 0 {
        return ""
    }

    let workspace_dir: utf8 = workspace_root_dir(workspace_manifest_path)
    match legion_read_workspace_manifest(workspace_manifest_path) {
        case Fine(workspace_manifest):
            loop member in workspace_manifest.members {
                let member_dir: utf8 = path_join(workspace_dir, member)
                let member_manifest_path: utf8 = path_join(member_dir, "legion.von")
                if !std.io.file_exists(member_manifest_path) {
                    continue
                }

                let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(member_dir)
                match legion_read_project_manifest(member_manifest_path, auto_link.core, auto_link.std, auto_link.has_default) {
                    case Fine(member_manifest):
                        let member_name: utf8 = legion_project_name(member_dir, member_manifest)
                        if member_name == dependency_name {
                            return member_dir
                        }
                    case Fail(error):
                }
            }
        case Fail(error):
    }
    return ""
}

micro collect_source_closure_recursive(
    project_dir: utf8,
    manifest: LegionProjectManifest,
    include_test_sources: bool,
    mut visited_package_names: [utf8],
    mut package_names: [utf8],
    mut package_dirs: [utf8],
    mut files: [utf8])
    -> VonParseResult<bool> {
    let project_name: utf8 = legion_project_name(project_dir, manifest)
    if visited_package_names.contains(project_name) {
        return Fine(true)
    }

    push(visited_package_names, project_name)
    push_unique_text(package_names, project_name)
    push_unique_text(package_dirs, normalize_path(project_dir))

    let project_files: [utf8] = collect_project_source_files(project_dir, include_test_sources)
    loop file in project_files {
        push_unique_text(files, file)
    }

    let dependency_names: [utf8] = legion_dependency_names(manifest, project_name)
    loop dependency_name in dependency_names {
        let dependency_dir: utf8 = resolve_workspace_member_dir(project_dir, dependency_name)
        if dependency_dir.length() == 0 {
            return Fail(new_von_diagnostic("未找到依赖包目录：" + dependency_name, 0, 0))
        }

        let dependency_manifest_path: utf8 = path_join(dependency_dir, "legion.von")
        let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(dependency_dir)
        match legion_read_project_manifest(dependency_manifest_path, auto_link.core, auto_link.std, auto_link.has_default) {
            case Fine(dependency_manifest):
                match collect_source_closure_recursive(
                    dependency_dir,
                    dependency_manifest,
                    include_test_sources,
                    visited_package_names,
                    package_names,
                    package_dirs,
                    files) {
                    case Fine(done):
                    case Fail(error):
                        return Fail(error)
                }
            case Fail(error):
                return Fail(error)
        }
    }

    return Fine(true)
}

micro collect_source_closure(context: LegionBuildContext, manifest: LegionProjectManifest) -> VonParseResult<LegionSourceClosurePlan> {
    let mut visited_package_names: [utf8] = []
    let mut package_names: [utf8] = []
    let mut package_dirs: [utf8] = []
    let mut files: [utf8] = []

    match collect_source_closure_recursive(
        context.project_dir,
        manifest,
        context.include_test_sources,
        visited_package_names,
        package_names,
        package_dirs,
        files) {
        case Fine(done):
            return Fine(LegionSourceClosurePlan {
                package_names: package_names,
                package_dirs: package_dirs,
                files: files
            })
        case Fail(error):
            return Fail(error)
    }
}

micro delegate_host_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    <% match arch %>
        <% case "clr" %>
        let exit_code: i32 = clr_host_build_project(project_dir, requested_target, output, verbose)
        if exit_code != 0 {
            std.io.error("错误：宿主构建器执行失败，退出码 = " + format("{}", exit_code))
        }
        <% case "nyar" %>
        let success: bool = nyar_host_build_project(project_dir, requested_target, output)
        if !success {
            std.io.error("错误：NyarVM 宿主构建器执行失败")
        }
        <% else %>
        std.io.print_line("  当前宿主尚未接入源码编译执行器，暂不继续下探真实编译阶段。")
        <% end match %>
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
    loop target in manifest.publish_targets {
        if target.type == publish_type {
            if requested_target.length() == 0 || target.target == requested_target {
                return PublishSelection {
                    found: true,
                    target: target
                }
            }
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
    std.io.print_line("  legion publish [project] [--target <target>] [--output <dir>] [--verbose]")
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
    match legion_read_project_manifest(project_manifest, auto_link.core, auto_link.std, auto_link.has_default) {
        case Fine(manifest):
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
                let package_path: utf8 = clr_host_pack_project(project_dir, publish_target.target, output_dir, package_id, package_version, request.verbose)
                if package_path.length() == 0 {
                    std.io.error("错误：NuGet 打包失败")
                    return
                }
                std.io.print_line("NuGet 包已生成：" + package_path)
                <% else %>
                std.io.error("错误：当前宿主暂不支持 nuget 打包，请使用 CLR 目标 legion")
                <% end match %>
        case Fail(error):
            std.io.error("错误：解析 legion.von 失败 - " + error.message)
            return
    }
}

micro execute_publish(args: [utf8]) -> unit {
    std.io.print_line("publish：执行 build(验证) -> pack")
    execute_pack(args)
}

# 尝试从项目目录向上查找 workspace legions.von，返回 workspace 级 auto_link 默认值
micro emit_single_project_build(project_dir: utf8, requested_target: utf8, output: utf8, verbose: bool) -> unit {
    let manifest_path: utf8 = path_join(project_dir, "legion.von")
    let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(project_dir)
    match legion_read_project_manifest(manifest_path, auto_link.core, auto_link.std, auto_link.has_default) {
        case Fine(manifest):
            let request: BuildRequest = BuildRequest {
                project: project_dir,
                target: requested_target,
                output: output,
                verbose: verbose
            }

            match legion_build_contexts(project_dir, manifest_path, manifest, request) {
                case Fine(contexts):
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

                            # 依赖图诊断
                            let dep_graph: DirectedGraph = directed_graph_new()
                            # 添加项目自身
                            directed_graph_add_node(dep_graph, context.project_name)
                            loop dependency_name in context.dependency_names {
                                directed_graph_add_edge(dep_graph, context.project_name, dependency_name)
                            }
                            if has_cycle(dep_graph) {
                                std.io.print_line("  警告：依赖图中存在循环！")
                            }
                        }

                        match collect_source_closure(context, manifest) {
                            case Fine(source_closure):
                                if source_closure.files.length() == 0 {
                                    std.io.error("错误：未找到可编译的 Valkyrie 源文件，请检查 source/、script/、test/ 目录以及依赖包。")
                                    return
                                }

                                std.io.create_directory(context.output_dir)
                                std.io.print_line("  源码闭包：" + source_closure.package_names.length() + " 个包，" + source_closure.files.length() + " 个文件")
                                if context.verbose {
                                    loop package_name in source_closure.package_names {
                                        std.io.print_line("    包：" + package_name)
                                    }
                                }

                                delegate_host_build(project_dir, requested_target, output, verbose)
                            case Fail(error):
                                std.io.error("错误：生成源码闭包失败 - " + error.message)
                                return
                        }
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
            if members.length() == 0 {
                std.io.error("错误：legions.von 中无 members")
                return
            }

            std.io.print_line("发现 workspace，共 " + members.length() + " 个成员项目")
            loop member in members {
                let member_dir: utf8 = path_join(project_dir, member)
                emit_single_project_build(member_dir, requested_target, output, verbose)
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
    if args.length() == 0 {
        print_root_help()
        return
    }

    let cmd_name: utf8 = args[0]
    if cmd_name == "--version" || cmd_name == "-V" {
        std.io.print_line(version_text())
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

    if cmd_name == "publish" {
        execute_publish(cmd_args)
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
