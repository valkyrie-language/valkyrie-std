namespace legion;

use std.data.text.von;
use std.io;

structure LegionBuildTarget {
    name: utf8
}

structure LegionProjectManifest {
    name: utf8
    description: utf8
    build_targets: [LegionBuildTarget]
    dependencies: [utf8]
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

micro legion_collect_dependency_names(value: VonValue) -> [utf8] {
    let mut result: [utf8] = []
    let fields: [VonField] = von_as_object(value)
    let mut i: usize = 0
    while i < len(fields) {
        let field: VonField = fields[i]
        if len(field.name) > 0 {
            push(result, field.name)
        }
        i = i + 1
    }
    return result
}

micro legion_project_manifest_from_von(document: VonValue) -> VonParseResult<LegionProjectManifest> {
    match document {
        case Object(_):
            return Fine(LegionProjectManifest {
                name: von_as_text(von_find_field(document, "name")),
                description: von_as_text(von_find_field(document, "description")),
                build_targets: legion_collect_build_targets(von_find_field(document, "build")),
                dependencies: legion_collect_dependency_names(von_find_field(document, "dependencies"))
            })
        else:
            return Fail(new_von_diagnostic("legion.von 根节点必须是对象", 0, 0))
    }
}

micro legion_workspace_manifest_from_von(document: VonValue) -> VonParseResult<LegionWorkspaceManifest> {
    match document {
        case Object(_):
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

micro legion_read_project_manifest(path: utf8) -> VonParseResult<LegionProjectManifest> {
    match legion_read_von_document(path) {
        case Fine(document):
            return legion_project_manifest_from_von(document)
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
