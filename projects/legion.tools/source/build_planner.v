namespace legion;

using std.io;

structure LegionSourceClosurePlan {
    package_names: [utf8]
    package_dirs: [utf8]
    files: [utf8]
}

structure LegionCompilePlan {
    project_dir: utf8
    manifest_path: utf8
    project_name: utf8
    canonical_target: utf8
    output_dir: utf8
    dependency_names: [utf8]
    dependency_order: [utf8]
    arch_tag: utf8
    abi: utf8
    backend_family: utf8
    preferred_logical_entry: utf8
    include_test_sources: bool
    build_options: LegionBuildTargetOptions
    source_closure: LegionSourceClosurePlan
}

structure LegionBackendExecutionRequest {
    project_dir: utf8
    manifest_path: utf8
    project_name: utf8
    canonical_target: utf8
    output_dir: utf8
    dependency_names: [utf8]
    dependency_order: [utf8]
    arch_tag: utf8
    abi: utf8
    backend_family: utf8
    preferred_logical_entry: utf8
    include_test_sources: bool
    build_options: LegionBuildTargetOptions
    package_count: usize
    file_count: usize
    executor_mode: utf8
    verbose: bool
}

structure LegionBackendExecutionResult {
    executor_kind: utf8
    success: bool
    error: utf8
}

micro push_unique_text(mut items: [utf8], value: utf8) -> unit {
    if !items.contains(value) {
        push(items, value)
    }
}

micro compare_utf8_text(left: utf8, right: utf8) -> i32 {
    if left.equals(right) {
        return 0
    }

    let mut left_chars = left.chars()
    let mut right_chars = right.chars()
    while left_chars.has_next() && right_chars.has_next() {
        let left_char: char = left_chars.next().unwrap()
        let right_char: char = right_chars.next().unwrap()
        if left_char < right_char {
            return -1
        }
        if left_char > right_char {
            return 1
        }
    }

    if left_chars.has_next() {
        return 1
    }
    if right_chars.has_next() {
        return -1
    }
    return 0
}

