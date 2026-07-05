namespace legion;

using std.data.text.von;
using std.io;

structure LegionBuildTargetOptions {
    source_map: bool
    type_script: bool
    wat: bool
    msil: bool
}

structure LegionBuildTarget {
    name: utf8
    options: LegionBuildTargetOptions
}

structure LegionDependency {
    name: utf8
    version: utf8
    abi: utf8
}

structure LegionProjectManifest {
    name: utf8
    version: utf8
    description: utf8
    build_targets: [LegionBuildTarget]
    publish_targets: [LegionPublishTarget]
    auto_link_core: bool
    auto_link_std: bool
    dependencies: [LegionDependency]
}

structure LegionPublishTarget {
    target: utf8
    format_type: utf8
    package_id: utf8
    version: utf8
}

structure LegionWorkspaceManifest {
    members: [utf8]
}

⍝ auto_link 解析结果（core + std）
structure AutoLinkResult {
    core: bool
    std: bool
}

⍝ workspace auto_link 解析结果（core + std + has_default）
structure WorkspaceAutoLinkResult {
    core: bool
    std: bool
    has_default: bool
}

micro legion_read_von_document(path: utf8) -> VonParseResult<VonValue> {
    if !std.io.file_exists(path) {
        return Fail(new_von_diagnostic("找不到清单文件", 0, 0))
    }

    let source: utf8 = std.io.read_file_text(path)
    return parse_von(source)
}

micro legion_empty_build_target_options() -> LegionBuildTargetOptions {
    return LegionBuildTargetOptions {
        source_map: false,
        type_script: false,
        wat: false,
        msil: false
    }
}

micro legion_collect_build_targets(value: VonValue) -> [LegionBuildTarget] {
    return von_as_array(value)
        .into_iterator()
        .map(micro(item: VonValue) -> LegionBuildTarget {
            let target_name: utf8 = von_as_text(von_find_field(item, "target"))
            let options: LegionBuildTargetOptions = LegionBuildTargetOptions {
                source_map: von_as_bool(von_find_field(item, "source_map")),
                type_script: von_as_bool(von_find_field(item, "type_script")),
                wat: von_as_bool(von_find_field(item, "wat")),
                msil: von_as_bool(von_find_field(item, "msil"))
            }

            return LegionBuildTarget {
                name: target_name,
                options: options
            }
        })
        .filter(micro(target: LegionBuildTarget) -> bool {
            return target.name.length() > 0
        })
        .collect_array()
}

micro legion_collect_publish_targets(value: VonValue, default_version: utf8) -> [LegionPublishTarget] {
    return von_as_array(value)
        .into_iterator()
        .map(micro(item: VonValue) -> LegionPublishTarget {
            let target_name: utf8 = von_as_text(von_find_field(item, "target"))
            let publish_type: utf8 = von_as_text(von_find_field(item, "type"))
            let package_id: utf8 = von_as_text(von_find_field(item, "package_id"))
            let publish_version_raw: utf8 = von_as_text(von_find_field(item, "version"))
            let publish_version: utf8 = if publish_version_raw.length() > 0 { publish_version_raw } else { default_version }

            return LegionPublishTarget {
                target: target_name,
                format_type: publish_type,
                package_id: package_id,
                version: publish_version
            }
        })
        .filter(micro(target: LegionPublishTarget) -> bool {
            return target.target.length() > 0 && target.format_type.length() > 0
        })
        .collect_array()
}

# 从 VON 值中解析依赖对象，过滤掉 core/std 布尔标志
micro legion_collect_dependencies(deps_value: VonValue) -> [LegionDependency] {
    return von_as_object(deps_value)
        .into_iterator()
        .filter(micro(field: VonField) -> bool {
            return field.name != "core" && field.name != "std"
        })
        .map(micro(field: VonField) -> LegionDependency {
            let version: utf8 = ""
            let abi: utf8 = ""

            if von_is_object(field.value) {
                let ver_val: VonValue = von_find_field(field.value, "version")
                version = von_as_text(ver_val)
                let abi_val: VonValue = von_find_field(field.value, "abi")
                abi = von_as_text(abi_val)
            }
            else {
                version = von_as_text(field.value)
            }

            return LegionDependency {
                name: field.name,
                version: version,
                abi: abi
            }
        })
        .filter(micro(dependency: LegionDependency) -> bool {
            return dependency.name.length() > 0
        })
        .collect_array()
}

