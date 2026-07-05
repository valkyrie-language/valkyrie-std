namespace nyar.language.valkyrie;

micro dq() -> utf8 {
    return '''"'''
}

micro namespace_to_symbol(namespace_name: utf8) -> utf8 {
    return namespace_name.replace(".", "__")
}

micro contains_forbidden_marker(source: utf8, marker: utf8) -> bool {
    return source.contains(marker)
}

micro smoke_capability_error(source: utf8, file_count: usize, dependency_count: i32) -> Option<utf8> {
    if dependency_count > 0 {
        return Some("依赖闭包超出 smoke 子集：暂不支持 workspace 依赖包")
    }
    if file_count == 0 {
        return Some("源码闭包为空")
    }
    if file_count > 8 {
        return Some("源码文件数量超出 smoke 子集上限")
    }
    if contains_forbidden_marker(source, "<%") {
        return Some("暂不支持 arch 模板预处理（<% match arch %>）")
    }
    if contains_forbidden_marker(source, "structure ") {
        return Some("暂不支持 structure 声明")
    }
    if contains_forbidden_marker(source, "trait ") {
        return Some("暂不支持 trait")
    }
    if contains_forbidden_marker(source, "using legion") {
        return Some("暂不支持 legion.tools 级依赖解析")
    }
    if !source.contains("[main]") {
        return Some("smoke 子集要求存在 [main] 入口")
    }
    if !source.contains("console_write_line(") {
        return Some("smoke 子集要求 main 调用 console_write_line(...)")
    }
    return None
}

micro extract_namespace(source: utf8) -> utf8 {
    let marker: utf8 = "namespace "
    let start: i32 = source.index_of(marker)
    if start < 0 {
        return "smoke"
    }
    let from: i32 = start + marker.length()
    let mut end: i32 = from
    while end < source.length() {
        let ch: utf8 = source[end]
        if ch == ";" || ch == "\n" || ch == "\r" {
            break
        }
        end = end + 1
    }
    return source.slice(from, end).trim()
}

micro extract_console_message(source: utf8) -> utf8 {
    let marker: utf8 = "console_write_line(" + dq()
    let start: i32 = source.index_of(marker)
    if start < 0 {
        return "legion.tools smoke"
    }
    let from: i32 = start + marker.length()
    let mut end: i32 = from
    while end < source.length() {
        if source[end] == dq() {
            break
        }
        end = end + 1
    }
    return source.slice(from, end)
}

micro compile_source_to_build_output(combined_source: utf8, file_count: usize) -> SmokeCompileResult {
    let capability_error: Option<utf8> = smoke_capability_error(combined_source, file_count, 0)
    if capability_error.is_some() {
        return SmokeCompileResult {
            ok: false,
            error: capability_error.unwrap(),
            output: SmokeBuildOutput {
                assembly_name: "",
                namespace_symbol: "",
                console_message: "",
                source_files: []
            }
        }
    }

    let namespace_name: utf8 = extract_namespace(combined_source)
    let namespace_symbol: utf8 = namespace_to_symbol(namespace_name)
    let message: utf8 = extract_console_message(combined_source)
    return SmokeCompileResult {
        ok: true,
        error: "",
        output: SmokeBuildOutput {
            assembly_name: "legion__" + namespace_symbol + "__functions",
            namespace_symbol: namespace_symbol,
            console_message: message,
            source_files: []
        }
    }
}
