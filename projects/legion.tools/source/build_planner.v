namespace legion;

using std.io;

structure LegionSourceClosurePlan {
    package_names: [utf8]
    package_dirs: [utf8]
    files: [utf8]
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
