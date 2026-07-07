namespace legion;

using std.io;

structure LegionSourceClosurePlan {
    package_names: [utf8]
    package_dirs: [utf8]
    files: [utf8]
}

structure SourceClosureState {
    visited_package_names: [utf8]
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

micro text_list_contains(items: [utf8], value: utf8) -> bool {
    # 0-based cursor → cardinal/offset subscript `⁅ ⁆` (not ordinal `[]`).
    let mut index: usize = 0
    while index < items.length() {
        if items⁅index⁆ == value {
            return true
        }
        index = index + 1
    }
    return false
}

micro push_unique_text(items: [utf8], value: utf8) -> [utf8] {
    # Avoid `items.contains` — CLR overload currently binds array `.contains` to Utf8Text_contains.
    if !text_list_contains(items, value) {
        return push(items, value)
    }
    return items
}

micro compare_utf8_text(left: utf8, right: utf8) -> i32 {
    if left.equals(right) {
        return 0
    }

    let left_len: i32 = left.length()
    let right_len: i32 = right.length()
    let min_len: i32 = if left_len < right_len { left_len } else { right_len }
    let mut index: i32 = 0
    while index < min_len {
        # `utf8.slice(start, count)` — second arg is count, not end (CLR → Substring).
        let left_ch: utf8 = left.slice(index, 1)
        let right_ch: utf8 = right.slice(index, 1)
        if !left_ch.equals(right_ch) {
            let left_prefix: utf8 = left.slice(0, index + 1)
            let right_prefix: utf8 = right.slice(0, index + 1)
            if left_prefix.length() < right_prefix.length() {
                return -1
            }
            if left_prefix.length() > right_prefix.length() {
                return 1
            }
            return if left_len < right_len { -1 } else { 1 }
        }
        index = index + 1
    }

    if left_len < right_len {
        return -1
    }
    if left_len > right_len {
        return 1
    }
    return 0
}

micro sort_texts(mut values: [utf8]) -> unit {
    # Insertion sort over cardinal indices (offset), not ordinal `[]`.
    let mut i: usize = 1
    while i < values.length() {
        let current: utf8 = values⁅i⁆
        let mut j: usize = i
        while j > 0 && compare_utf8_text(values⁅j - 1⁆, current) > 0 {
            values⁅j⁆ = values⁅j - 1⁆
            j = j - 1
        }
        values⁅j⁆ = current
        i = i + 1
    }
}

micro parent_path(path: utf8) -> utf8 {
    let normalized: utf8 = normalize_path(path)
    let parts: [utf8] = normalized.split("/")
    let mut last_index: i32 = parts.length() as i32 - 1
    while last_index >= 0 {
        if parts⁅last_index as usize⁆.length() > 0 {
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
        let part: utf8 = parts⁅i⁆
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

micro append_unique_normalized_files(result: [utf8], directory: utf8, pattern: utf8) -> [utf8] {
    let files: [utf8] = collect_directory_files(directory, pattern)
    let mut acc: [utf8] = result
    let mut i: usize = 0
    while i < files.length() {
        let normalized: utf8 = normalize_path(files⁅i⁆)
        acc = push_unique_text(acc, normalized)
        i = i + 1
    }
    return acc
}

micro collect_project_source_files(project_dir: utf8, include_test_sources: bool) -> [utf8] {
    let mut result: [utf8] = []

    let source_dir: utf8 = path_join(project_dir, "source")
    result = append_unique_normalized_files(result, source_dir, "*.v")
    result = append_unique_normalized_files(result, source_dir, "*.ggs")

    let script_dir: utf8 = path_join(project_dir, "script")
    result = append_unique_normalized_files(result, script_dir, "*.v")
    result = append_unique_normalized_files(result, script_dir, "*.ggs")

    if include_test_sources {
        let test_dir: utf8 = path_join(project_dir, "test")
        result = append_unique_normalized_files(result, test_dir, "*.v")
        result = append_unique_normalized_files(result, test_dir, "*.ggs")
    }

    sort_texts(result)
    return result
}

# Walk one workspace's members; descend into nested `legions.von` workspaces
# (e.g. `projects/nyar._` → `projects/nyar`) so deps like `nyar` resolve.
micro resolve_dependency_in_workspace(workspace_manifest_path: utf8, dependency_name: utf8) -> utf8 {
    let workspace_dir: utf8 = workspace_root_dir(workspace_manifest_path)
    match legion_read_workspace_manifest(workspace_manifest_path) {
        case Fine(workspace_manifest):
            let mut member_index: usize = 0
            while member_index < workspace_manifest.members.length() {
                let member_dir: utf8 = path_join(workspace_dir, workspace_manifest.members⁅member_index⁆)
                let member_manifest_path: utf8 = path_join(member_dir, "legion.von")
                if std.io.file_exists(member_manifest_path) {
                    let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(member_dir)
                    match legion_read_project_manifest(member_manifest_path, auto_link.core, auto_link.std, auto_link.has_default) {
                        case Fine(member_manifest):
                            # Match manifest.name OR workspace member basename (seed planner
                            # alias): `projects/core` may be named `valkyrie-core` while
                            # auto_link inserts the logical dep name `core`.
                            let member_name: utf8 = legion_project_name(member_dir, member_manifest)
                            let member_basename: utf8 = legion_last_path_segment(member_dir)
                            if member_name == dependency_name || member_basename == dependency_name {
                                return member_dir
                            }
                        case Fail(_):
                            ()
                    }
                }
                else {
                    let nested_workspace: utf8 = path_join(member_dir, "legions.von")
                    if std.io.file_exists(nested_workspace) {
                        let nested_hit: utf8 = resolve_dependency_in_workspace(nested_workspace, dependency_name)
                        if nested_hit.length() > 0 {
                            return nested_hit
                        }
                    }
                }
                member_index = member_index + 1
            }
        case Fail(_):
            ()
    }
    return ""
}

micro resolve_workspace_member_dir(project_dir: utf8, dependency_name: utf8) -> utf8 {
    let mut workspace_manifest_path: utf8 = find_workspace_manifest_path(project_dir)
    while workspace_manifest_path.length() > 0 {
        let hit: utf8 = resolve_dependency_in_workspace(workspace_manifest_path, dependency_name)
        if hit.length() > 0 {
            return hit
        }

        # Nested workspaces (e.g. nyar._) do not list outer members like `std`/`core`.
        # Climb to the next enclosing `legions.von`.
        let workspace_dir: utf8 = workspace_root_dir(workspace_manifest_path)
        let mut climb: utf8 = parent_path(workspace_dir)
        let mut next_workspace: utf8 = ""
        while climb.length() > 0 {
            let candidate: utf8 = path_join(climb, "legions.von")
            if std.io.file_exists(candidate) && candidate != workspace_manifest_path {
                next_workspace = candidate
                break
            }
            let parent: utf8 = parent_path(climb)
            if parent.length() == 0 || parent == climb {
                break
            }
            climb = parent
        }
        workspace_manifest_path = next_workspace
    }
    return ""
}

micro collect_source_closure_recursive(
    project_dir: utf8,
    manifest: LegionProjectManifest,
    include_test_sources: bool,
    state: SourceClosureState
) -> VonParseResult<SourceClosureState> {
    let project_name: utf8 = legion_project_name(project_dir, manifest)
    if text_list_contains(state.visited_package_names, project_name) {
        return Fine(state)
    }

    let mut visited: [utf8] = push(state.visited_package_names, project_name)
    let mut package_names: [utf8] = push_unique_text(state.package_names, project_name)
    let mut package_dirs: [utf8] = push_unique_text(state.package_dirs, normalize_path(project_dir))
    let mut files: [utf8] = state.files

    let project_files: [utf8] = collect_project_source_files(project_dir, include_test_sources)
    let mut file_idx: usize = 0
    while file_idx < project_files.length() {
        files = push_unique_text(files, project_files⁅file_idx⁆)
        file_idx = file_idx + 1
    }

    let dependency_names: [utf8] = legion_dependency_names(manifest, project_name)
    let mut dep_idx: usize = 0
    while dep_idx < dependency_names.length() {
        let dependency_name: utf8 = dependency_names⁅dep_idx⁆
        let dependency_dir: utf8 = resolve_workspace_member_dir(project_dir, dependency_name)
        if dependency_dir.length() == 0 {
            return Fail(new_von_diagnostic("未找到依赖包目录：" + dependency_name, 0, 0))
        }

        let dependency_manifest_path: utf8 = path_join(dependency_dir, "legion.von")
        let auto_link: WorkspaceAutoLinkResult = try_load_workspace_auto_link(dependency_dir)
        let auto_core: bool = auto_link.core
        let auto_std: bool = auto_link.std
        let auto_has_default: bool = auto_link.has_default
        match legion_read_project_manifest(dependency_manifest_path, auto_core, auto_std, auto_has_default) {
            case Fine(dependency_manifest):
                let child_state: SourceClosureState = SourceClosureState {
                    visited_package_names: visited,
                    package_names: package_names,
                    package_dirs: package_dirs,
                    files: files
                }
                match collect_source_closure_recursive(
                    dependency_dir,
                    dependency_manifest,
                    include_test_sources,
                    child_state) {
                    case Fine(updated_acc):
                        visited = updated_acc.visited_package_names
                        package_names = updated_acc.package_names
                        package_dirs = updated_acc.package_dirs
                        files = updated_acc.files
                    case Fail(error):
                        return Fail(error)
                }
            case Fail(error):
                return Fail(error)
        }
        dep_idx = dep_idx + 1
    }

    return Fine(SourceClosureState {
        visited_package_names: visited,
        package_names: package_names,
        package_dirs: package_dirs,
        files: files
    })
}

micro collect_source_closure(context: LegionBuildContext, manifest: LegionProjectManifest) -> VonParseResult<LegionSourceClosurePlan> {
    let initial_state: SourceClosureState = SourceClosureState {
        visited_package_names: [],
        package_names: [],
        package_dirs: [],
        files: []
    }

    match collect_source_closure_recursive(
        context.project_dir,
        manifest,
        context.include_test_sources,
        initial_state) {
        case Fail(error):
            return Fail(error)
        case Fine(state):
            sort_texts(state.package_names)
            sort_texts(state.package_dirs)
            sort_texts(state.files)
            return Fine(LegionSourceClosurePlan {
                package_names: state.package_names,
                package_dirs: state.package_dirs,
                files: state.files
            })
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
    # Do not use `string + length()` — CLR currently emits raw `add` then `castclass string` (AV).
    let mut result: utf8 = append_line(buffer, title + ": " + format("{}", values.length()) + " 项")
    let mut i: usize = 0
    while i < values.length() {
        result = append_line(result, "  " + values⁅i⁆)
        i = i + 1
    }

    return result
}

micro merge_project_source_files(files: [utf8], project_dir: utf8) -> [utf8] {
    # Planner closure has dropped project `source/*.v` (e.g. `_.v`) on CLR; re-scan.
    let project_files: [utf8] = collect_project_source_files(project_dir, false)
    let mut acc: [utf8] = files
    let mut i: usize = 0
    while i < project_files.length() {
        acc = push_unique_text(acc, project_files⁅i⁆)
        i = i + 1
    }
    return acc
}

micro write_compile_plan_snapshot(plan: LegionCompilePlan) -> bool {
    let merged_files: [utf8] = merge_project_source_files(plan.source_closure.files, plan.project_dir)
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
    content = append_prefixed_lines(content, "files", merged_files)
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
        executor_mode: "emitter",
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
    if request.executor_mode != "emitter" {
        return LegionBackendExecutionResult {
            executor_kind: "unsupported",
            success: false,
            error: "未知的后端执行模式：" + request.executor_mode
        }
    }

    if request.arch_tag == "clr" || request.arch_tag == "wasm" {
        let exit_code: i32 = emitter_compile_project(request.project_dir, request.canonical_target, request.output_dir, request.verbose)
        if exit_code != 0 {
            return LegionBackendExecutionResult {
                executor_kind: "emitter",
                success: false,
                error: "nyar driver 编译执行失败，退出码 = " + format("{}", exit_code)
            }
        }
        return LegionBackendExecutionResult {
            executor_kind: "emitter",
            success: true,
            error: ""
        }
    }

    return LegionBackendExecutionResult {
        executor_kind: "emitter",
        success: false,
        error: "当前目标尚未接入源码编译执行器：" + request.canonical_target
    }
}
