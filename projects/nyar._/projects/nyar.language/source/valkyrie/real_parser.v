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
        if source⁅i⁆ == ch {
            return i
        }
        i = i + 1
    }
    return -1
}

micro slice_text(source: utf8, start: i32, end: i32) -> utf8 {
    # `utf8.slice(start, count)` — second arg is count, not exclusive end (CLR → Substring).
    if start < 0 {
        start = 0
    }
    if end < start {
        return ""
    }
    if end > source.length() {
        end = source.length()
    }
    let count: i32 = end - start
    return source.slice(start, count)
}

micro trim_text(value: utf8) -> utf8 {
    return value.trim()
}

micro extract_quoted_string(source: utf8, open_paren_index: i32) -> utf8 {
    let marker: utf8 = dq()
    let start: i32 = open_paren_index + 1
    let mut i: i32 = start
    while i < source.length() {
        if source⁅i⁆ == marker {
            return slice_text(source, start, i)
        }
        i = i + 1
    }
    return ""
}

micro strip_quotes(value: utf8) -> utf8 {
    let mut s: utf8 = trim_text(value)
    if s.length() >= 2 {
        let first: utf8 = s.slice(0, 1)
        let last: utf8 = s.slice(s.length() - 1, 1)
        if (first == dq() && last == dq()) || (first == "'" && last == "'") {
            return s.slice(1, s.length() - 2)
        }
    }
    return s
}

# CLR bootstrap: avoid `T?` / Option here — Some(T) is often lowered to bare T / null,
# and `Option_is_some` then `castclass Option` on null → NRE.
micro parse_clr_attribute(line: utf8) -> ParsedClrExtern {
    let open: i32 = line.index_of("(")
    let close: i32 = line.last_index_of(")")
    if open < 0 || close <= open {
        std.io.print_line("[v1-debug] clr_bad_parens open=" + format("{}", open) + " close=" + format("{}", close))
        return ParsedClrExtern {
            assembly: "",
            owner_type: "",
            method_name: ""
        }
    }
    let inner_len: i32 = close - (open + 1)
    let inner: utf8 = line.slice(open + 1, inner_len)
    # Do not use `split(...).length()` here — CLR often reports 0 on fresh split arrays.
    let c1: i32 = inner.index_of(",")
    if c1 < 0 {
        std.io.print_line("[v1-debug] clr_no_c1 inner_len=" + format("{}", inner.length()))
        return ParsedClrExtern {
            assembly: "",
            owner_type: "",
            method_name: ""
        }
    }
    let rest_start: i32 = c1 + 1
    let rest_len: i32 = inner.length() - rest_start
    let rest: utf8 = inner.slice(rest_start, rest_len)
    let c2: i32 = rest.index_of(",")
    if c2 < 0 {
        std.io.print_line("[v1-debug] clr_no_c2 rest_len=" + format("{}", rest.length()))
        return ParsedClrExtern {
            assembly: "",
            owner_type: "",
            method_name: ""
        }
    }
    let a0: utf8 = strip_quotes(inner.slice(0, c1))
    let a1: utf8 = strip_quotes(rest.slice(0, c2))
    let a2_start: i32 = c2 + 1
    let a2: utf8 = strip_quotes(rest.slice(a2_start, rest.length() - a2_start))
    std.io.print_line("[v1-debug] clr_parts=" + a0 + "|" + a1 + "|" + a2)
    return ParsedClrExtern {
        assembly: a0,
        owner_type: a1,
        method_name: a2
    }
}

