namespace legion;

using std.data.text.von;
using std.io;

structure LegionBuildTarget {
    name: utf8
}

structure LegionDependency {
    name: utf8
    version: utf8
    abi: utf8
}

structure LegionProjectManifest {
    name: utf8
    description: utf8
    build_targets: [LegionBuildTarget]
    auto_link_core: bool
    auto_link_std: bool
    dependencies: [LegionDependency]
}

structure LegionWorkspaceManifest {
    members: [utf8]
}

micro legion_read_von_document(path: utf8) -> VonParseResult<VonValue> {
    if !std.io.file_exists(path) {
        return Fail(new_von_diagnostic("找不到清单文件", 0, 0))
    }

    let source: utf8 = std.io.read_file_text(path)
    return parse_von(source)
}

micro legion_collect_build_targets(value: VonValue) -> [LegionBuildTarget] {
    let mut result: [LegionBuildTarget] = []
    let items: [VonValue] = von_as_array(value)
    let mut i: usize = 0
    while i < len(items) {
        let item: VonValue = items[i]
        let target_name: utf8 = von_as_text(von_find_field(item, "target"))
        if len(target_name) > 0 {
            push(result, LegionBuildTarget {
                name: target_name
            })
        }
        i = i + 1
    }
    return result
}

# 从 VON 值中解析依赖对象，过滤掉 core/std 布尔标志
micro legion_collect_dependencies(deps_value: VonValue) -> [LegionDependency] {
    let mut result: [LegionDependency] = []
    let fields: [VonField] = von_as_object(deps_value)
    let mut i: usize = 0
    while i < len(fields) {
        let field: VonField = fields[i]

        # 跳过 core/std 布尔控制标志（兼容旧 schema）
        if field.name == "core" || field.name == "std" {
            i = i + 1
            continue
        }

        if len(field.name) > 0 {
            let version: utf8 = ""
            let abi: utf8 = ""

            match field.value {
                case Object(inner_fields):
                    let ver_val: VonValue = von_find_field(field.value, "version")
                    version = von_as_text(ver_val)
                    let abi_val: VonValue = von_find_field(field.value, "abi")
                    abi = von_as_text(abi_val)
                default:
                    version = von_as_text(field.value)
            }

            push(result, LegionDependency {
                name: field.name,
                version: version,
                abi: abi
            })
        }
        i = i + 1
    }
    return result
}

# 从 VON 对象中解析 auto_link 配置
# 优先级：项目级 auto_link > workspace_auto_link > 默认值 (true, true)
micro legion_parse_auto_link(value: VonValue, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> (bool, bool) {
    let auto_link: VonValue = von_find_field(value, "auto_link")
    match auto_link {
        case Object(fields):
            let core_val: VonValue = von_find_field(auto_link, "core")
            let std_val: VonValue = von_find_field(auto_link, "std")
            let core: bool = von_as_bool(core_val)
            let std: bool = von_as_bool(std_val)
            return (core, std)
        default:
            if has_workspace_default {
                return (workspace_auto_core, workspace_auto_std)
            }
            # 无 workspace 时的默认值：自动链接 core 和 std
            return (true, true)
    }
}

# 从 workspace legions.von 解析 auto_link 默认值
micro legion_parse_workspace_auto_link(document: VonValue) -> (bool, bool, bool) {
    let ws_field: VonValue = von_find_field(document, "workspace")
    match ws_field {
        case Object(fields):
            let auto_link: VonValue = von_find_field(ws_field, "auto_link")
            match auto_link {
                case Object(fields):
                    let core_val: VonValue = von_find_field(auto_link, "core")
                    let std_val: VonValue = von_find_field(auto_link, "std")
                    return (von_as_bool(core_val), von_as_bool(std_val), true)
                default:
                    return (true, true, false)
            }
        default:
            return (true, true, false)
    }
}

micro legion_project_manifest_from_von(document: VonValue, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> VonParseResult<LegionProjectManifest> {
    match document {
        case Object(fields):
            let (auto_core, auto_std) = legion_parse_auto_link(document, workspace_auto_core, workspace_auto_std, has_workspace_default)
            let deps_value: VonValue = von_find_field(document, "dependencies")

            return Fine(LegionProjectManifest {
                name: von_as_text(von_find_field(document, "name")),
                description: von_as_text(von_find_field(document, "description")),
                build_targets: legion_collect_build_targets(von_find_field(document, "build")),
                auto_link_core: auto_core,
                auto_link_std: auto_std,
                dependencies: legion_collect_dependencies(deps_value)
            })
        else:
            return Fail(new_von_diagnostic("legion.von 根节点必须是对象", 0, 0))
    }
}

micro legion_workspace_manifest_from_von(document: VonValue) -> VonParseResult<LegionWorkspaceManifest> {
    match document {
        case Object(fields):
            let mut members: [utf8] = []
            let items: [VonValue] = von_as_array(von_find_field(document, "members"))
            let mut i: usize = 0
            while i < len(items) {
                let member: utf8 = von_as_text(items[i])
                if len(member) > 0 {
                    push(members, member)
                }
                i = i + 1
            }

            return Fine(LegionWorkspaceManifest {
                members: members
            })
        else:
            return Fail(new_von_diagnostic("legions.von 根节点必须是对象", 0, 0))
    }
}

micro legion_read_project_manifest(path: utf8, workspace_auto_core: bool, workspace_auto_std: bool, has_workspace_default: bool) -> VonParseResult<LegionProjectManifest> {
    match legion_read_von_document(path) {
        case Fine(document):
            return legion_project_manifest_from_von(document, workspace_auto_core, workspace_auto_std, has_workspace_default)
        case Fail(error):
            return Fail(error)
    }
}

micro legion_read_workspace_manifest(path: utf8) -> VonParseResult<LegionWorkspaceManifest> {
    match legion_read_von_document(path) {
        case Fine(document):
            return legion_workspace_manifest_from_von(document)
        case Fail(error):
            return Fail(error)
    }
}