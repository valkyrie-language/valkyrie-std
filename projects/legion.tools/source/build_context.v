namespace legion;

structure LegionBuildContext {
    project_dir: utf8
    manifest_path: utf8
    project_name: utf8
    canonical_target: utf8
    output_dir: utf8
    dependency_names: [utf8]
    verbose: bool
}

micro legion_canonical_target(target: utf8) -> utf8 {
    let value: utf8 = target.trim().to_lower()
    if value == "clr" || value == "clr-microsoft-unknown-managed" {
        return "clr-microsoft-unknown-managed"
    }
    if value == "jvm" || value == "jvm-openjdk-unknown-managed" {
        return "jvm-openjdk-unknown-managed"
    }
    if value == "wasm" || value == "wasm32-unknown-web-webassembly" {
        return "wasm32-unknown-web-webassembly"
    }
    if value == "nyar" || value == "nyar-unknown-unknown" {
        return "nyar-unknown-unknown"
    }
    return ""
}

micro legion_requested_targets(value: utf8) -> [utf8] {
    if len(value.trim()) == 0 {
        return []
    }
    if value.trim().to_lower() == "all" {
        return ["clr", "jvm", "wasm", "nyar"]
    }

    let mut result: [utf8] = []
    let pieces: [utf8] = value.split(",")
    let mut i: usize = 0
    while i < len(pieces) {
        let target: utf8 = pieces[i].trim()
        if len(target) > 0 {
            push(result, target)
        }
        i = i + 1
    }
    return result
}

micro legion_manifest_targets(manifest: LegionProjectManifest, requested_target: utf8) -> [utf8] {
    let explicit_targets: [utf8] = legion_requested_targets(requested_target)
    if len(explicit_targets) > 0 {
        return explicit_targets
    }

    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < len(manifest.build_targets) {
        push(result, manifest.build_targets[i].name)
        i = i + 1
    }
    return result
}

micro legion_last_path_segment(path: utf8) -> utf8 {
    let parts: [utf8] = normalize_path(path).split("/")
    let mut result: utf8 = ""
    let mut i: usize = 0
    while i < len(parts) {
        if len(parts[i]) > 0 {
            result = parts[i]
        }
        i = i + 1
    }
    return result
}

micro legion_project_name(project_dir: utf8, manifest: LegionProjectManifest) -> utf8 {
    if len(manifest.name.trim()) > 0 {
        return manifest.name.trim()
    }
    return legion_last_path_segment(project_dir)
}

micro legion_output_root(project_dir: utf8, output: utf8) -> utf8 {
    if len(output.trim()) == 0 {
        return path_join(project_dir, "dist")
    }
    return resolve_project_dir(output)
}

micro legion_build_contexts(
    project_dir: utf8,
    manifest_path: utf8,
    manifest: LegionProjectManifest,
    request: BuildRequest)
    -> VonParseResult<[LegionBuildContext]> {
    let targets: [utf8] = legion_manifest_targets(manifest, request.target)
    if len(targets) == 0 {
        return Fail(new_von_diagnostic("未指定构建目标，且 legion.von 中无 build 列表", 0, 0))
    }

    let mut contexts: [LegionBuildContext] = []
    let output_root: utf8 = legion_output_root(project_dir, request.output)
    let project_name: utf8 = legion_project_name(project_dir, manifest)

    let mut i: usize = 0
    while i < len(targets) {
        let requested: utf8 = targets[i]
        let canonical: utf8 = legion_canonical_target(requested)
        if len(canonical) == 0 {
            return Fail(new_von_diagnostic("存在不支持的构建目标", 0, 0))
        }

        push(contexts, LegionBuildContext {
            project_dir: project_dir,
            manifest_path: manifest_path,
            project_name: project_name,
            canonical_target: canonical,
            output_dir: path_join(output_root, canonical),
            dependency_names: manifest.dependencies,
            verbose: request.verbose
        })
        i = i + 1
    }

    return Fine(contexts)
}