micro parse_function_header(line: utf8) -> ParsedFunction {
    let marker: utf8 = "micro "
    # Accept `micro` / `private micro` / `public micro` — not prose mentioning the word.
    # Avoid `else if` here: CLR body lowering currently drops the elif condition
    # (else always strips 7 → Substring OOR on short lines like `[main]`).
    let mut hdr: utf8 = line.trim()
    if hdr.starts_with("private ") {
        if hdr.length() >= 8 {
            hdr = hdr.slice(8, hdr.length() - 8).trim()
        }
    }
    if hdr.starts_with("public ") {
        if hdr.length() >= 7 {
            hdr = hdr.slice(7, hdr.length() - 7).trim()
        }
    }
    if !hdr.starts_with(marker) {
        return empty_parsed_function()
    }
    let after_start: i32 = 6
    let line_len: i32 = hdr.length()
    if after_start >= line_len {
        return empty_parsed_function()
    }
    # Prefer Substring via slice(start, count) directly — avoid end/count confusion.
    let after_micro: utf8 = hdr.slice(after_start, line_len - after_start)
    let paren: i32 = after_micro.index_of("(")
    if paren < 0 {
        return empty_parsed_function()
    }
    if paren == 0 {
        return empty_parsed_function()
    }
    let name: utf8 = trim_text(after_micro.slice(0, paren))
    if name.length() == 0 || name.contains(" ") {
        return empty_parsed_function()
    }
    let mut parsed: ParsedFunction = empty_parsed_function()
    parsed.name = name
    parsed.return_is_unit = hdr.contains("): unit") || hdr.contains(") -> unit") || hdr.contains("): unit;")
    parsed.return_is_i64 = hdr.contains(") -> i64") || hdr.contains("): i64")
    return parsed
}

