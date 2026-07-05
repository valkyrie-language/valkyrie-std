namespace nyar.language.valkyrie;

using std.io;

structure CollectedBody {
    text: utf8
    next_index: usize
}

micro dq() -> utf8 {
    return '''"'''
}

micro find_char(source: utf8, ch: utf8, from_index: i32) -> i32 {
    let mut i: i32 = from_index
    while i < source.length() {
        if source[i] == ch {
            return i
        }
        i = i + 1
    }
    return -1
}

micro slice_text(source: utf8, start: i32, end: i32) -> utf8 {
    if start < 0 {
        start = 0
    }
    if end < start {
        return ""
    }
    if end > source.length() {
        end = source.length()
    }
    return source.slice(start, end)
}

micro trim_text(value: utf8) -> utf8 {
    return value.trim()
}

micro extract_quoted_string(source: utf8, open_paren_index: i32) -> Option<utf8> {
    let marker: utf8 = dq()
    let start: i32 = open_paren_index + 1
    let mut i: i32 = start
    while i < source.length() {
        if source[i] == marker {
            return Some(slice_text(source, start, i))
        }
        i = i + 1
    }
    return None
}

micro parse_clr_attribute(line: utf8) -> Option<ParsedClrExtern> {
    let open: i32 = line.index_of("(")
    let close: i32 = line.last_index_of(")")
    if open < 0 || close <= open {
        return None
    }
    let inner: utf8 = slice_text(line, open + 1, close)
    let parts: [utf8] = inner.split(",")
    if parts.length() < 3 {
        return None
    }
    return Some(ParsedClrExtern {
        assembly: trim_text(parts[0]),
        owner_type: trim_text(parts[1]),
        method_name: trim_text(parts[2])
    })
}

micro parse_function_header(line: utf8) -> Option<ParsedFunction> {
    if !line.contains("micro ") {
        return None
    }
    let name_start: i32 = line.index_of("micro ")
    if name_start < 0 {
        return None
    }
    let after_micro: utf8 = slice_text(line, name_start + 6, line.length())
    let paren: i32 = after_micro.index_of("(")
    if paren < 0 {
        return None
    }
    let name: utf8 = trim_text(slice_text(after_micro, 0, paren))
    let mut parsed: ParsedFunction = empty_parsed_function()
    parsed.name = name
    parsed.return_is_unit = line.contains("): unit") || line.contains(") -> unit") || line.contains("): unit;")
    parsed.return_is_i64 = line.contains(") -> i64") || line.contains("): i64")
    return Some(parsed)
}

micro collect_function_body(lines: [utf8], start_index: usize) -> CollectedBody {
    let mut body: utf8 = ""
    let mut brace_depth: i32 = 0
    let mut i: usize = start_index
    while i < lines.length() {
        let line: utf8 = lines[i]
        body = body + line + "\n"
        let mut j: i32 = 0
        while j < line.length() {
            let ch: utf8 = line[j]
            if ch == "{" {
                brace_depth = brace_depth + 1
            }
            if ch == "}" {
                brace_depth = brace_depth - 1
                if brace_depth <= 0 {
                    return CollectedBody {
                        text: body,
                        next_index: i + 1
                    }
                }
            }
            j = j + 1
        }
        i = i + 1
    }
    return CollectedBody {
        text: body,
        next_index: i
    }
}

micro find_call_literal(body: utf8, callee: utf8) -> Option<utf8> {
    let marker: utf8 = callee + "(" + dq()
    let start: i32 = body.index_of(marker)
    if start < 0 {
        return None
    }
    return extract_quoted_string(body, start + callee.length())
}

micro body_contains_call(body: utf8, callee: utf8) -> bool {
    return body.contains(callee + "(")
}

micro body_contains_return_literal(body: utf8) -> Option<utf8> {
    let marker: utf8 = "return " + dq()
    let start: i32 = body.index_of(marker)
    if start < 0 {
        return None
    }
    return extract_quoted_string(body, start + 7)
}

micro parse_module_source(source: utf8) -> ParsedModule {
    let mut parsed: ParsedModule = empty_parsed_module()
    let namespace_marker: utf8 = "namespace "
    let ns_start: i32 = source.index_of(namespace_marker)
    if ns_start >= 0 {
        let from: i32 = ns_start + namespace_marker.length()
        let mut end: i32 = from
        while end < source.length() {
            let ch: utf8 = source[end]
            if ch == ";" || ch == "\n" || ch == "\r" {
                break
            }
            end = end + 1
        }
        parsed.namespace_name = trim_text(slice_text(source, from, end))
    }

    let lines: [utf8] = source.split("\n")
    let mut pending_clr: Option<ParsedClrExtern> = None
    let mut pending_main: bool = false
    let mut i: usize = 0
    while i < lines.length() {
        let line: utf8 = trim_text(lines[i])
        if line.starts_with("[clr(") {
            pending_clr = parse_clr_attribute(line)
            i = i + 1
            continue
        }
        if line == "[main]" {
            pending_main = true
            i = i + 1
            continue
        }
        let header: Option<ParsedFunction> = parse_function_header(line)
        if header.is_some() {
            let parsed_header: ParsedFunction = header.unwrap()
            let collected: CollectedBody = collect_function_body(lines, i + 1)
            parsed_header.body_source = collected.text
            parsed_header.is_main = pending_main
            parsed_header.is_clr_extern = pending_clr.is_some()
            if pending_clr.is_some() {
                parsed_header.clr_extern = pending_clr.unwrap()
            }
            push(parsed.functions, parsed_header)
            pending_clr = None
            pending_main = false
            i = collected.next_index
            continue
        }
        i = i + 1
    }
    return parsed
}

micro parse_modules_from_files(files: [utf8]) -> [ParsedModule] {
    let mut modules: [ParsedModule] = []
    loop file_path in files {
        if !std.io.file_exists(file_path) {
            continue
        }
        let content: utf8 = std.io.read_file_text(file_path)
        push(modules, parse_module_source(content))
    }
    return modules
}

micro find_function(parsed: ParsedModule, name: utf8) -> Option<ParsedFunction> {
    loop item in parsed.functions {
        if item.name == name {
            return Some(item)
        }
    }
    return None
}

micro qualified_symbol(namespace_name: utf8, function_name: utf8) -> utf8 {
    if namespace_name.length() == 0 {
        return function_name
    }
    return namespace_name + "." + function_name
}

micro namespace_to_symbol(namespace_name: utf8) -> utf8 {
    return namespace_name.replace(".", "__")
}

micro operation_method_name(namespace_name: utf8, function_name: utf8) -> utf8 {
    return namespace_to_symbol(namespace_name) + "__" + function_name
}