micro sort_texts(mut values: [utf8]) -> unit {
    let mut i: usize = 1
    while i < values.length() {
        let current: utf8 = values[i]
        let mut j: usize = i
        while j > 0 && compare_utf8_text(values[j - 1], current) > 0 {
            values[j] = values[j - 1]
            j = j - 1
        }
        values[j] = current
        i = i + 1
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

micro append_unique_normalized_files(mut result: [utf8], directory: utf8, pattern: utf8) -> unit {
    collect_directory_files(directory, pattern)
        .into_iterator()
        .map(micro(file: utf8) -> utf8 {
            return normalize_path(file)
        })
        .for_each(micro(file: utf8) -> unit {
            push_unique_text(result, file)
        })
}

micro collect_project_source_files(project_dir: utf8, include_test_sources: bool) -> [utf8] {
    let mut result: [utf8] = []

    let source_dir: utf8 = path_join(project_dir, "source")
    append_unique_normalized_files(result, source_dir, "*.v")
    append_unique_normalized_files(result, source_dir, "*.ggs")

    let script_dir: utf8 = path_join(project_dir, "script")
    append_unique_normalized_files(result, script_dir, "*.v")
    append_unique_normalized_files(result, script_dir, "*.ggs")

    if include_test_sources {
        let test_dir: utf8 = path_join(project_dir, "test")
        append_unique_normalized_files(result, test_dir, "*.v")
        append_unique_normalized_files(result, test_dir, "*.ggs")
    }

    sort_texts(result)
    return result
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
    mut files: [utf8]
)
    -> VonParseResult<bool> 
{
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
            sort_texts(package_names)
            sort_texts(package_dirs)
            sort_texts(files)
            return Fine(LegionSourceClosurePlan {
                package_names: package_names,
                package_dirs: package_dirs,
                files: files
            })
        case Fail(error):
            return Fail(error)
    }
}

micro build_compile_plan(context: LegionBuildContext, manifest: LegionProjectManifest) -> VonParseResult<LegionCompilePlan> {
    match collect_source_closure(context, manifest) {
        case Fine(source_closure):
            if source_closure.files.length() == 0 {
                return Fail(new_von_diagnostic("未找到可编译的 Valkyrie 源文件，请检查 source/、script/、test/ 目录以及依赖包。", 0, 0))
            }

            return Fine(LegionCompilePlan {
                project_dir: context.project_dir,
                manifest_path: context.manifest_path,
                project_name: context.project_name,
                canonical_target: context.canonical_target,
                output_dir: context.output_dir,
                dependency_names: context.dependency_names,
                dependency_order: context.dependency_order,
                arch_tag: context.arch_tag,
                abi: context.abi,
                backend_family: context.backend_family,
                preferred_logical_entry: context.preferred_logical_entry,
                include_test_sources: context.include_test_sources,
                build_options: context.build_options,
                source_closure: source_closure
            })
        case Fail(error):
            return Fail(error)
    }
}

micro compile_plan_snapshot_path(output_dir: utf8) -> utf8 {
    return path_join(output_dir, "compile-plan.txt")
}

micro backend_execution_snapshot_path(output_dir: utf8) -> utf8 {
    return path_join(output_dir, "backend-request.txt")
}

micro backend_execution_result_snapshot_path(output_dir: utf8) -> utf8 {
    return path_join(output_dir, "backend-result.txt")
}

micro append_line(buffer: utf8, line: utf8) -> utf8 {
    return buffer + line + "\n"
}

micro append_prefixed_lines(buffer: utf8, title: utf8, values: [utf8]) -> utf8 {
    let mut result: utf8 = append_line(buffer, title + ": " + values.length() + " 项")
    values
        .into_iterator()
        .for_each(micro(value: utf8) -> unit {
            result = append_line(result, "  " + value)
        })

    return result
}

micro write_compile_plan_snapshot(plan: LegionCompilePlan) -> bool {
    let mut content: utf8 = ""
    content = append_line(content, "project_dir: " + plan.project_dir)
    content = append_line(content, "manifest_path: " + plan.manifest_path)
    content = append_line(content, "project_name: " + plan.project_name)
    content = append_line(content, "canonical_target: " + plan.canonical_target)
    content = append_line(content, "output_dir: " + plan.output_dir)
    content = append_line(content, "arch_tag: " + plan.arch_tag)
    content = append_line(content, "abi: " + plan.abi)
    content = append_line(content, "backend_family: " + plan.backend_family)
    content = append_line(content, "preferred_logical_entry: " + plan.preferred_logical_entry)
    content = append_line(content, "include_test_sources: " + if plan.include_test_sources { "true" } else { "false" })
    content = append_line(content, "build_options.source_map: " + if plan.build_options.source_map { "true" } else { "false" })
    content = append_line(content, "build_options.type_script: " + if plan.build_options.type_script { "true" } else { "false" })
    content = append_line(content, "build_options.wat: " + if plan.build_options.wat { "true" } else { "false" })
    content = append_line(content, "build_options.msil: " + if plan.build_options.msil { "true" } else { "false" })
    content = append_prefixed_lines(content, "dependency_names", plan.dependency_names)
    content = append_prefixed_lines(content, "dependency_order", plan.dependency_order)
    content = append_prefixed_lines(content, "package_names", plan.source_closure.package_names)
    content = append_prefixed_lines(content, "package_dirs", plan.source_closure.package_dirs)
    content = append_prefixed_lines(content, "files", plan.source_closure.files)
    return std.io.write_file_text(compile_plan_snapshot_path(plan.output_dir), content)
}

micro build_backend_execution_request(plan: LegionCompilePlan, verbose: bool) -> LegionBackendExecutionRequest {
    return LegionBackendExecutionRequest {
        project_dir: plan.project_dir,
        manifest_path: plan.manifest_path,
        project_name: plan.project_name,
        canonical_target: plan.canonical_target,
        output_dir: plan.output_dir,
        dependency_names: plan.dependency_names,
        dependency_order: plan.dependency_order,
        arch_tag: plan.arch_tag,
        abi: plan.abi,
        backend_family: plan.backend_family,
        preferred_logical_entry: plan.preferred_logical_entry,
        include_test_sources: plan.include_test_sources,
        build_options: plan.build_options,
        package_count: plan.source_closure.package_names.length(),
        file_count: plan.source_closure.files.length(),
        executor_mode: "source_compiler",
        verbose: verbose
    }
}

micro write_backend_execution_request_snapshot(request: LegionBackendExecutionRequest) -> bool {
    let mut content: utf8 = ""
    content = append_line(content, "project_dir: " + request.project_dir)
    content = append_line(content, "manifest_path: " + request.manifest_path)
    content = append_line(content, "project_name: " + request.project_name)
    content = append_line(content, "canonical_target: " + request.canonical_target)
    content = append_line(content, "output_dir: " + request.output_dir)
    content = append_line(content, "arch_tag: " + request.arch_tag)
    content = append_line(content, "abi: " + request.abi)
    content = append_line(content, "backend_family: " + request.backend_family)
    content = append_line(content, "preferred_logical_entry: " + request.preferred_logical_entry)
    content = append_line(content, "include_test_sources: " + if request.include_test_sources { "true" } else { "false" })
    content = append_line(content, "build_options.source_map: " + if request.build_options.source_map { "true" } else { "false" })
    content = append_line(content, "build_options.type_script: " + if request.build_options.type_script { "true" } else { "false" })
    content = append_line(content, "build_options.wat: " + if request.build_options.wat { "true" } else { "false" })
    content = append_line(content, "build_options.msil: " + if request.build_options.msil { "true" } else { "false" })
    content = append_prefixed_lines(content, "dependency_names", request.dependency_names)
    content = append_prefixed_lines(content, "dependency_order", request.dependency_order)
    content = append_line(content, "package_count: " + format("{}", request.package_count))
    content = append_line(content, "file_count: " + format("{}", request.file_count))
    content = append_line(content, "executor_mode: " + request.executor_mode)
    content = append_line(content, "verbose: " + if request.verbose { "true" } else { "false" })
    content = append_line(content, "compile_plan_snapshot: " + compile_plan_snapshot_path(request.output_dir))
    return std.io.write_file_text(backend_execution_snapshot_path(request.output_dir), content)
}

micro write_backend_execution_result_snapshot(output_dir: utf8, result: LegionBackendExecutionResult) -> bool {
    let mut content: utf8 = ""
    content = append_line(content, "executor_kind: " + result.executor_kind)
    content = append_line(content, "success: " + if result.success { "true" } else { "false" })
    content = append_line(content, "error: " + result.error)
    return std.io.write_file_text(backend_execution_result_snapshot_path(output_dir), content)
}

micro execute_backend_request(request: LegionBackendExecutionRequest) -> LegionBackendExecutionResult {
    if request.executor_mode == "source_compiler" {
        return LegionBackendExecutionResult {
            executor_kind: "source_compiler",
            success: false,
            error: "源码编译执行器尚未接入：当前已禁用 host_bridge，请直接补齐源码编译执行入口"
        }
    }

    return LegionBackendExecutionResult {
        executor_kind: "unsupported",
        success: false,
        error: "未知的后端执行模式：" + request.executor_mode
    }
}