micro collect_function_body(lines: [utf8], line_count: usize, start_index: usize) -> CollectedBody {
    let mut body: utf8 = ""
    let mut brace_depth: i32 = 0
    let mut i: usize = start_index
    let mut in_str: utf8 = ""
    while i < line_count {
        let line: utf8 = lines⁅i⁆
        body = body + line + "\n"
        let mut j: i32 = 0
        let line_len: i32 = line.length()
        while j < line_len {
            let ch: utf8 = line⁅j⁆
            if in_str.length() > 0 {
                if ch == in_str {
                    in_str = ""
                    j = j + 1
                    continue
                }
                # Skip full `\u{…}` so braces inside escapes do not affect depth.
                if ch == "\u{5c}" && j + 1 < line_len {
                    if j + 3 < line_len && line.slice(j + 1, 2) == "u{" {
                        let mut k: i32 = j + 3
                        while k < line_len && line⁅k⁆ != "}" {
                            k = k + 1
                        }
                        if k < line_len {
                            j = k + 1
                        }
                        else {
                            j = line_len
                        }
                        continue
                    }
                    j = j + 2
                    continue
                }
                j = j + 1
                continue
            }
            # Line comments — `# … {` / `format("{}", x)` notes must not shift brace depth.
            if ch == "#" || (ch == "/" && j + 1 < line_len && line.slice(j + 1, 1) == "/") {
                j = line_len
                continue
            }
            if ch == dq() || ch == "'" {
                in_str = ch
                j = j + 1
                continue
            }
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

micro find_call_literal(body: utf8, callee: utf8) -> utf8 {
    let open_call: utf8 = callee + "("
    let start: i32 = body.index_of(open_call)
    if start < 0 {
        return ""
    }
    let after_paren: i32 = start + open_call.length()
    let mut i: i32 = after_paren
    while i < body.length() {
        let ch: utf8 = body.slice(i, 1)
        if ch == " " || ch == "\t" {
            i = i + 1
            continue
        }
        if ch == dq() || ch == "'" {
            let str_start: i32 = i + 1
            let mut j: i32 = str_start
            while j < body.length() {
                let end_ch: utf8 = body.slice(j, 1)
                if end_ch == ch {
                    return body.slice(str_start, j - str_start)
                }
                j = j + 1
            }
            return ""
        }
        break
    }
    return ""
}

micro is_ident_continue_char(ch: utf8) -> bool {
    if ch == "_" {
        return true
    }
    let digits: utf8 = "0123456789"
    if digits.contains(ch) {
        return true
    }
    let lower: utf8 = "abcdefghijklmnopqrstuvwxyz"
    if lower.contains(ch) {
        return true
    }
    let upper: utf8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return upper.contains(ch)
}

micro body_contains_call(body: utf8, callee: utf8) -> bool {
    # Real call `name(` — reject `.length(` and suffix of longer identifiers.
    let open_call: utf8 = callee + "("
    let mut from: i32 = 0
    while from < body.length() {
        let rest: utf8 = body.slice(from, body.length() - from)
        let at: i32 = rest.index_of(open_call)
        if at < 0 {
            return false
        }
        let abs: i32 = from + at
        if abs == 0 {
            return true
        }
        let prev: utf8 = body.slice(abs - 1, 1)
        if prev == "." || is_ident_continue_char(prev) {
            from = abs + 1
            continue
        }
        return true
    }
    return false
}

micro body_contains_return_literal(body: utf8) -> utf8 {
    let key: utf8 = "return "
    let start: i32 = body.index_of(key)
    if start < 0 {
        return ""
    }
    let mut i: i32 = start + key.length()
    while i < body.length() {
        let ch: utf8 = body.slice(i, 1)
        if ch == " " || ch == "\t" {
            i = i + 1
            continue
        }
        if ch == dq() || ch == "'" {
            let str_start: i32 = i + 1
            let mut j: i32 = str_start
            while j < body.length() {
                if body.slice(j, 1) == ch {
                    return body.slice(str_start, j - str_start)
                }
                j = j + 1
            }
            return ""
        }
        break
    }
    return ""
}

# Digits after `return` when the return value is a decimal integer literal.
micro body_return_integer_digits(body: utf8) -> utf8 {
    let key: utf8 = "return "
    let start: i32 = body.index_of(key)
    if start < 0 {
        return ""
    }
    let mut i: i32 = start + key.length()
    while i < body.length() {
        let ch: utf8 = body.slice(i, 1)
        if ch == " " || ch == "\t" {
            i = i + 1
            continue
        }
        break
    }
    if i >= body.length() {
        return ""
    }
    let mut neg: bool = false
    if body.slice(i, 1) == "-" {
        neg = true
        i = i + 1
    }
    let dig_start: i32 = i
    while i < body.length() {
        let ch: utf8 = body.slice(i, 1)
        if ch != "0" && ch != "1" && ch != "2" && ch != "3" && ch != "4" && ch != "5" && ch != "6" && ch != "7" && ch != "8" && ch != "9" {
            break
        }
        i = i + 1
    }
    if i == dig_start {
        return ""
    }
    let digits: utf8 = body.slice(dig_start, i - dig_start)
    while i < body.length() {
        let ch: utf8 = body.slice(i, 1)
        if ch == " " || ch == "\t" || ch == "\r" || ch == "\n" || ch == ";" || ch == "}" {
            i = i + 1
            continue
        }
        # Non-trivial trailing expression (e.g. return x.length()).
        return ""
    }
    if neg {
        return "-" + digits
    }
    return digits
}

micro body_needs_mir_lowering(body: utf8) -> bool {
    if body.contains("while ") || body.contains("while(") {
        return true
    }
    if body.contains(".length()") {
        return true
    }
    if body.contains("source_closure") || body.contains("package_names") {
        return true
    }
    if body.contains("if ") || body.contains("if(") {
        return true
    }
    if body.contains("let mut ") || body.contains("let ") {
        # Smoke may not use let; legion and cmp-smoke do.
        return true
    }
    return false
}

micro parse_module_source(source: utf8) -> ParsedModule {
    let mut parsed: ParsedModule = empty_parsed_module()
    let namespace_marker: utf8 = "namespace "
    let ns_start: i32 = source.index_of(namespace_marker)
    if ns_start >= 0 {
        let from: i32 = ns_start + namespace_marker.length()
        let mut end: i32 = from
        while end < source.length() {
            let ch: utf8 = source⁅end⁆
            if ch == ";" || ch == "\n" || ch == "\r" {
                break
            }
            end = end + 1
        }
        parsed.namespace_name = trim_text(slice_text(source, from, end))
    }

    let lines: [utf8] = source.split("\n")
    let line_count: usize = lines.length()
    let probe_legion: bool = source.contains("micro legion")
    if probe_legion {
        std.io.print_line("[v1-debug] parse_module line_count=" + format("{}", line_count as i32))
        std.io.print_line("[v1-debug] parse_module src_len=" + format("{}", source.length()))
        std.io.print_line("[v1-debug] parse_module has_micro_space=" + if source.contains("micro ") { "1" } else { "0" })
    }
    let mut pending_clr: ParsedClrExtern = ParsedClrExtern {
        assembly: "",
        owner_type: "",
        method_name: ""
    }
    let mut has_pending_clr: bool = false
    let mut pending_main: bool = false
    let mut imply_owner: utf8 = ""
    let mut functions: [ParsedFunction] = []
    let mut found_fn: i32 = 0
    let mut micro_line_hits: i32 = 0
    let mut i: usize = 0
    while i < line_count {
        let line: utf8 = trim_text(lines⁅i⁆)
        # Comments must not be scanned for `micro ` (e.g. "its own micro so…").
        if line.starts_with("#") || line.starts_with("//") {
            i = i + 1
            continue
        }
        if line.starts_with("imply ") {
            let rest: utf8 = line.slice(6, line.length() - 6).trim()
            let brace_on: i32 = rest.index_of("{")
            let gen_on: i32 = rest.index_of("<")
            let mut oname: utf8 = rest
            if brace_on >= 0 {
                oname = rest.slice(0, brace_on).trim()
            }
            if gen_on >= 0 && (brace_on < 0 || gen_on < brace_on) {
                oname = oname.slice(0, gen_on).trim()
            }
            let sp: i32 = oname.index_of(" ")
            if sp >= 0 {
                oname = oname.slice(0, sp).trim()
            }
            imply_owner = oname
            i = i + 1
            continue
        }
        if probe_legion && line.index_of("micro ") >= 0 && micro_line_hits < 3 {
            micro_line_hits = micro_line_hits + 1
            std.io.print_line("[v1-debug] micro_line=" + line)
            let hdr: ParsedFunction = parse_function_header(line)
            std.io.print_line("[v1-debug] hdr_name_len=" + format("{}", hdr.name.length()))
            if hdr.name.length() > 0 {
                std.io.print_line("[v1-debug] hdr_name=" + hdr.name)
            }
        }
        if line.index_of("[clr(") == 0 || line.starts_with("[clr(") || line.contains("[clr(") {
            pending_clr = parse_clr_attribute(line)
            has_pending_clr = pending_clr.assembly.length() > 0
            if probe_legion || line.contains("WriteLine") {
                std.io.print_line("[v1-debug] clr_line=" + line)
                std.io.print_line("[v1-debug] clr_asm_len=" + format("{}", pending_clr.assembly.length()))
                std.io.print_line("[v1-debug] clr_asm=" + pending_clr.assembly)
            }
            i = i + 1
            continue
        }
        if line == "[main]" || line.starts_with("[main]") {
            pending_main = true
            i = i + 1
            continue
        }
        let mut parsed_header: ParsedFunction = parse_function_header(line)
        if parsed_header.name.length() > 0 {
            parsed_header.is_main = pending_main || parsed_header.name == "legion" || parsed_header.name == "main"
            parsed_header.is_clr_extern = has_pending_clr
            if has_pending_clr {
                parsed_header.clr_extern = pending_clr
            }
            # Extern / forward decls end with `;` and must not swallow the next body.
            # Keep the header line as body_source so param/return parsing still works.
            if line.contains(";") && !line.contains("{") {
                parsed_header.body_source = line
                functions = push(functions, parsed_header)
                found_fn = found_fn + 1
                has_pending_clr = false
                pending_main = false
                i = i + 1
                continue
            }
            # Include the header line so `{` on the same line counts for brace depth.
            let collected: CollectedBody = collect_function_body(lines, line_count, i)
            if imply_owner.length() > 0 {
                parsed_header.body_source = "// @owner " + imply_owner + "\n" + collected.text
            }
            else {
                parsed_header.body_source = collected.text
            }
            functions = push(functions, parsed_header)
            found_fn = found_fn + 1
            has_pending_clr = false
            pending_main = false
            i = collected.next_index
            continue
        }
        i = i + 1
    }
    parsed.functions = functions
    if probe_legion {
        std.io.print_line("[v1-debug] parse_module found_fn=" + format("{}", found_fn))
        std.io.print_line("[v1-debug] parse_module functions_len=" + format("{}", parsed.functions.length() as i32))
    }
    return parsed
}

micro parse_modules_from_files(files: [utf8], file_count: usize) -> [ParsedModule] {
    # Pass file_count from caller — CLR has mis-read `[utf8].length()` on some params as 0.
    let mut modules: [ParsedModule] = []
    let mut i: usize = 0
    while i < file_count {
        let file_path: utf8 = files⁅i⁆
        i = i + 1
        if !std.io.file_exists(file_path) {
            continue
        }
        let content: utf8 = std.io.read_file_text(file_path)
        modules = push(modules, parse_module_source(content))
    }
    return modules
}

micro find_function(parsed: ParsedModule, name: utf8) -> ParsedFunction {
    let mut i: usize = 0
    while i < parsed.functions.length() {
        let item: ParsedFunction = parsed.functions⁅i⁆
        if item.name == name {
            return item
        }
        i = i + 1
    }
    return empty_parsed_function()
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