# 从 VON 对象中解析 auto_link 配置
# 优先级：项目级 auto_link > workspace_auto_link > 默认值 (true, true)
micro legion_parse_auto_link(value: VonValue, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> AutoLinkResult {
    let auto_link: VonValue = von_find_field(value, "auto_link")
    if von_is_object(auto_link) {
        let core_val: VonValue = von_find_field(auto_link, "core")
        let std_val: VonValue = von_find_field(auto_link, "std")
        let core: bool = von_as_bool(core_val)
        let std: bool = von_as_bool(std_val)
        return AutoLinkResult { core: core, std: std }
    }
    if has_workspace_default {
        return AutoLinkResult { core: workspace_auto_core, std: workspace_auto_std }
    }
    return AutoLinkResult { core: true, std: true }
}

# 从 workspace legions.von 解析 auto_link 默认值
micro legion_parse_workspace_auto_link(document: VonValue) -> WorkspaceAutoLinkResult {
    let ws_field: VonValue = von_find_field(document, "workspace")
    if von_is_object(ws_field) {
        let auto_link: VonValue = von_find_field(ws_field, "auto_link")
        if von_is_object(auto_link) {
            let core_val: VonValue = von_find_field(auto_link, "core")
            let std_val: VonValue = von_find_field(auto_link, "std")
            return WorkspaceAutoLinkResult { core: von_as_bool(core_val), std: von_as_bool(std_val), has_default: true }
        }
        return WorkspaceAutoLinkResult { core: true, std: true, has_default: false }
    }
    return WorkspaceAutoLinkResult { core: true, std: true, has_default: false }
}

micro legion_project_manifest_from_von(document: VonValue, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> VonParseResult<LegionProjectManifest> {
    if !von_is_object(document) {
        return Fail(new_von_diagnostic("legion.von 根节点必须是对象", 0, 0))
    }
    let auto_link_result: AutoLinkResult = legion_parse_auto_link(document, workspace_auto_core, workspace_auto_std, has_workspace_default)
    let deps_value: VonValue = von_find_field(document, "dependencies")
    let project_version: utf8 = von_as_text(von_find_field(document, "version"))

    return Fine(LegionProjectManifest {
        name: von_as_text(von_find_field(document, "name")),
        version: project_version,
        description: von_as_text(von_find_field(document, "description")),
        build_targets: legion_collect_build_targets(von_find_field(document, "build")),
        publish_targets: legion_collect_publish_targets(von_find_field(document, "publish"), project_version),
        auto_link_core: auto_link_result.core,
        auto_link_std: auto_link_result.std,
        dependencies: legion_collect_dependencies(deps_value)
    })
}

micro legion_workspace_manifest_from_von(document: VonValue) -> VonParseResult<LegionWorkspaceManifest> {
    if !von_is_object(document) {
        return Fail(new_von_diagnostic("legions.von 根节点必须是对象", 0, 0))
    }
    let members: [utf8] = von_as_array(von_find_field(document, "members"))
        .into_iterator()
        .map(micro(item: VonValue) -> utf8 {
            return von_as_text(item)
        })
        .filter(micro(member: utf8) -> bool {
            return member.length() > 0
        })
        .collect_array()

    return Fine(LegionWorkspaceManifest {
        members: members
    })
}

micro legion_read_project_manifest(path: utf8, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> VonParseResult<LegionProjectManifest> {
    let parsed: VonParseResult<VonValue> = legion_read_von_document(path)
    let failure: VonDiagnostic? = von_parse_take_fail(parsed)
    if failure.is_some() {
        return Fail(failure.unwrap())
    }
    let document: VonValue = von_parse_take_fine(parsed).unwrap()
    return legion_project_manifest_from_von(document, workspace_auto_core, workspace_auto_std, has_workspace_default)
}

micro legion_read_workspace_manifest(path: utf8) -> VonParseResult<LegionWorkspaceManifest> {
    let parsed: VonParseResult<VonValue> = legion_read_von_document(path)
    let failure: VonDiagnostic? = von_parse_take_fail(parsed)
    if failure.is_some() {
        return Fail(failure.unwrap())
    }
    let document: VonValue = von_parse_take_fine(parsed).unwrap()
    return legion_workspace_manifest_from_von(document)
}
