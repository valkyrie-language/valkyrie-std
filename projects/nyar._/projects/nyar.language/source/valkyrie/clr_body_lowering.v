namespace nyar.language.valkyrie;

using std.io;

# LEGACY BYPASS — body_source → MSIL string emit.
# Preferred path: AST → HIR → MIR → ExecutableModule → nyar.emitter.clr
#   (see frontend_facts.v / clr_adapt.v).
# Flip `body_source_bypass_retired()` to true to fail-closed this entire file for bootstrap.
# Do NOT expand this bypass; isomorphic MIR coverage retires it.

structure BodyLowerResult {
    ok: bool
    error: utf8
    instructions: utf8
    locals_clause: utf8
    maxstack: i32
    # Monotonic label counter after this result (nested emitters must propagate).
    next_lab: i32
}

structure BodyLocal {
    name: utf8
    clr_type: utf8
    slot: i32
    is_arg: bool
}

micro body_lower_fail(message: utf8) -> BodyLowerResult {
    let mut msg: utf8 = message
    if msg.length() == 0 {
        msg = "empty-fail"
    }
    return BodyLowerResult {
        ok: false,
        error: msg,
        instructions: "",
        locals_clause: "",
        maxstack: 8,
        next_lab: 0
    }
}

# When true, all body_source→MSIL entry points fail-closed (force ExecutableModule emitter).
# Keep false until AST→HIR→MIR covers legion.tools bootstrap surface.
micro body_source_bypass_retired() -> bool {
    return false
}

micro body_source_bypass_retired_error() -> utf8 {
    return "FAIL-CLOSED: body_source→MSIL bypass retired; use MirModule→ExecutableModule→nyar.emitter"
}

micro body_lower_ok(instructions: utf8, locals_clause: utf8) -> BodyLowerResult {
    return BodyLowerResult {
        ok: true,
        error: "",
        instructions: instructions,
        locals_clause: locals_clause,
        maxstack: 16,
        next_lab: 0
    }
}

micro body_lower_ok_lab(instructions: utf8, locals_clause: utf8, next_lab: i32) -> BodyLowerResult {
    return BodyLowerResult {
        ok: true,
        error: "",
        instructions: instructions,
        locals_clause: locals_clause,
        maxstack: 16,
        next_lab: next_lab
    }
}

# --- Method-local MSIL label uniquify (loop vs join; not gap padding) ---

micro msil_trim_line(line: utf8) -> utf8 {
    let mut s: utf8 = line
    while s.length() > 0 {
        let c: utf8 = s.slice(0, 1)
        if c == " " || c == "\t" || c == "\r" {
            s = s.slice(1, s.length() - 1)
            continue
        }
        break
    }
    while s.length() > 0 {
        let c2: utf8 = s.slice(s.length() - 1, 1)
        if c2 == " " || c2 == "\t" || c2 == "\r" {
            s = s.slice(0, s.length() - 1)
            continue
        }
        break
    }
    return s
}

micro msil_line_indent(line: utf8) -> utf8 {
    let mut i: i32 = 0
    while i < line.length() {
        let c: utf8 = line.slice(i, 1)
        if c == " " || c == "\t" {
            i = i + 1
            continue
        }
        break
    }
    if i == 0 {
        return ""
    }
    return line.slice(0, i)
}

micro msil_label_def_name(line: utf8) -> utf8 {
    let t: utf8 = msil_trim_line(line)
    if t.length() < 2 || !t.ends_with(":") {
        return ""
    }
    let name: utf8 = t.slice(0, t.length() - 1)
    if name.length() == 0 || name.index_of(" ") >= 0 || name.index_of("\t") >= 0 {
        return ""
    }
    let c0: utf8 = name.slice(0, 1)
    if (c0 >= "A" && c0 <= "Z") || (c0 >= "a" && c0 <= "z") || c0 == "_" {
        return name
    }
    return ""
}

micro msil_is_branch_op(op: utf8) -> bool {
    if op == "br" || op == "brtrue" || op == "brfalse" || op == "beq" || op == "bne.un" {
        return true
    }
    if op == "bge" || op == "bgt" || op == "ble" || op == "blt" {
        return true
    }
    if op == "bge.un" || op == "bgt.un" || op == "ble.un" || op == "blt.un" {
        return true
    }
    if op == "leave" || op == "leave.s" {
        return true
    }
    return false
}

micro msil_branch_target(line: utf8) -> utf8 {
    let t: utf8 = msil_trim_line(line)
    let sp: i32 = t.index_of(" ")
    if sp <= 0 {
        return ""
    }
    let op: utf8 = t.slice(0, sp)
    if !msil_is_branch_op(op) {
        return ""
    }
    let rest: utf8 = t.slice(sp + 1, t.length() - sp - 1).trim()
    if rest.length() == 0 || rest.index_of(" ") >= 0 || rest.index_of("\t") >= 0 {
        return ""
    }
    return rest
}

micro msil_lab_map_find(names: [utf8], name: utf8) -> i32 {
    let mut i: usize = 0
    while i < names.length() {
        if names⁅i⁆ == name {
            return i as i32
        }
        i = i + 1
    }
    return -1
}

# Rewrite labels so each def/ref group is unique inside one method body.
# Loop labels (first sight = def) keep identity for back-edges; join labels
# (first sight = ref) open a new identity after their def completes.
micro uniquify_msil_labels(instr: utf8) -> utf8 {
    if instr.length() == 0 {
        return instr
    }
    # Pass 1: first sighting kind per name (1=def/loop, 0=ref/join).
    let mut kind_names: [utf8] = []
    let mut kind_loop: [i32] = []
    let mut i: i32 = 0
    let mut line_start: i32 = 0
    while i <= instr.length() {
        let at_end: bool = i >= instr.length()
        let is_nl: bool = false
        if !at_end {
            is_nl = instr.slice(i, 1) == "\n"
        }
        if at_end || is_nl {
            let count: i32 = i - line_start
            let mut line: utf8 = ""
            if count > 0 {
                line = instr.slice(line_start, count)
            }
            let def_n: utf8 = msil_label_def_name(line)
            let mut br_n: utf8 = ""
            if def_n.length() == 0 {
                br_n = msil_branch_target(line)
            }
            let mut sight: utf8 = def_n
            let mut is_def_sight: i32 = 1
            if sight.length() == 0 {
                sight = br_n
                is_def_sight = 0
            }
            if sight.length() > 0 && msil_lab_map_find(kind_names, sight) < 0 {
                kind_names = push(kind_names, sight)
                kind_loop = push(kind_loop, is_def_sight)
            }
            if at_end {
                break
            }
            i = i + 1
            line_start = i
            continue
        }
        i = i + 1
    }
    # Pass 2: rewrite.
    let mut bound_names: [utf8] = []
    let mut bound_uniqs: [utf8] = []
    let mut bound_done: [i32] = []
    let mut ctr: i32 = 0
    let mut out: utf8 = ""
    i = 0
    line_start = 0
    while i <= instr.length() {
        let at_end2: bool = i >= instr.length()
        let mut is_nl2: bool = false
        if !at_end2 {
            is_nl2 = instr.slice(i, 1) == "\n"
        }
        if at_end2 || is_nl2 {
            let count2: i32 = i - line_start
            let mut line2: utf8 = ""
            if count2 > 0 {
                line2 = instr.slice(line_start, count2)
            }
            let def2: utf8 = msil_label_def_name(line2)
            let mut br2: utf8 = ""
            if def2.length() == 0 {
                br2 = msil_branch_target(line2)
            }
            if def2.length() > 0 {
                let mut bi: i32 = msil_lab_map_find(bound_names, def2)
                let mut need_fresh: bool = bi < 0
                if bi >= 0 && bound_done⁅bi as usize⁆ == 1 {
                    need_fresh = true
                }
                if need_fresh {
                    ctr = ctr + 1
                    let uniq: utf8 = def2 + "_u" + format("{}", ctr)
                    if bi < 0 {
                        bound_names = push(bound_names, def2)
                        bound_uniqs = push(bound_uniqs, uniq)
                        bound_done = push(bound_done, 0)
                        bi = bound_names.length() as i32 - 1
                    }
                    else {
                        bound_uniqs = msil_utf8_set(bound_uniqs, bi, uniq)
                        bound_done = msil_i32_set(bound_done, bi, 0)
                    }
                }
                let use_u: utf8 = bound_uniqs⁅bi as usize⁆
                bound_done = msil_i32_set(bound_done, bi, 1)
                out = out + msil_line_indent(line2) + use_u + ":"
            }
            else if br2.length() > 0 {
                let ki2: i32 = msil_lab_map_find(kind_names, br2)
                let is_loop2: bool = ki2 >= 0 && kind_loop⁅ki2 as usize⁆ == 1
                let mut bi2: i32 = msil_lab_map_find(bound_names, br2)
                let mut need_fresh2: bool = bi2 < 0
                if bi2 >= 0 && bound_done⁅bi2 as usize⁆ == 1 && !is_loop2 {
                    need_fresh2 = true
                }
                if need_fresh2 {
                    ctr = ctr + 1
                    let uniq2: utf8 = br2 + "_u" + format("{}", ctr)
                    if bi2 < 0 {
                        bound_names = push(bound_names, br2)
                        bound_uniqs = push(bound_uniqs, uniq2)
                        bound_done = push(bound_done, 0)
                        bi2 = bound_names.length() as i32 - 1
                    }
                    else {
                        bound_uniqs = msil_utf8_set(bound_uniqs, bi2, uniq2)
                        bound_done = msil_i32_set(bound_done, bi2, 0)
                    }
                }
                let use_b: utf8 = bound_uniqs⁅bi2 as usize⁆
                let tline: utf8 = msil_trim_line(line2)
                let spb: i32 = tline.index_of(" ")
                let opb: utf8 = tline.slice(0, spb)
                out = out + msil_line_indent(line2) + opb + " " + use_b
            }
            else {
                out = out + line2
            }
            if at_end2 {
                break
            }
            out = out + "\n"
            i = i + 1
            line_start = i
            continue
        }
        i = i + 1
    }
    return out
}

micro msil_utf8_set(arr: [utf8], idx: i32, val: utf8) -> [utf8] {
    let mut out: [utf8] = []
    let mut i: usize = 0
    while i < arr.length() {
        if i == idx as usize {
            out = push(out, val)
        }
        else {
            out = push(out, arr⁅i⁆)
        }
        i = i + 1
    }
    return out
}

micro msil_i32_set(arr: [i32], idx: i32, val: i32) -> [i32] {
    let mut out: [i32] = []
    let mut i: usize = 0
    while i < arr.length() {
        if i == idx as usize {
            out = push(out, val)
        }
        else {
            out = push(out, arr⁅i⁆)
        }
        i = i + 1
    }
    return out
}

# Advance one codepoint inside a string literal. Skips full `\u{…}` so braces do not affect depth.
micro string_lit_advance(src: utf8, i: i32) -> i32 {
    if i >= src.length() {
        return i
    }
    let ch: utf8 = src.slice(i, 1)
    if ch == "\u{5c}" && i + 1 < src.length() {
        if i + 3 < src.length() && src.slice(i + 1, 2) == "u{" {
            let mut j: i32 = i + 3
            while j < src.length() && src.slice(j, 1) != "}" {
                j = j + 1
            }
            if j < src.length() {
                return j + 1
            }
            return src.length()
        }
        return i + 2
    }
    return i + 1
}

# Skip `# …` / `// …` to end of line (call only when not inside a string).
micro brace_scan_skip_line_comment(src: utf8, i: i32) -> i32 {
    let n: i32 = src.length()
    let mut j: i32 = i
    while j < n {
        if src.slice(j, 1) == "\n" {
            return j + 1
        }
        j = j + 1
    }
    return n
}

# First `{` outside strings / line comments / `\u{…}` escapes.
micro index_of_brace_outside_string(src: utf8) -> i32 {
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    while i < src.length() {
        let ch: utf8 = src.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(src, i)
            continue
        }
        if ch == "#" {
            i = brace_scan_skip_line_comment(src, i)
            continue
        }
        if ch == "/" && i + 1 < src.length() && src.slice(i + 1, 1) == "/" {
            i = brace_scan_skip_line_comment(src, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "{" {
            return i
        }
        i = i + 1
    }
    return -1
}

# Find matching `}` for `{` at open, ignoring braces inside strings / comments / `\u{…}`.
micro match_brace_close(src: utf8, open: i32) -> i32 {
    if open < 0 || open >= src.length() || src.slice(open, 1) != "{" {
        return -1
    }
    let mut depth: i32 = 0
    let mut i: i32 = open
    let mut in_str: utf8 = ""
    while i < src.length() {
        let ch: utf8 = src.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(src, i)
            continue
        }
        if ch == "#" {
            i = brace_scan_skip_line_comment(src, i)
            continue
        }
        if ch == "/" && i + 1 < src.length() && src.slice(i + 1, 1) == "/" {
            i = brace_scan_skip_line_comment(src, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "{" {
            depth = depth + 1
        }
        else if ch == "}" {
            depth = depth - 1
            if depth == 0 {
                return i
            }
        }
        i = i + 1
    }
    return -1
}

micro extract_function_inner_body(body_source: utf8) -> utf8 {
    # Prefer comment/string-aware open — bare `index_of("{")` hits `{` in `# … `{` …`.
    let open: i32 = index_of_brace_outside_string(body_source)
    if open < 0 {
        return ""
    }
    let close: i32 = match_brace_close(body_source, open)
    if close <= open + 1 {
        return ""
    }
    return body_source.slice(open + 1, close - open - 1)
}

micro find_local(locals: [BodyLocal], name: utf8) -> BodyLocal {
    let mut i: usize = 0
    while i < locals.length() {
        if locals⁅i⁆.name == name {
            return locals⁅i⁆
        }
        i = i + 1
    }
    return BodyLocal {
        name: "",
        clr_type: "",
        slot: -1,
        is_arg: false
    }
}

micro find_local_slot(locals: [BodyLocal], name: utf8) -> i32 {
    return find_local(locals, name).slot
}

micro clr_type_for_annotation(type_text: utf8) -> utf8 {
    return clr_type_for_annotation_with_structs(type_text, [])
}

micro append_ld_slot(msil: utf8, local: BodyLocal) -> utf8 {
    if local.slot < 0 {
        return msil
    }
    if local.is_arg {
        if local.slot == 0 {
            return append_msil_line(msil, "        ldarg.0")
        }
        if local.slot == 1 {
            return append_msil_line(msil, "        ldarg.1")
        }
        if local.slot == 2 {
            return append_msil_line(msil, "        ldarg.2")
        }
        if local.slot == 3 {
            return append_msil_line(msil, "        ldarg.3")
        }
        return append_msil_line(msil, "        ldarg.s " + format("{}", local.slot))
    }
    return append_ldloc_slot(msil, local.slot)
}

micro extract_body_owner_type(body_source: utf8) -> utf8 {
    let marker: utf8 = "// @owner "
    let at: i32 = body_source.index_of(marker)
    if at < 0 {
        return ""
    }
    let start: i32 = at + marker.length()
    let count: i32 = body_source.length() - start
    let after: utf8 = body_source.slice(start, count)
    let mut end: i32 = after.index_of("\n")
    if end < 0 {
        end = after.length()
    }
    return after.slice(0, end).trim()
}

micro extract_return_type_text(body_source: utf8) -> utf8 {
    # `) -> T` or multiline arrow form before the body brace.
    let mut at: i32 = body_source.index_of(") -> ")
    let mut after_start: i32 = -1
    if at >= 0 {
        after_start = at + 5
    }
    else {
        let arrow: i32 = body_source.index_of(" -> ")
        if arrow >= 0 {
            after_start = arrow + 4
        }
    }
    if after_start < 0 {
        let key2: utf8 = "): "
        let at2: i32 = body_source.index_of(key2)
        if at2 < 0 {
            return ""
        }
        after_start = at2 + key2.length()
    }
    let after: utf8 = body_source.slice(after_start, body_source.length() - after_start).trim()
    let mut end: i32 = 0
    while end < after.length() {
        let ch: utf8 = after.slice(end, 1)
        if ch == " " || ch == "{" || ch == "\t" || ch == "\r" || ch == "\n" {
            break
        }
        end = end + 1
    }
    return after.slice(0, end).trim()
}

micro parse_function_params(body_source: utf8, structs: [ParsedStruct]) -> [BodyLocal] {
    let mut params: [BodyLocal] = []
    let owner: utf8 = extract_body_owner_type(body_source)
    let micro_at: i32 = body_source.index_of("micro ")
    if micro_at < 0 {
        return params
    }
    let open: i32 = body_source.index_of("(")
    let close: i32 = body_source.index_of(")")
    if open < 0 || close <= open {
        return params
    }
    let clause: utf8 = body_source.slice(open + 1, close - open - 1).trim()
    if clause.length() == 0 {
        return params
    }
    let mut start: i32 = 0
    let mut arg_i: i32 = 0
    let mut i: i32 = 0
    while i <= clause.length() {
        let at_end: bool = i == clause.length()
        let ch: utf8 = ","
        if !at_end {
            ch = clause.slice(i, 1)
        }
        if at_end || ch == "," {
            let piece: utf8 = clause.slice(start, i - start).trim()
            if piece.length() > 0 {
                let mut pname: utf8 = ""
                let mut pty: utf8 = ""
                let colon: i32 = piece.index_of(":")
                if piece == "self" || piece == "mut self" {
                    pname = "self"
                    pty = owner
                    if pty.length() == 0 {
                        pty = "object"
                    }
                }
                else if colon > 0 {
                    pname = piece.slice(0, colon).trim()
                    if pname.starts_with("mut ") {
                        pname = pname.slice(4, pname.length() - 4).trim()
                    }
                    pty = piece.slice(colon + 1, piece.length() - colon - 1).trim()
                    if pty.starts_with("mut ") {
                        pty = pty.slice(4, pty.length() - 4).trim()
                    }
                    if pty == "Self" && owner.length() > 0 {
                        pty = owner
                    }
                }
                if pname.length() > 0 {
                    let mut clr: utf8 = clr_type_for_annotation_with_defs(pty, structs, submission.unite_defs)
                    if clr.length() == 0 && pty.length() > 0 {
                        if find_struct_def(structs, pty).name.length() > 0 || find_unite_def(submission.unite_defs, pty).name.length() > 0 {
                            clr = msil_class_ty(pty)
                        }
                        else {
                            clr = "object"
                        }
                    }
                    if clr.length() == 0 {
                        clr = "object"
                    }
                    params = push(params, BodyLocal {
                        name: pname,
                        clr_type: clr,
                        slot: arg_i,
                        is_arg: true
                    })
                    arg_i = arg_i + 1
                }
            }
            start = i + 1
        }
        i = i + 1
    }
    return params
}

micro msil_param_signature(params: [BodyLocal]) -> utf8 {
    if params.length() == 0 {
        return ""
    }
    let mut s: utf8 = ""
    let mut i: usize = 0
    while i < params.length() {
        if i > 0 {
            s = s + ", "
        }
        s = s + params⁅i⁆.clr_type + " '" + params⁅i⁆.name + "'"
        i = i + 1
    }
    return s
}

micro msil_param_types(params: [BodyLocal]) -> utf8 {
    if params.length() == 0 {
        return ""
    }
    let mut s: utf8 = ""
    let mut i: usize = 0
    while i < params.length() {
        if i > 0 {
            s = s + ", "
        }
        s = s + params⁅i⁆.clr_type
        i = i + 1
    }
    return s
}

micro last_index_of_text(text: utf8, needle: utf8) -> i32 {
    if needle.length() == 0 || text.length() < needle.length() {
        return -1
    }
    let mut i: i32 = text.length() - needle.length()
    while i >= 0 {
        if text.slice(i, needle.length()) == needle {
            return i
        }
        i = i - 1
    }
    return -1
}

# Matching `)` for `(` at open — string-aware, nested-paren safe.
# Outermost `recv.method(` open paren at depth 0 (not an inner `.length(`).
micro find_outer_method_call_open(expr: utf8) -> i32 {
    let e: utf8 = expr.trim()
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    let mut best: i32 = -1
    while i < e.length() {
        let ch: utf8 = e.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(e, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "(" || ch == "[" || ch == "⁅" {
            depth = depth + 1
            i = i + 1
            continue
        }
        if ch == ")" || ch == "]" || ch == "⁆" {
            depth = depth - 1
            i = i + 1
            continue
        }
        if depth == 0 && ch == "." {
            let mut j: i32 = i + 1
            while j < e.length() {
                let cj: utf8 = e.slice(j, 1)
                if !is_ident_continue_char(cj) {
                    break
                }
                j = j + 1
            }
            if j > i + 1 && j < e.length() && e.slice(j, 1) == "(" {
                best = j
            }
        }
        i = i + 1
    }
    return best
}

# True only for keyword `else`, not identifiers like `else_ok` / `elsewhere`.
micro is_else_keyword_at(text: utf8, j: i32) -> bool {
    if j < 0 || j + 4 > text.length() {
        return false
    }
    if text.slice(j, 4) != "else" {
        return false
    }
    if j + 4 >= text.length() {
        return true
    }
    let next: utf8 = text.slice(j + 4, 1)
    if is_ident_continue_char(next) {
        return false
    }
    return true
}

micro matching_close_paren(text: utf8, open: i32) -> i32 {
    if open < 0 || open >= text.length() || text.slice(open, 1) != "(" {
        return -1
    }
    let mut depth: i32 = 0
    let mut i: i32 = open
    let mut in_str: utf8 = ""
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(text, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "(" {
            depth = depth + 1
        }
        else if ch == ")" {
            depth = depth - 1
            if depth == 0 {
                return i
            }
        }
        i = i + 1
    }
    return -1
}

# First needle at paren-depth 0 (ignores matches inside `(…)` / strings).
micro index_of_at_paren_depth0(text: utf8, needle: utf8) -> i32 {
    if needle.length() == 0 {
        return -1
    }
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(text, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        # Match needle before depth bumps — otherwise `"⁅"` / `"["` never hit at depth 0.
        if depth == 0 && i + needle.length() <= text.length() && text.slice(i, needle.length()) == needle {
            return i
        }
        if ch == "(" || ch == "[" || ch == "⁅" {
            depth = depth + 1
            i = i + 1
            continue
        }
        if ch == ")" || ch == "]" || ch == "⁆" {
            depth = depth - 1
            i = i + 1
            continue
        }
        i = i + 1
    }
    return -1
}


micro last_index_of_at_paren_depth0(text: utf8, needle: utf8) -> i32 {
    if needle.length() == 0 {
        return -1
    }
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    let mut last: i32 = -1
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(text, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if depth == 0 && i + needle.length() <= text.length() && text.slice(i, needle.length()) == needle {
            last = i
        }
        if ch == "(" || ch == "[" || ch == "⁅" {
            depth = depth + 1
            i = i + 1
            continue
        }
        if ch == ")" || ch == "]" || ch == "⁆" {
            depth = depth - 1
            i = i + 1
            continue
        }
        i = i + 1
    }
    return last
}

micro unqualified_symbol(symbol: utf8) -> utf8 {
    let dot: i32 = last_index_of_text(symbol, ".")
    if dot < 0 {
        return symbol
    }
    return symbol.slice(dot + 1, symbol.length() - dot - 1)
}

micro parse_return_clr_type(body_source: utf8, returns_void: bool, structs: [ParsedStruct]) -> utf8 {
    if returns_void {
        return "void"
    }
    # `) -> T` on one line, or `)\n    -> T` when params wrap.
    let mut at: i32 = body_source.index_of(") -> ")
    let mut start_ty: i32 = -1
    if at >= 0 {
        start_ty = at + 5
    }
    else {
        let arrow: i32 = body_source.index_of("-> ")
        if arrow > 0 {
            # Prefer the arrow after the parameter list's closing `)`.
            let mut pi: i32 = arrow - 1
            while pi >= 0 {
                let chp: utf8 = body_source.slice(pi, 1)
                if chp == " " || chp == "\t" || chp == "\r" || chp == "\n" {
                    pi = pi - 1
                    continue
                }
                if chp == ")" {
                    start_ty = arrow + 3
                }
                break
            }
        }
    }
    let mut ty: utf8 = ""
    if start_ty >= 0 {
        let count_ty: i32 = body_source.length() - start_ty
        let after: utf8 = body_source.slice(start_ty, count_ty).trim()
        let mut end: i32 = 0
        let mut depth: i32 = 0
        while end < after.length() {
            let ch: utf8 = after.slice(end, 1)
            if ch == "<" {
                depth = depth + 1
            }
            else if ch == ">" {
                depth = depth - 1
            }
            else if depth == 0 && (ch == " " || ch == "{" || ch == "\t" || ch == "\r" || ch == "\n") {
                break
            }
            end = end + 1
        }
        ty = after.slice(0, end).trim()
    }
    if ty.length() == 0 {
        return "int32"
    }
    if ty == "unit" {
        return "void"
    }
    let clr: utf8 = clr_type_for_annotation_with_structs(ty, structs)
    if clr.length() == 0 {
        return "int32"
    }
    return clr
}

micro lookup_callee_return_clr(submission: FragmentSubmission, short_name: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.body_symbols.length() {
        if unqualified_symbol(submission.body_symbols⁅i⁆) == short_name {
            let body: utf8 = ""
            if i < submission.body_sources.length() {
                body = submission.body_sources⁅i⁆
            }
            let returns_void: bool = operation_is_void(submission, submission.body_symbols⁅i⁆)
            return parse_return_clr_type(body, returns_void, submission.struct_defs)
        }
        i = i + 1
    }
    return ""
}

micro lookup_callee_param_types(submission: FragmentSubmission, short_name: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.body_symbols.length() {
        if unqualified_symbol(submission.body_symbols⁅i⁆) == short_name {
            let body: utf8 = ""
            if i < submission.body_sources.length() {
                body = submission.body_sources⁅i⁆
            }
            let params: [BodyLocal] = parse_function_params(body, submission.struct_defs)
            return msil_param_types(params)
        }
        i = i + 1
    }
    return ""
}

micro resolve_callee_symbol(submission: FragmentSubmission, short_name: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.body_symbols.length() {
        if unqualified_symbol(submission.body_symbols⁅i⁆) == short_name {
            return submission.body_symbols⁅i⁆
        }
        i = i + 1
    }
    return short_name
}

micro split_call_args(arglist: utf8) -> [utf8] {
    let mut args: [utf8] = []
    let mut buf: utf8 = ""
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    let t: utf8 = arglist.trim()
    if t.length() == 0 {
        return args
    }
    while i < t.length() {
        let ch: utf8 = t.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                buf = buf + ch
                i = i + 1
                continue
            }
            let next: i32 = string_lit_advance(t, i)
            buf = buf + t.slice(i, next - i)
            i = next
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            buf = buf + ch
            i = i + 1
            continue
        }
        if ch == "(" || ch == "[" || ch == "⁅" || ch == "{" {
            depth = depth + 1
            buf = buf + ch
        }
        else if ch == ")" || ch == "]" || ch == "⁆" || ch == "}" {
            depth = depth - 1
            buf = buf + ch
        }
        else if ch == "," && depth == 0 {
            let piece: utf8 = buf.trim()
            if piece.length() > 0 {
                args = push(args, piece)
            }
            buf = ""
        }
        else {
            buf = buf + ch
        }
        i = i + 1
    }
    let tail: utf8 = buf.trim()
    if tail.length() > 0 {
        args = push(args, tail)
    }
    return args
}

micro looks_like_call_expr(expr: utf8) -> bool {
    let e: utf8 = expr.trim()
    # Do not treat `"path_join(" + x + ")"` as a call — first `(` may sit inside a string.
    if e.starts_with(dq()) || e.starts_with("'") || e.starts_with("'''") {
        return false
    }
    let mut open: i32 = index_of_at_paren_depth0(e, "(")
    if open <= 0 {
        open = e.index_of("(")
    }
    if open <= 0 {
        return false
    }
    let name: utf8 = e.slice(0, open).trim()
    if name.length() == 0 || name.contains(" ") || name.contains("=") {
        return false
    }
    if name.starts_with(dq()) || name.starts_with("'") {
        return false
    }
    if name.contains(".") {
        # std.io.print_line handled elsewhere
        return false
    }
    # Call expr must end at the matching close paren (allow trailing `;`).
    let close: i32 = matching_close_paren(e, open)
    if close <= open {
        return false
    }
    let after: utf8 = e.slice(close + 1, e.length() - close - 1).trim()
    return after.length() == 0 || after == ";"
}

micro emit_call_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    return emit_call_expr_hint(msil, expr, locals, submission, "")
}

micro emit_call_expr_hint(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission, sum_hint: utf8) -> BodyLowerResult {
    let mut e: utf8 = expr.trim()
    if e.ends_with(";") {
        e = e.slice(0, e.length() - 1).trim()
    }
    if e.starts_with("push(") {
        return body_lower_fail("push 仅支持赋值形式 arr = push(arr, x)： " + e)
    }
    # `panic("msg")` → throw Exception (match/unwrap arms).
    if e.starts_with("panic(") && e.ends_with(")") {
        let arg: utf8 = e.slice(6, e.length() - 7).trim()
        let ar: BodyLowerResult = emit_value_expr(msil, arg, locals, submission)
        if !ar.ok {
            return ar
        }
        let mut panic_msil: utf8 = append_msil_line(ar.instructions, "        newobj instance void [mscorlib]System.Exception::.ctor(string)")
        panic_msil = append_msil_line(panic_msil, "        throw")
        return body_lower_ok(panic_msil, "")
    }
    let open: i32 = e.index_of("(")
    let close: i32 = matching_close_paren(e, open)
    if open <= 0 || close <= open {
        return body_lower_fail("无法解析调用：" + expr)
    }
    let mut cname: utf8 = e.slice(0, open).trim()
    # `Utf8Text::from_bytes_unchecked` → resolve by method name (imply micros).
    let colons: i32 = cname.index_of("::")
    if colons >= 0 {
        cname = cname.slice(colons + 2, cname.length() - colons - 2).trim()
    }
    let arglist: utf8 = e.slice(open + 1, close - open - 1).trim()
    let args: [utf8] = split_call_args(arglist)
    if cname == "Fine" || cname == "Fail" {
        let sum: utf8 = nominal_type_name(sum_hint)
        if sum.length() == 0 || find_unite_def(submission.unite_defs, sum).name.length() == 0 {
            return body_lower_fail("Fine/Fail 缺少 unite 上下文（返回/注解类型）：" + expr)
        }
        let payload: utf8 = ""
        if args.length() == 1 {
            payload = args⁅0⁆
        }
        else if args.length() != 0 {
            return body_lower_fail("Fine/Fail 需要 0/1 参数：" + expr)
        }
        return emit_unite_variant_ctor(msil, cname, payload, sum, locals, submission)
    }
    if cname == "Some" {
        if args.length() != 1 {
            return body_lower_fail("Some 需要 1 参数：" + expr)
        }
        # Option erased to nullable ref — Some(x) is just x.
        return emit_stack_expr(msil, args⁅0⁆, locals, submission)
    }
    if cname == "None" {
        return body_lower_ok(append_msil_line(msil, "        ldnull"), "")
    }
    # von_parse_take_fail(parsed) → Fail payload or null (tag==1).
    if cname == "von_parse_take_fail" {
        if args.length() != 1 {
            return body_lower_fail("von_parse_take_fail 需要 1 参数：" + expr)
        }
        let pr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !pr.ok {
            return pr
        }
        # Unique per emission site (buffer length), not a fixed gap.
        let lab_n: i32 = pr.instructions.length() + 1
        let fine_l: utf8 = "VF" + format("{}", lab_n)
        let end_l: utf8 = "VE" + format("{}", lab_n)
        let mut acc: utf8 = pr.instructions
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonParseResult::tag")
        acc = append_msil_line(acc, "        ldc.i4.1")
        acc = append_msil_line(acc, "        bne.un " + fine_l)
        acc = append_msil_line(acc, "        ldfld object VonParseResult::payload")
        acc = append_msil_line(acc, "        castclass VonDiagnostic")
        acc = append_msil_line(acc, "        br " + end_l)
        acc = append_msil_line(acc, fine_l + ":")
        acc = append_msil_line(acc, "        pop")
        acc = append_msil_line(acc, "        ldnull")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    # von_as_text / von_as_bool / von_as_array / von_as_object — tag dispatch (bootstrap).
    if cname == "von_as_text" {
        if args.length() != 1 {
            return body_lower_fail("von_as_text 需要 1 参数：" + expr)
        }
        let pr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !pr.ok {
            return pr
        }
        let mut acc: utf8 = pr.instructions
        let lab_n: i32 = acc.length() + 1
        let end_l: utf8 = "VAT" + format("{}", lab_n)
        let ok_l: utf8 = "VAO" + format("{}", lab_n)
        # Text=0, Number=2, Name=3 → payload string; else ""
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonValue::tag")
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, "        beq " + ok_l)
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonValue::tag")
        acc = append_msil_line(acc, "        ldc.i4.2")
        acc = append_msil_line(acc, "        beq " + ok_l)
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonValue::tag")
        acc = append_msil_line(acc, "        ldc.i4.3")
        acc = append_msil_line(acc, "        beq " + ok_l)
        acc = append_msil_line(acc, "        pop")
        acc = append_msil_line(acc, "        ldstr " + dq() + dq())
        acc = append_msil_line(acc, "        br " + end_l)
        acc = append_msil_line(acc, ok_l + ":")
        acc = append_msil_line(acc, "        ldfld object VonValue::payload")
        acc = append_msil_line(acc, "        castclass string")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    if cname == "von_as_bool" {
        if args.length() != 1 {
            return body_lower_fail("von_as_bool 需要 1 参数：" + expr)
        }
        let pr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !pr.ok {
            return pr
        }
        let mut acc: utf8 = pr.instructions
        let lab_n: i32 = acc.length() + 1
        let end_l: utf8 = "VAB" + format("{}", lab_n)
        let miss_l: utf8 = "VAX" + format("{}", lab_n)
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonValue::tag")
        acc = append_msil_line(acc, "        ldc.i4.1")
        acc = append_msil_line(acc, "        bne.un " + miss_l)
        acc = append_msil_line(acc, "        ldfld object VonValue::payload")
        acc = append_msil_line(acc, "        unbox.any bool")
        acc = append_msil_line(acc, "        br " + end_l)
        acc = append_msil_line(acc, miss_l + ":")
        acc = append_msil_line(acc, "        pop")
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    if cname == "von_as_array" || cname == "von_as_object" {
        if args.length() != 1 {
            return body_lower_fail(cname + " 需要 1 参数：" + expr)
        }
        let want: i32 = 4
        let cast_ty: utf8 = "VonValue[]"
        if cname == "von_as_object" {
            want = 5
            cast_ty = "VonField[]"
        }
        let pr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !pr.ok {
            return pr
        }
        let mut acc: utf8 = pr.instructions
        let lab_n: i32 = acc.length() + 1
        let end_l: utf8 = "VAA" + format("{}", lab_n)
        let miss_l: utf8 = "VAN" + format("{}", lab_n)
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonValue::tag")
        acc = append_ldc_i4_digits(acc, format("{}", want))
        acc = append_msil_line(acc, "        bne.un " + miss_l)
        acc = append_msil_line(acc, "        ldfld object VonValue::payload")
        acc = append_msil_line(acc, "        castclass " + msil_cast_type(cast_ty))
        acc = append_msil_line(acc, "        br " + end_l)
        acc = append_msil_line(acc, miss_l + ":")
        acc = append_msil_line(acc, "        pop")
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, "        newarr " + cast_ty.slice(0, cast_ty.length() - 2))
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    # von_find_field(value, name) — Object fields linear search (bootstrap; body may be missing from fragment).
    if cname == "von_find_field" {
        if args.length() != 2 {
            return body_lower_fail("von_find_field 需要 2 参数：" + expr)
        }
        let mut obj_tag: i32 = find_unite_variant(find_unite_def(submission.unite_defs, "VonValue"), "Object").tag
        # ast.v order: Text, Flag, Number, Name, Array, Object, Empty — Object = 5 when scrape misses.
        if obj_tag < 0 {
            obj_tag = 5
        }
        let tmp_arr: BodyLocal = find_local(locals, "__clr_push_new")
        let tmp_i: BodyLocal = find_local(locals, "__clr_push_i")
        let tmp_n: BodyLocal = find_local(locals, "__clr_push_n")
        let tmp_s: BodyLocal = find_local(locals, "__clr_match_scrut")
        if tmp_arr.slot < 0 || tmp_i.slot < 0 || tmp_n.slot < 0 || tmp_s.slot < 0 {
            return body_lower_fail("von_find_field 缺少临时局部（需 match/push temps）")
        }
        let vr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !vr.ok {
            return vr
        }
        let nr: BodyLowerResult = emit_stack_expr(vr.instructions, args⁅1⁆, locals, submission)
        if !nr.ok {
            return nr
        }
        # Stack: value, field_name — stash name in match scrut as object via box? Keep name in push_n as… strings need ref local.
        # Reuse: stloc name into __clr_match_scrut (object) — strings are refs.
        let mut acc_vf: utf8 = nr.instructions
        acc_vf = append_stloc_slot(acc_vf, tmp_s.slot)
        # value still on stack
        let lab_n: i32 = acc_vf.length() + 1
        let miss_obj: utf8 = "VFZ" + format("{}", lab_n)
        let miss_loop: utf8 = "VFM" + format("{}", lab_n)
        let loop_l: utf8 = "VFL" + format("{}", lab_n)
        let found_l: utf8 = "VFF" + format("{}", lab_n)
        let end_l: utf8 = "VFE" + format("{}", lab_n)
        acc_vf = append_msil_line(acc_vf, "        dup")
        acc_vf = append_msil_line(acc_vf, "        ldfld int32 VonValue::tag")
        acc_vf = append_ldc_i4_digits(acc_vf, format("{}", obj_tag))
        acc_vf = append_msil_line(acc_vf, "        bne.un " + miss_obj)
        acc_vf = append_msil_line(acc_vf, "        ldfld object VonValue::payload")
        acc_vf = append_msil_line(acc_vf, "        castclass class VonField[]")
        acc_vf = append_stloc_slot(acc_vf, tmp_arr.slot)
        acc_vf = append_ldloc_slot(acc_vf, tmp_arr.slot)
        acc_vf = append_msil_line(acc_vf, "        ldlen")
        acc_vf = append_msil_line(acc_vf, "        conv.i4")
        acc_vf = append_stloc_slot(acc_vf, tmp_n.slot)
        acc_vf = append_msil_line(acc_vf, "        ldc.i4.0")
        acc_vf = append_stloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_msil_line(acc_vf, loop_l + ":")
        acc_vf = append_ldloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_ldloc_slot(acc_vf, tmp_n.slot)
        acc_vf = append_msil_line(acc_vf, "        bge " + miss_loop)
        acc_vf = append_ldloc_slot(acc_vf, tmp_arr.slot)
        acc_vf = append_ldloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_msil_line(acc_vf, "        ldelem.ref")
        acc_vf = append_msil_line(acc_vf, "        castclass VonField")
        acc_vf = append_msil_line(acc_vf, "        ldfld string VonField::name")
        acc_vf = append_ldloc_slot(acc_vf, tmp_s.slot)
        acc_vf = append_msil_line(acc_vf, "        castclass string")
        acc_vf = append_msil_line(acc_vf, "        call bool [mscorlib]System.String::op_Equality(string, string)")
        acc_vf = append_msil_line(acc_vf, "        brtrue " + found_l)
        acc_vf = append_ldloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_msil_line(acc_vf, "        ldc.i4.1")
        acc_vf = append_msil_line(acc_vf, "        add")
        acc_vf = append_stloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_msil_line(acc_vf, "        br " + loop_l)
        acc_vf = append_msil_line(acc_vf, found_l + ":")
        acc_vf = append_ldloc_slot(acc_vf, tmp_arr.slot)
        acc_vf = append_ldloc_slot(acc_vf, tmp_i.slot)
        acc_vf = append_msil_line(acc_vf, "        ldelem.ref")
        acc_vf = append_msil_line(acc_vf, "        castclass VonField")
        acc_vf = append_msil_line(acc_vf, "        ldfld class VonValue VonField::'value'")
        acc_vf = append_msil_line(acc_vf, "        br " + end_l)
        acc_vf = append_msil_line(acc_vf, miss_obj + ":")
        acc_vf = append_msil_line(acc_vf, "        pop")
        acc_vf = append_msil_line(acc_vf, miss_loop + ":")
        let empty_r: BodyLowerResult = emit_unite_variant_ctor(acc_vf, "Empty", "", "VonValue", locals, submission)
        if !empty_r.ok {
            return empty_r
        }
        acc_vf = empty_r.instructions
        acc_vf = append_msil_line(acc_vf, end_l + ":")
        return body_lower_ok(acc_vf, "")
    }
    # von_parse_take_fine(parsed) → Fine payload or null (tag==0).
    if cname == "von_parse_take_fine" {
        if args.length() != 1 {
            return body_lower_fail("von_parse_take_fine 需要 1 参数：" + expr)
        }
        let pr: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !pr.ok {
            return pr
        }
        let lab_n: i32 = pr.instructions.length() + 1
        let fail_l: utf8 = "VN" + format("{}", lab_n)
        let end_l: utf8 = "VO" + format("{}", lab_n)
        let mut acc: utf8 = pr.instructions
        acc = append_msil_line(acc, "        dup")
        acc = append_msil_line(acc, "        ldfld int32 VonParseResult::tag")
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, "        bne.un " + fail_l)
        acc = append_msil_line(acc, "        ldfld object VonParseResult::payload")
        # Payload remains as object / cast by let annotation at store site.
        acc = append_msil_line(acc, "        br " + end_l)
        acc = append_msil_line(acc, fail_l + ":")
        acc = append_msil_line(acc, "        pop")
        acc = append_msil_line(acc, "        ldnull")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    if cname == "Empty" || cname == "Text" || cname == "Flag" || cname == "Number" || cname == "Name" || cname == "Array" || cname == "Object" {
        let mut sum_v: utf8 = nominal_type_name(sum_hint)
        if sum_v.length() == 0 {
            sum_v = "VonValue"
        }
        let payload: utf8 = ""
        if args.length() == 1 {
            payload = args⁅0⁆
        }
        else if args.length() != 0 {
            return body_lower_fail(cname + " 需要 0/1 参数：" + expr)
        }
        return emit_unite_variant_ctor(msil, cname, payload, sum_v, locals, submission)
    }
    # format("{}", x) → Convert.ToString / identity string
    if cname == "format" {
        if args.length() != 2 {
            return body_lower_fail("format 需要两参数：" + expr)
        }
        let fmt: utf8 = args⁅0⁆.trim()
        if fmt == dq() + "{}" + dq() {
            let ar: BodyLowerResult = emit_stack_expr(msil, args⁅1⁆, locals, submission)
            if !ar.ok {
                return ar
            }
            # Prefer int32 ToString; also works after box for refs via Object.ToString.
            let mut acc_f: utf8 = ar.instructions
            acc_f = append_msil_line(acc_f, "        call string [mscorlib]System.Convert::ToString(int32)")
            return body_lower_ok(acc_f, "")
        }
        return body_lower_fail("format 模板尚不支持：" + fmt)
    }
    # Tiny path helpers often missing from fragment symbols — expand inline.
    if cname == "compile_plan_snapshot_path" || cname == "backend_execution_snapshot_path" || cname == "backend_execution_result_snapshot_path" {
        if args.length() != 1 {
            return body_lower_fail(cname + " 需要 1 参数：" + expr)
        }
        let mut leaf: utf8 = "compile-plan.txt"
        if cname == "backend_execution_snapshot_path" {
            leaf = "backend-request.txt"
        }
        if cname == "backend_execution_result_snapshot_path" {
            leaf = "backend-result.txt"
        }
        return emit_call_expr_hint(msil, "path_join(" + args⁅0⁆ + ", " + dq() + leaf + dq() + ")", locals, submission, sum_hint)
    }
    # path_join(base, child) — string concat with `/` (bootstrap intrinsic).
    if cname == "path_join" {
        if args.length() != 2 {
            return body_lower_fail("path_join 需要 2 参数：" + expr)
        }
        let a0: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !a0.ok {
            return a0
        }
        let mut acc_pj: utf8 = append_msil_line(a0.instructions, "        ldstr " + dq() + "/" + dq())
        let a1: BodyLowerResult = emit_stack_expr(acc_pj, args⁅1⁆, locals, submission)
        if !a1.ok {
            return a1
        }
        # Stack: base, "/", child
        return body_lower_ok(append_msil_line(a1.instructions, "        call string [mscorlib]System.String::Concat(string, string, string)"), "")
    }
    if cname == "__array_len" {
        if args.length() != 1 {
            return body_lower_fail("__array_len 需要 1 参数：" + expr)
        }
        let ar: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !ar.ok {
            return ar
        }
        let mut acc_al: utf8 = append_msil_line(ar.instructions, "        ldlen")
        acc_al = append_msil_line(acc_al, "        conv.i4")
        return body_lower_ok(acc_al, "")
    }
    # String.get_Chars is instance — not static String::get_Chars(string, int32).
    if cname == "__clr_str_char" && args.length() == 2 {
        let s_r: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !s_r.ok {
            return s_r
        }
        let i_r: BodyLowerResult = emit_int_expr(s_r.instructions, args⁅1⁆, locals, submission)
        if !i_r.ok {
            return i_r
        }
        let mut acc_ch: utf8 = append_msil_line(i_r.instructions, "        callvirt instance char [mscorlib]System.String::get_Chars(int32)")
        acc_ch = append_msil_line(acc_ch, "        conv.i4")
        return body_lower_ok(acc_ch, "")
    }
    # Thread.Sleep(int32) — do not go through string-typed extern call path.
    if (cname == "clr_thread_sleep" || cname == "smoke_thread_sleep") && args.length() == 1 {
        let ms_r: BodyLowerResult = emit_int_expr(msil, args⁅0⁆, locals, submission)
        if !ms_r.ok {
            return ms_r
        }
        return body_lower_ok(append_msil_line(ms_r.instructions, "        call void [mscorlib]System.Threading.Thread::Sleep(int32)"), "")
    }
    let mut acc: utf8 = msil
    let mut ai: usize = 0
    while ai < args.length() {
        let a: utf8 = args⁅ai⁆
        let ar: BodyLowerResult = emit_stack_expr(acc, a, locals, submission)
        if !ar.ok {
            return ar
        }
        acc = ar.instructions
        ai = ai + 1
    }
    let ret_clr: utf8 = lookup_callee_return_clr(submission, cname)
    if ret_clr.length() == 0 {
        # [clr(...)] extern — not in body_symbols; emit BCL call from import binding.
        let mut bi: usize = 0
        while bi < submission.external_import_bindings.length() {
            let binding: ExternalImportBinding = submission.external_import_bindings⁅bi⁆
            if unqualified_symbol(binding.symbol) == cname && binding.link.locator_segments.length() >= 3 {
                let assembly: utf8 = binding.link.locator_segments⁅0⁆
                let owner: utf8 = binding.link.locator_segments⁅1⁆
                let method_name: utf8 = binding.link.locator_segments⁅2⁆
                # Instance String.get_Chars(int32) — first arg is `this`.
                if method_name == "get_Chars" && args.length() == 2 {
                    let mut acc_gc: utf8 = msil
                    let s0: BodyLowerResult = emit_stack_expr(acc_gc, args⁅0⁆, locals, submission)
                    if !s0.ok {
                        return s0
                    }
                    let i0: BodyLowerResult = emit_int_expr(s0.instructions, args⁅1⁆, locals, submission)
                    if !i0.ok {
                        return i0
                    }
                    acc_gc = append_msil_line(i0.instructions, "        callvirt instance char [" + assembly + "]" + owner + "::get_Chars(int32)")
                    acc_gc = append_msil_line(acc_gc, "        conv.i4")
                    return body_lower_ok(acc_gc, "")
                }
                let mut ptypes_e: utf8 = ""
                let mut pi: usize = 0
                while pi < args.length() {
                    if pi > 0 {
                        ptypes_e = ptypes_e + ", "
                    }
                    ptypes_e = ptypes_e + "string"
                    pi = pi + 1
                }
                # Process.Start → Process; unit callers discard. Other externs treated as void.
                if owner.ends_with("Process") && method_name == "Start" {
                    acc = append_msil_line(acc, "        call class [" + assembly + "]" + owner + " [" + assembly + "]" + owner + "::" + method_name + "(" + ptypes_e + ")")
                    acc = append_msil_line(acc, "        pop")
                    return body_lower_ok(acc, "")
                }
                acc = append_msil_line(acc, "        call void [" + assembly + "]" + owner + "::" + method_name + "(" + ptypes_e + ")")
                return body_lower_ok(acc, "")
            }
            bi = bi + 1
        }
        return body_lower_fail("未知调用目标（无 body/返回类型）：" + cname)
    }
    let ptypes: utf8 = lookup_callee_param_types(submission, cname)
    if args.length() > 0 && ptypes.length() == 0 {
        return body_lower_fail("调用参数类型未知：" + cname)
    }
    let callee_sym: utf8 = resolve_callee_symbol(submission, cname)
    return body_lower_ok(append_msil_line(acc, "        call " + ret_clr + " " + msil_method_name(callee_sym) + "(" + ptypes + ")"), "")
}

# Lower a stack value: nested call / if / plain expr (field paths, literals, …).
micro emit_stack_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    return emit_stack_expr_hint(msil, expr, locals, submission, "")
}

# Resolve bare nullary unite variant name (LeftBrace, EndOfFile, Empty, …) → sum type.
micro find_unite_for_nullary_variant(unites: [ParsedUnite], variant: utf8) -> utf8 {
    let mut i: usize = 0
    while i < unites.length() {
        let u: ParsedUnite = unites⁅i⁆
        let v: ParsedUniteVariant = find_unite_variant(u, variant)
        if v.tag >= 0 && v.payload_type.length() == 0 {
            return u.name
        }
        i = i + 1
    }
    return ""
}

micro emit_stack_expr_hint(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission, sum_hint: utf8) -> BodyLowerResult {
    let e: utf8 = expr.trim()
    if looks_like_call_expr(e) {
        return emit_call_expr_hint(msil, e, locals, submission, sum_hint)
    }
    let se0: BodyLowerResult = try_emit_string_equality(msil, e, locals, submission)
    if se0.ok {
        return se0
    }
    if e.starts_with("if ") {
        return emit_if_expr(msil, e, locals, submission, 9000)
    }
    # Bare nullary unite: `LeftBrace` / `EndOfFile` / `Empty`
    if e.index_of(" ") < 0 && e.index_of(".") < 0 && e.index_of("(") < 0 && e.length() > 0 {
        let mut sum: utf8 = nominal_type_name(sum_hint)
        if sum.length() == 0 {
            sum = find_unite_for_nullary_variant(submission.unite_defs, e)
        }
        if sum.length() > 0 && find_unite_variant(find_unite_def(submission.unite_defs, sum), e).tag >= 0 {
            return emit_unite_variant_ctor(msil, e, "", sum, locals, submission)
        }
    }
    if looks_like_struct_literal(e) {
        return emit_struct_literal(msil, e, locals, submission)
    }
    return emit_value_expr(msil, e, locals, submission)
}

micro append_push_temps(lets: [BodyLocal], body_source: utf8) -> [BodyLocal] {
    let mut out: [BodyLocal] = lets
    let mut next: i32 = 0
    let mut i: usize = 0
    while i < out.length() {
        if out⁅i⁆.slot + 1 > next {
            next = out⁅i⁆.slot + 1
        }
        i = i + 1
    }
    if (body_source.contains("match ") || body_source.contains("von_find_field(")) && find_local_slot(out, "__clr_match_scrut") < 0 {
        out = push(out, BodyLocal {
            name: "__clr_match_scrut",
            clr_type: "object",
            slot: next,
            is_arg: false
        })
        next = next + 1
    }
    if body_source.contains("loop ") && find_local_slot(out, "__clr_loop_i") < 0 {
        out = push(out, BodyLocal {
            name: "__clr_loop_i",
            clr_type: "int32",
            slot: next,
            is_arg: false
        })
        next = next + 1
    }
    # Always reserve push temps — `contains("push(")` can miss when body scrape is truncated.
    if find_local_slot(out, "__clr_push_new") >= 0 {
        return out
    }
    out = push(out, BodyLocal {
        name: "__clr_push_new",
        clr_type: "object",
        slot: next,
        is_arg: false
    })
    out = push(out, BodyLocal {
        name: "__clr_push_i",
        clr_type: "int32",
        slot: next + 1,
        is_arg: false
    })
    out = push(out, BodyLocal {
        name: "__clr_push_n",
        clr_type: "int32",
        slot: next + 2,
        is_arg: false
    })
    return out
}

micro newarr_opcode_for_clr_array(clr_array: utf8) -> utf8 {
    let t: utf8 = clr_array.trim()
    if t == "string[]" {
        return "        newarr [mscorlib]System.String\n"
    }
    if t == "object[]" {
        return "        newarr [mscorlib]System.Object\n"
    }
    if t == "uint8[]" {
        return "        newarr [mscorlib]System.Byte\n"
    }
    if t == "int32[]" {
        return "        newarr [mscorlib]System.Int32\n"
    }
    if t.starts_with("class ") && t.ends_with("[]") {
        let inner: utf8 = t.slice(6, t.length() - 6).trim()
        if inner.ends_with("[]") {
            let elem: utf8 = inner.slice(0, inner.length() - 2).trim()
            return "        newarr " + elem + "\n"
        }
    }
    if t.ends_with("[]") {
        let elem: utf8 = t.slice(0, t.length() - 2).trim()
        return "        newarr " + elem + "\n"
    }
    return ""
}

# `dest = push(src, x)`. Empty dest → leave new array on stack (`return push(...)`).
micro emit_string_array_push(dest: utf8, src: utf8, value_expr: utf8, locals: [BodyLocal], lab: i32, submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let tmp_new: BodyLocal = find_local(locals, "__clr_push_new")
    let tmp_i: BodyLocal = find_local(locals, "__clr_push_i")
    let tmp_n: BodyLocal = find_local(locals, "__clr_push_n")
    if tmp_new.slot < 0 || tmp_i.slot < 0 || tmp_n.slot < 0 {
        return body_lower_fail("push 缺少临时局部")
    }
    let src_l: BodyLocal = find_local(locals, src)
    let mut arr_clr: utf8 = ""
    let mut load_arr: utf8 = ""
    if src_l.slot >= 0 && src_l.clr_type.ends_with("[]") {
        arr_clr = src_l.clr_type
        load_arr = append_ld_slot("", src_l)
    }
    else if src.contains(".") && src.index_of("⁅") < 0 && src.index_of("[") < 0 {
        let loaded: PathLoadResult = emit_load_path("", src, locals, structs)
        if !loaded.ok {
            if loaded.error.starts_with("soft:") {
                return body_lower_fail("push 路径失败：" + src)
            }
            return body_lower_fail(loaded.error)
        }
        if !loaded.result_type.ends_with("[]") {
            return body_lower_fail("push 源需为数组：" + src + " / " + loaded.result_type)
        }
        arr_clr = loaded.result_type
        load_arr = loaded.instructions
    }
    else {
        return body_lower_fail("push 源需为数组：" + src)
    }
    # Infer dest store kind; empty dest leaves result on evaluation stack.
    let dest_l: BodyLocal = find_local(locals, dest)
    let mut store_field: bool = false
    if dest.length() > 0 {
        if dest_l.slot >= 0 && dest_l.clr_type.ends_with("[]") {
            store_field = false
        }
        else if dest.contains(".") && dest.index_of("⁅") < 0 && dest.index_of("[") < 0 {
            store_field = true
        }
        else if dest_l.slot >= 0 {
            # Fresh local may still be untyped string[] from let — allow store.
            store_field = false
        }
        else {
            return body_lower_fail("push 目标需为数组局部或字段：" + dest)
        }
    }
    let newarr: utf8 = newarr_opcode_for_clr_array(arr_clr)
    if newarr.length() == 0 {
        return body_lower_fail("push 无法 newarr：" + arr_clr)
    }
    let mut ld_elem: utf8 = "        ldelem.ref\n"
    let mut st_elem: utf8 = "        stelem.ref\n"
    if arr_clr == "uint8[]" {
        ld_elem = "        ldelem.u1\n"
        st_elem = "        stelem.i1\n"
    }
    else if arr_clr == "int32[]" {
        ld_elem = "        ldelem.i4\n"
        st_elem = "        stelem.i4\n"
    }
    let loop_l: utf8 = "P" + format("{}", lab)
    let done_l: utf8 = "Q" + format("{}", lab)
    let mut parts: [utf8] = []
    parts = push(parts, load_arr)
    parts = push(parts, "        ldlen\n")
    parts = push(parts, "        conv.i4\n")
    parts = push(parts, append_stloc_slot("", tmp_n.slot))
    parts = push(parts, append_ldloc_slot("", tmp_n.slot))
    parts = push(parts, "        ldc.i4.1\n")
    parts = push(parts, "        add\n")
    parts = push(parts, newarr)
    parts = push(parts, append_stloc_slot("", tmp_new.slot))
    parts = push(parts, "        ldc.i4.0\n")
    parts = push(parts, append_stloc_slot("", tmp_i.slot))
    parts = push(parts, loop_l + ":\n")
    parts = push(parts, append_ldloc_slot("", tmp_i.slot))
    parts = push(parts, append_ldloc_slot("", tmp_n.slot))
    parts = push(parts, "        bge " + done_l + "\n")
    parts = push(parts, append_ldloc_slot("", tmp_new.slot))
    parts = push(parts, append_ldloc_slot("", tmp_i.slot))
    parts = push(parts, load_arr)
    parts = push(parts, append_ldloc_slot("", tmp_i.slot))
    parts = push(parts, ld_elem)
    parts = push(parts, st_elem)
    parts = push(parts, append_ldloc_slot("", tmp_i.slot))
    parts = push(parts, "        ldc.i4.1\n")
    parts = push(parts, "        add\n")
    parts = push(parts, append_stloc_slot("", tmp_i.slot))
    parts = push(parts, "        br " + loop_l + "\n")
    parts = push(parts, done_l + ":\n")
    parts = push(parts, append_ldloc_slot("", tmp_new.slot))
    parts = push(parts, append_ldloc_slot("", tmp_n.slot))
    let mut vr: BodyLowerResult = body_lower_fail("")
    if looks_like_struct_literal(value_expr) {
        vr = emit_struct_literal("", value_expr, locals, submission)
    }
    else {
        vr = emit_stack_expr("", value_expr, locals, submission)
    }
    if !vr.ok {
        return vr
    }
    parts = push(parts, vr.instructions)
    parts = push(parts, st_elem)
    if dest.length() == 0 {
        parts = push(parts, append_ldloc_slot("", tmp_new.slot))
    }
    else if store_field {
        let dot: i32 = last_index_of_text(dest, ".")
        let obj_path: utf8 = dest.slice(0, dot).trim()
        let field_name: utf8 = dest.slice(dot + 1, dest.length() - dot - 1).trim()
        let obj_loaded: PathLoadResult = emit_load_path("", obj_path, locals, structs)
        if !obj_loaded.ok {
            return body_lower_fail(obj_loaded.error)
        }
        let mut type_name: utf8 = obj_loaded.result_type.trim()
        if type_name.starts_with("class") {
            type_name = type_name.slice(5, type_name.length() - 5).trim()
        }
        parts = push(parts, obj_loaded.instructions)
        parts = push(parts, append_ldloc_slot("", tmp_new.slot))
        parts = push(parts, "        stfld " + arr_clr + " " + type_name + "::" + msil_id(field_name) + "\n")
    }
    else {
        parts = push(parts, append_ldloc_slot("", tmp_new.slot))
        parts = push(parts, append_stloc_slot("", dest_l.slot))
    }
    return body_lower_ok_lab(join_msil_parts(parts), "", lab + 1)
}

micro decode_v_string_content(lit: utf8) -> utf8 {
    # Decode V / C-style escapes in string literal *contents* (no surrounding quotes).
    # Short `\n`/`\t`/`\r` MUST work: seed previously dropped nested short-escape arms,
    # leaving only `\u{…}` — lex then compared whitespace to backslash+n and von failed.
    # Keep this flat (few nest levels) so seed/v1 both retain every arm.
    let mut out: utf8 = ""
    let mut i: i32 = 0
    let bs: utf8 = "\\"
    while i < lit.length() {
        let ch0: utf8 = lit.slice(i, 1)
        if ch0 != bs || i + 1 >= lit.length() {
            out = out + ch0
            i = i + 1
            continue
        }
        # `\u{HH…}` first so `\u` is not treated as an unknown short escape.
        if i + 3 < lit.length() && lit.slice(i, 3) == "\\u{" {
            let mut j: i32 = i + 3
            let mut hex: utf8 = ""
            while j < lit.length() && lit.slice(j, 1) != "}" {
                hex = hex + lit.slice(j, 1)
                j = j + 1
            }
            if j < lit.length() && lit.slice(j, 1) == "}" {
                if hex == "22" {
                    out = out + dq()
                }
                else if hex == "27" {
                    # apostrophe — required for msil_method_name / keyword quoting
                    out = out + "\u{27}"
                }
                else if hex == "2045" {
                    out = out + "⁅"
                }
                else if hex == "2046" {
                    out = out + "⁆"
                }
                else if hex == "5c" || hex == "5C" {
                    out = out + bs
                }
                else if hex == "0a" || hex == "0A" {
                    out = out + "\u{0a}"
                }
                else if hex == "0d" || hex == "0D" {
                    out = out + "\u{0d}"
                }
                else if hex == "09" {
                    out = out + "\u{09}"
                }
                else {
                    out = out + lit.slice(i, j - i + 1)
                }
                i = j + 1
                continue
            }
        }
        let esc: utf8 = lit.slice(i + 1, 1)
        if esc == "n" {
            out = out + "\u{0a}"
        }
        else if esc == "t" {
            out = out + "\u{09}"
        }
        else if esc == "r" {
            out = out + "\u{0d}"
        }
        else if esc == bs {
            out = out + bs
        }
        else if esc == dq() {
            out = out + dq()
        }
        else if esc == "'" {
            out = out + "'"
        }
        else {
            out = out + esc
        }
        i = i + 2
    }
    return out
}

micro strip_match_arch_else(text: utf8) -> utf8 {
    # `<% match arch %> <% case … %> … <% else %> BODY <% end %>` → BODY (CLR bootstrap).
    let mut out: utf8 = ""
    let mut i: i32 = 0
    while i < text.length() {
        if i + 16 <= text.length() && text.slice(i, 16) == "<% match arch %>" {
            let mut epos: i32 = -1
            let mut j: i32 = i
            while j + 10 <= text.length() {
                if text.slice(j, 10) == "<% else %>" {
                    epos = j
                    break
                }
                j = j + 1
            }
            let mut endpos: i32 = -1
            if epos >= 0 {
                let mut k: i32 = epos + 10
                while k + 9 <= text.length() {
                    if text.slice(k, 9) == "<% end %>" {
                        endpos = k
                        break
                    }
                    k = k + 1
                }
            }
            if epos >= 0 && endpos > epos {
                let body: utf8 = text.slice(epos + 10, endpos - epos - 10)
                out = out + body
                i = endpos + 9
                continue
            }
            # Malformed — skip the opening tag only.
            i = i + 16
            continue
        }
        out = out + text.slice(i, 1)
        i = i + 1
    }
    return out
}

micro hex2_u8(b: i32) -> utf8 {
    let hexd: utf8 = "0123456789ABCDEF"
    # Avoid `b / 16` — body→MSIL int `/` still fail-closed in v1.
    let mut hi: i32 = 0
    let mut rest: i32 = b
    while rest >= 16 {
        hi = hi + 1
        rest = rest - 16
    }
    let mut out: utf8 = hexd.slice(hi, 1)
    out = out + hexd.slice(rest, 1)
    return out
}

# UTF-16LE byte pair for one BMP char (ASCII / quill / '?').
micro utf16le_hex_bmp(ch: utf8) -> utf8 {
    # Index quills — must survive Framework ilasm (raw UTF-8 in ldstr "…" fails).
    if ch == "⁅" {
        return "45 20"
    }
    if ch == "⁆" {
        return "46 20"
    }
    if ch == "\u{09}" {
        return "09 00"
    }
    if ch == "\u{0a}" {
        return "0A 00"
    }
    if ch == "\u{0d}" {
        return "0D 00"
    }
    # Printable ASCII 32..126 in code order (index 0 → 32).
    let mut map: utf8 = " !"
    map = map + dq()
    map = map + "#$%&"
    map = map + "\u{27}"
    map = map + "()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
    map = map + "\u{5c}"
    map = map + "]^_"
    map = map + "\u{60}"
    map = map + "abcdefghijklmnopqrstuvwxyz"
    map = map + "{"
    map = map + "|"
    map = map + "}"
    map = map + "~"
    let idx: i32 = map.index_of(ch)
    if idx >= 0 {
        let mut hx: utf8 = hex2_u8(idx + 32)
        hx = hx + " 00"
        return hx
    }
    return "3F 00"
}

micro msil_quote_string(content: utf8) -> utf8 {
    # ASCII ldstr "…" for Framework ilasm. Quills (U+2045/U+2046) cannot appear as
    # raw UTF-8 inside quotes — emit `ldstr bytearray (UTF-16LE…)` when present.
    # Other non-ASCII (CJK) scrub to '?' so ilasm never sees them in quoted form.
    let decoded: utf8 = decode_v_string_content(content)
    let mut ascii: utf8 = "\u{09}\u{0a}\u{0d} !#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{}~"
    ascii = ascii + dq()
    ascii = ascii + "\u{5c}"
    ascii = ascii + "\u{27}"
    ascii = ascii + "\u{60}"
    ascii = ascii + "|"
    let mut esc: utf8 = ""
    let mut ba: utf8 = ""
    let mut has_quill: bool = false
    let mut i: i32 = 0
    let bs: utf8 = "\\"
    while i < decoded.length() {
        let ch: utf8 = decoded.slice(i, 1)
        if ch == "⁅" || ch == "⁆" {
            has_quill = true
        }
        if ch == bs {
            esc = esc + bs + bs
        }
        else if ch == dq() {
            esc = esc + bs + dq()
        }
        else if ch == "\u{0a}" {
            esc = esc + bs + "n"
        }
        else if ch == "\u{09}" {
            esc = esc + bs + "t"
        }
        else if ch == "\u{0d}" {
            esc = esc + bs + "r"
        }
        else if ascii.contains(ch) {
            esc = esc + ch
        }
        else if ch == "⁅" || ch == "⁆" {
            esc = esc + "?"
        }
        else {
            esc = esc + "?"
        }
        if ba.length() > 0 {
            ba = ba + " "
        }
        ba = ba + utf16le_hex_bmp(ch)
        i = i + 1
    }
    if has_quill {
        let mut out_ba: utf8 = "        ldstr bytearray ("
        out_ba = out_ba + ba
        out_ba = out_ba + ")"
        return out_ba
    }
    # Stepwise concat — `"        ldstr " + dq() + esc + dq()` collapses to bare `ldstr `.
    let mut out: utf8 = "        ldstr "
    out = out + dq()
    out = out + esc
    out = out + dq()
    return out
}

# Index of closing `"` for a double-quoted literal starting at expr[0], or -1.
# Does not treat `"a" + b + "c"` as one literal (ends_with('"') is not enough).
micro string_literal_close_index(expr: utf8) -> i32 {
    if expr.length() < 2 || !expr.starts_with(dq()) {
        return -1
    }
    let mut i: i32 = 1
    while i < expr.length() {
        let ch: utf8 = expr.slice(i, 1)
        if ch == "\u{5c}" && i + 1 < expr.length() {
            i = string_lit_advance(expr, i)
            continue
        }
        if ch == dq() {
            return i
        }
        i = i + 1
    }
    return -1
}

micro is_string_literal_expr(expr: utf8) -> bool {
    let e: utf8 = expr.trim()
    # V triple-quote: '''"''' / '''x''' — whole expr must be one literal.
    if e.length() >= 6 && e.starts_with("'''") {
        let mut i: i32 = 3
        while i + 2 < e.length() {
            if e.slice(i, 3) == "'''" {
                return i + 3 == e.length()
            }
            i = i + 1
        }
        return false
    }
    if e.length() >= 2 && e.starts_with(dq()) {
        let close: i32 = string_literal_close_index(e)
        return close >= 0 && close + 1 == e.length()
    }
    return false
}

# Bare decimal int token (`0`, `12`, `-1`) — not field paths / calls.
micro is_int_literal_token(expr: utf8) -> bool {
    let e: utf8 = expr.trim()
    if e.length() == 0 {
        return false
    }
    let mut i: i32 = 0
    if e.slice(0, 1) == "-" {
        if e.length() == 1 {
            return false
        }
        i = 1
    }
    while i < e.length() {
        let ch: utf8 = e.slice(i, 1)
        if ch < "0" || ch > "9" {
            return false
        }
        i = i + 1
    }
    return true
}

micro emit_string_literal_expr(msil: utf8, expr: utf8) -> BodyLowerResult {
    let e: utf8 = expr.trim()
    if e.length() >= 6 && e.starts_with("'''") && e.ends_with("'''") {
        let lit: utf8 = e.slice(3, e.length() - 6)
        return body_lower_ok(msil + msil_quote_string(lit) + "\n", "")
    }
    if e.length() >= 2 && e.starts_with(dq()) && e.ends_with(dq()) {
        let lit: utf8 = e.slice(1, e.length() - 2)
        return body_lower_ok(msil + msil_quote_string(lit) + "\n", "")
    }
    return body_lower_fail("非字符串字面量：" + expr)
}

micro try_emit_string_equality(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let e: utf8 = expr.trim()
    let mut negate: bool = false
    let mut eq: i32 = e.index_of(" == ")
    if eq <= 0 {
        eq = e.index_of(" != ")
        if eq <= 0 {
            return body_lower_fail("soft:seq-no-op")
        }
        negate = true
    }
    let left: utf8 = e.slice(0, eq).trim()
    let right: utf8 = e.slice(eq + 4, e.length() - eq - 4).trim()
    # `color⁅i⁆ == 1` / `n == 0` must use ceq — never String.op_Equality.
    if is_int_literal_token(left) || is_int_literal_token(right) || left == "true" || left == "false" || right == "true" || right == "false" {
        return body_lower_fail("soft:seq-int")
    }
    # `acc.length() != before` — `.length()` is int32; `.` must not force string path.
    if left.ends_with(".length()") || right.ends_with(".length()") {
        return body_lower_fail("soft:seq-length-int")
    }
    let left_ty: utf8 = find_local(locals, left).clr_type
    let right_ty: utf8 = find_local(locals, right).clr_type
    if left_ty == "int32" || left_ty == "int64" || left_ty == "bool" || right_ty == "int32" || right_ty == "int64" || right_ty == "bool" {
        return body_lower_fail("soft:seq-int-local")
    }
    # Pure index load (`arr⁅i⁆` / `arr[i]`) compared to non-string → int path.
    # Keep `out⁅j⁆.name == st.name` on the string path (field after index).
    let left_pure_idx: bool = left.ends_with("⁆") || (left.ends_with("]") && left.contains("[") && !left.starts_with("["))
    let right_pure_idx: bool = right.ends_with("⁆") || (right.ends_with("]") && right.contains("[") && !right.starts_with("["))
    if left_pure_idx && !(is_string_literal_expr(right) || right_ty == "string") {
        return body_lower_fail("soft:seq-index-int")
    }
    if right_pure_idx && !(is_string_literal_expr(left) || left_ty == "string") {
        return body_lower_fail("soft:seq-index-int")
    }
    # Field/method dots except numeric `.length()` (already rejected above).
    let left_strish: bool = left_ty == "string" || left.contains(".name") || (left.index_of(".") >= 0 && !left.ends_with(".length()"))
    let right_strish: bool = right_ty == "string" || right.contains(".name") || (right.index_of(".") >= 0 && !right.ends_with(".length()"))
    if !(is_string_literal_expr(right) || is_string_literal_expr(left) || left_strish || right_strish || left.contains("⁅") || right.contains("⁅")) {
        return body_lower_fail("soft:seq-types")
    }
    let mut acc_se: utf8 = msil
    if is_string_literal_expr(left) {
        let lr: BodyLowerResult = emit_string_literal_expr(acc_se, left)
        if !lr.ok {
            return lr
        }
        acc_se = lr.instructions
    }
    else {
        let lr: BodyLowerResult = emit_value_expr(acc_se, left, locals, submission)
        if !lr.ok {
            return lr
        }
        acc_se = lr.instructions
    }
    if is_string_literal_expr(right) {
        let rr: BodyLowerResult = emit_string_literal_expr(acc_se, right)
        if !rr.ok {
            return rr
        }
        acc_se = rr.instructions
    }
    else {
        let rr: BodyLowerResult = emit_value_expr(acc_se, right, locals, submission)
        if !rr.ok {
            return rr
        }
        acc_se = rr.instructions
    }
    let mut acc: utf8 = append_msil_line(acc_se, "        call bool [mscorlib]System.String::op_Equality(string, string)")
    if negate {
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, "        ceq")
    }
    return body_lower_ok(acc, "")
}

micro emit_bool_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let e: utf8 = expr.trim()
    let se: BodyLowerResult = try_emit_string_equality(msil, e, locals, submission)
    if se.ok {
        return se
    }
    if looks_like_call_expr(e) {
        return emit_call_expr(msil, e, locals, submission)
    }
    let ir: BodyLowerResult = emit_int_expr(msil, e, locals, submission)
    if ir.ok {
        return ir
    }
    return body_lower_fail("无法 lowering 布尔条件：" + e)
}

micro emit_field_store(left: utf8, right: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let dot: i32 = last_index_of_text(left, ".")
    if dot <= 0 {
        return body_lower_fail("字段赋值路径无效：" + left)
    }
    let obj_path: utf8 = left.slice(0, dot).trim()
    let field_name: utf8 = left.slice(dot + 1, left.length() - dot - 1).trim()
    let loaded: PathLoadResult = emit_load_path("", obj_path, locals, structs)
    if !loaded.ok {
        return body_lower_fail(loaded.error)
    }
    let mut type_name: utf8 = loaded.result_type.trim()
    if type_name.starts_with("class") {
        type_name = type_name.slice(5, type_name.length() - 5).trim()
    }
    let st: ParsedStruct = find_struct_def(structs, type_name)
    if st.name.length() == 0 {
        return body_lower_fail("字段赋值未知结构：" + type_name)
    }
    let field: ParsedStructField = find_struct_field(st, field_name)
    if field.name.length() == 0 {
        return body_lower_fail("字段赋值未知字段：" + type_name + "." + field_name)
    }
    let ft: utf8 = msil_field_type(field.type_text, structs)
    let mut acc: utf8 = loaded.instructions
    if looks_like_call_expr(right) {
        let cr: BodyLowerResult = emit_call_expr(acc, right, locals, submission)
        if !cr.ok {
            return cr
        }
        acc = cr.instructions
    }
    else {
        let vr: BodyLowerResult = emit_value_expr(acc, right, locals, submission)
        if !vr.ok {
            return vr
        }
        acc = vr.instructions
    }
    return body_lower_ok(append_msil_line(acc, "        stfld " + ft + " " + type_name + "::" + msil_id(field_name)), "")
}

# recv.starts_with / contains / slice / to_lower → BCL string ops. Leaves value on stack.
micro emit_string_receiver_call(msil: utf8, expr: utf8, locals: [BodyLocal], structs: [ParsedStruct], submission: FragmentSubmission) -> BodyLowerResult {
    let mut e: utf8 = expr.trim()
    # Peel trailing nullary string methods: `.trim()` / `.to_lower()` chains.
    if e.ends_with(".to_lower()") {
        let inner: utf8 = e.slice(0, e.length() - 11).trim()
        let ir: BodyLowerResult = emit_string_receiver_call(msil, inner, locals, structs, submission)
        if !ir.ok {
            let vr: BodyLowerResult = emit_value_expr(msil, inner, locals, submission)
            if !vr.ok {
                return vr
            }
            return body_lower_ok(append_msil_line(vr.instructions, "        callvirt instance string [mscorlib]System.String::ToLower()"), "")
        }
        return body_lower_ok(append_msil_line(ir.instructions, "        callvirt instance string [mscorlib]System.String::ToLower()"), "")
    }
    if e.ends_with(".trim()") {
        let inner: utf8 = e.slice(0, e.length() - 7).trim()
        let ir: BodyLowerResult = emit_string_receiver_call(msil, inner, locals, structs, submission)
        if !ir.ok {
            let vr: BodyLowerResult = emit_value_expr(msil, inner, locals, submission)
            if !vr.ok {
                return vr
            }
            return body_lower_ok(append_msil_line(vr.instructions, "        callvirt instance string [mscorlib]System.String::Trim()"), "")
        }
        return body_lower_ok(append_msil_line(ir.instructions, "        callvirt instance string [mscorlib]System.String::Trim()"), "")
    }
    let open: i32 = find_outer_method_call_open(e)
    let close: i32 = matching_close_paren(e, open)
    if open <= 0 || close <= open {
        return body_lower_fail("字符串方法缺少括号：" + e)
    }
    # Chained `.trim().length()` must not be stolen as a trim call spanning to the last `)`.
    if close + 1 < e.length() {
        let after_call: utf8 = e.slice(close + 1, e.length() - close - 1).trim()
        if after_call.length() > 0 {
            return body_lower_fail("字符串方法后还有后缀：" + after_call)
        }
    }
    let recv_method: utf8 = e.slice(0, open).trim()
    let dot: i32 = last_index_of_text(recv_method, ".")
    if dot <= 0 {
        return body_lower_fail("字符串方法缺少接收者：" + e)
    }
    let recv: utf8 = recv_method.slice(0, dot).trim()
    let method: utf8 = recv_method.slice(dot + 1, recv_method.length() - dot - 1).trim()
    let arglist: utf8 = e.slice(open + 1, close - open - 1).trim()
    let recv_r: BodyLowerResult = emit_value_expr(msil, recv, locals, submission)
    if !recv_r.ok {
        return recv_r
    }
    let mut acc: utf8 = recv_r.instructions
    if method == "starts_with" || method == "ends_with" {
        let ar: BodyLowerResult = emit_value_expr(acc, arglist, locals, submission)
        if !ar.ok {
            return ar
        }
        let bcl: utf8 = "StartsWith"
        if method == "ends_with" {
            bcl = "EndsWith"
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        callvirt instance bool [mscorlib]System.String::" + bcl + "(string)"), "")
    }
    if method == "contains" {
        let ar: BodyLowerResult = emit_value_expr(acc, arglist, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        callvirt instance bool [mscorlib]System.String::Contains(string)"), "")
    }
    if method == "trim" {
        if arglist.length() != 0 {
            return body_lower_fail("trim 无参数：" + expr)
        }
        return body_lower_ok(append_msil_line(acc, "        callvirt instance string [mscorlib]System.String::Trim()"), "")
    }
    if method == "to_lower" {
        if arglist.length() != 0 {
            return body_lower_fail("to_lower 无参数：" + expr)
        }
        return body_lower_ok(append_msil_line(acc, "        callvirt instance string [mscorlib]System.String::ToLower()"), "")
    }
    if method == "replace" {
        let args: [utf8] = split_call_args(arglist)
        if args.length() != 2 {
            return body_lower_fail("replace 需要两参数：" + expr)
        }
        let a0: BodyLowerResult = emit_value_expr(acc, args⁅0⁆, locals, submission)
        if !a0.ok {
            return a0
        }
        let a1: BodyLowerResult = emit_value_expr(a0.instructions, args⁅1⁆, locals, submission)
        if !a1.ok {
            return a1
        }
        return body_lower_ok(append_msil_line(a1.instructions, "        callvirt instance string [mscorlib]System.String::Replace(string, string)"), "")
    }
    if method == "slice" {
        let args: [utf8] = split_call_args(arglist)
        if args.length() != 2 {
            return body_lower_fail("slice 需要两参数：" + expr)
        }
        let a0: BodyLowerResult = emit_int_expr(acc, args⁅0⁆, locals, submission)
        if !a0.ok {
            return a0
        }
        let a1: BodyLowerResult = emit_int_expr(a0.instructions, args⁅1⁆, locals, submission)
        if !a1.ok {
            return a1
        }
        return body_lower_ok(append_msil_line(a1.instructions, "        callvirt instance string [mscorlib]System.String::Substring(int32, int32)"), "")
    }
    if method == "index_of" {
        let ar: BodyLowerResult = emit_value_expr(acc, arglist, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        callvirt instance int32 [mscorlib]System.String::IndexOf(string)"), "")
    }
    if method == "last_index_of" {
        let ar: BodyLowerResult = emit_value_expr(acc, arglist, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        callvirt instance int32 [mscorlib]System.String::LastIndexOf(string)"), "")
    }
    if method == "equals" {
        let ar: BodyLowerResult = emit_value_expr(acc, arglist, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        callvirt instance bool [mscorlib]System.String::Equals(string)"), "")
    }
    return body_lower_fail("未知字符串方法：" + method)
}

micro strip_outer_parens(expr: utf8) -> utf8 {
    let e: utf8 = expr.trim()
    if !e.starts_with("(") || !e.ends_with(")") {
        return e
    }
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    while i < e.length() {
        let ch: utf8 = e.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(e, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "(" {
            depth = depth + 1
        }
        else if ch == ")" {
            depth = depth - 1
            if depth == 0 {
                if i == e.length() - 1 {
                    return e.slice(1, e.length() - 2).trim()
                }
                return e
            }
        }
        i = i + 1
    }
    return e
}

# Top-level ` && ` / ` || ` index; ignore operators inside strings or parentheses.
micro top_level_bool_op_index(expr: utf8, op: utf8) -> i32 {
    let mut depth: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    let oplen: i32 = op.length()
    while i + oplen <= expr.length() {
        let ch: utf8 = expr.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(expr, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "(" || ch == "[" || ch == "⁅" || ch == "{" {
            depth = depth + 1
            i = i + 1
            continue
        }
        if ch == ")" || ch == "]" || ch == "⁆" || ch == "}" {
            depth = depth - 1
            i = i + 1
            continue
        }
        if depth == 0 && expr.slice(i, oplen) == op {
            return i
        }
        i = i + 1
    }
    return -1
}

# Leave int32 0/1 on stack for branching.
micro emit_bool_condition(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let e: utf8 = strip_outer_parens(expr.trim())
    let structs: [ParsedStruct] = submission.struct_defs
    # `&&` / `||` before unary `!` so `!a && b` is (!a) && b, not !(a && b).
    let and_at: i32 = top_level_bool_op_index(e, " && ")
    if and_at >= 0 {
        # Short-circuit: do not evaluate right when left is false (e.g. `j > 0 && a⁅j-1⁆`).
        let left: utf8 = e.slice(0, and_at).trim()
        let right: utf8 = e.slice(and_at + 4, e.length() - and_at - 4).trim()
        let id: i32 = msil.length() + e.length()
        let false_l: utf8 = "SCf" + format("{}", id)
        let end_l: utf8 = "SCe" + format("{}", id)
        let lr: BodyLowerResult = emit_bool_condition(msil, left, locals, submission)
        if !lr.ok {
            return lr
        }
        let mut acc: utf8 = append_msil_line(lr.instructions, "        brfalse " + false_l)
        let rr: BodyLowerResult = emit_bool_condition(acc, right, locals, submission)
        if !rr.ok {
            return rr
        }
        acc = append_msil_line(rr.instructions, "        br " + end_l)
        acc = append_msil_line(acc, false_l + ":")
        acc = append_msil_line(acc, "        ldc.i4.0")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    let or_at: i32 = top_level_bool_op_index(e, " || ")
    if or_at >= 0 {
        # Short-circuit: do not evaluate right when left is true.
        let left: utf8 = e.slice(0, or_at).trim()
        let right: utf8 = e.slice(or_at + 4, e.length() - or_at - 4).trim()
        let id: i32 = msil.length() + e.length()
        let true_l: utf8 = "SCt" + format("{}", id)
        let end_l: utf8 = "SCo" + format("{}", id)
        let lr: BodyLowerResult = emit_bool_condition(msil, left, locals, submission)
        if !lr.ok {
            return lr
        }
        let mut acc: utf8 = append_msil_line(lr.instructions, "        brtrue " + true_l)
        let rr: BodyLowerResult = emit_bool_condition(acc, right, locals, submission)
        if !rr.ok {
            return rr
        }
        acc = append_msil_line(rr.instructions, "        br " + end_l)
        acc = append_msil_line(acc, true_l + ":")
        acc = append_msil_line(acc, "        ldc.i4.1")
        acc = append_msil_line(acc, end_l + ":")
        return body_lower_ok(acc, "")
    }
    if e.starts_with("!") {
        let inner: utf8 = e.slice(1, e.length() - 1).trim()
        let br: BodyLowerResult = emit_bool_condition(msil, inner, locals, submission)
        if !br.ok {
            return br
        }
        let acc: utf8 = append_msil_line(br.instructions, "        ldc.i4.0")
        return body_lower_ok(append_msil_line(acc, "        ceq"), "")
    }
    let io_bool: BodyLowerResult = emit_std_io_call(msil, e, locals, submission)
    if io_bool.ok {
        return io_bool
    }
    if io_bool.error.length() > 0 && !io_bool.error.starts_with("soft:") {
        return io_bool
    }
    if e.ends_with(" == 0") {
        let left: utf8 = e.slice(0, e.length() - 5).trim()
        let lr: BodyLowerResult = emit_int_expr(msil, left, locals, submission)
        if !lr.ok {
            return lr
        }
        let acc: utf8 = append_msil_line(lr.instructions, "        ldc.i4.0")
        return body_lower_ok(append_msil_line(acc, "        ceq"), "")
    }
    if e.ends_with(" != 0") {
        let left: utf8 = e.slice(0, e.length() - 5).trim()
        let lr: BodyLowerResult = emit_int_expr(msil, left, locals, submission)
        if !lr.ok {
            return lr
        }
        let acc: utf8 = append_msil_line(lr.instructions, "        ldc.i4.0")
        return body_lower_ok(append_msil_line(acc, "        cgt.un"), "")
    }
    let eq: i32 = e.index_of(" == ")
    if eq > 0 {
        let left: utf8 = e.slice(0, eq).trim()
        let right: utf8 = e.slice(eq + 4, e.length() - eq - 4).trim()
        let se0: BodyLowerResult = try_emit_string_equality(msil, e, locals, submission)
        if se0.ok {
            return se0
        }
        let lr: BodyLowerResult = emit_int_expr(msil, left, locals, submission)
        if lr.ok {
            let rr: BodyLowerResult = emit_int_expr(lr.instructions, right, locals, submission)
            if rr.ok {
                return body_lower_ok(append_msil_line(rr.instructions, "        ceq"), "")
            }
        }
    }
    let ne: i32 = e.index_of(" != ")
    if ne > 0 {
        let left_ne: utf8 = e.slice(0, ne).trim()
        let right_ne: utf8 = e.slice(ne + 4, e.length() - ne - 4).trim()
        let se_ne: BodyLowerResult = try_emit_string_equality(msil, e, locals, submission)
        if se_ne.ok {
            return se_ne
        }
        let lr_ne: BodyLowerResult = emit_int_expr(msil, left_ne, locals, submission)
        if lr_ne.ok {
            let rr_ne: BodyLowerResult = emit_int_expr(lr_ne.instructions, right_ne, locals, submission)
            if rr_ne.ok {
                # a != b → !(a == b)
                let mut acc_ne: utf8 = append_msil_line(rr_ne.instructions, "        ceq")
                acc_ne = append_msil_line(acc_ne, "        ldc.i4.0")
                return body_lower_ok(append_msil_line(acc_ne, "        ceq"), "")
            }
        }
    }
    let se: BodyLowerResult = try_emit_string_equality(msil, e, locals, submission)
    if se.ok {
        return se
    }
    # Int comparisons before field-path heuristic — `index >= tokens.length()` has `.`
    # and must not be split as path `index >= tokens`.
    let cmp_ge: i32 = e.index_of(" >= ")
    let cmp_le: i32 = e.index_of(" <= ")
    let cmp_gt: i32 = e.index_of(" > ")
    let cmp_lt: i32 = e.index_of(" < ")
    # Char/utf8 relational: `ch >= "0" && ch <= "9"` via String.Compare.
    let mut rel_op: utf8 = ""
    let mut rel_at: i32 = -1
    if cmp_ge > 0 {
        rel_op = "ge"
        rel_at = cmp_ge
    }
    else if cmp_le > 0 {
        rel_op = "le"
        rel_at = cmp_le
    }
    else if cmp_gt > 0 {
        rel_op = "gt"
        rel_at = cmp_gt
    }
    else if cmp_lt > 0 {
        rel_op = "lt"
        rel_at = cmp_lt
    }
    if rel_at > 0 {
        let mut op_len: i32 = 4
        if rel_op == "gt" || rel_op == "lt" {
            op_len = 3
        }
        let left_r: utf8 = e.slice(0, rel_at).trim()
        let right_r: utf8 = e.slice(rel_at + op_len, e.length() - rel_at - op_len).trim()
        if is_string_literal_expr(left_r) || is_string_literal_expr(right_r) || find_local(locals, left_r).clr_type == "string" || find_local(locals, right_r).clr_type == "string" {
            let lr: BodyLowerResult = emit_value_expr(msil, left_r, locals, submission)
            if !lr.ok {
                return lr
            }
            let rr: BodyLowerResult = emit_value_expr(lr.instructions, right_r, locals, submission)
            if !rr.ok {
                return rr
            }
            let mut acc_rel: utf8 = append_msil_line(rr.instructions, "        call int32 [mscorlib]System.String::Compare(string, string)")
            acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
            if rel_op == "lt" {
                return body_lower_ok(append_msil_line(acc_rel, "        clt"), "")
            }
            if rel_op == "gt" {
                return body_lower_ok(append_msil_line(acc_rel, "        cgt"), "")
            }
            if rel_op == "le" {
                acc_rel = append_msil_line(acc_rel, "        cgt")
                acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
                return body_lower_ok(append_msil_line(acc_rel, "        ceq"), "")
            }
            # ge → !(a < b)
            acc_rel = append_msil_line(acc_rel, "        clt")
            acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
            return body_lower_ok(append_msil_line(acc_rel, "        ceq"), "")
        }
    }
    if cmp_ge > 0 || cmp_le > 0 || (cmp_gt > 0 && e.index_of(" > ") > 0) || cmp_lt > 0 {
        let ir_cmp: BodyLowerResult = emit_int_expr(msil, e, locals, submission)
        if ir_cmp.ok {
            return ir_cmp
        }
    }
    # Bool/int field path: `attempt.ok` / `manager.has_manifest` — not string methods.
    if e.index_of("(") < 0 && e.index_of(" ") < 0 && (e.index_of(".") >= 0 || find_local(locals, e).slot >= 0) {
        let loaded: PathLoadResult = emit_load_path(msil, e, locals, structs)
        if loaded.ok && (loaded.result_type == "int32" || loaded.result_type == "bool") {
            return body_lower_ok(loaded.instructions, "")
        }
        if loaded.ok && loaded.result_type == "string" {
            # non-empty string as truthy
            let mut acc: utf8 = append_msil_line(loaded.instructions, "        callvirt instance int32 [mscorlib]System.String::get_Length()")
            acc = append_msil_line(acc, "        ldc.i4.0")
            return body_lower_ok(append_msil_line(acc, "        cgt"), "")
        }
    }
    if looks_like_call_expr(e) {
        return emit_call_expr(msil, e, locals, submission)
    }
    if e.ends_with(".is_some()") {
        let inner: utf8 = e.slice(0, e.length() - 10).trim()
        let lr: BodyLowerResult = emit_value_expr(msil, inner, locals, submission)
        if !lr.ok {
            return lr
        }
        let mut acc: utf8 = append_msil_line(lr.instructions, "        ldnull")
        acc = append_msil_line(acc, "        cgt.un")
        return body_lower_ok(acc, "")
    }
    if e.ends_with(".is_none()") {
        let inner_n: utf8 = e.slice(0, e.length() - 10).trim()
        let lr_n: BodyLowerResult = emit_value_expr(msil, inner_n, locals, submission)
        if !lr_n.ok {
            return lr_n
        }
        # Option erased to nullable ref — None ⇔ == null.
        let mut acc_n: utf8 = append_msil_line(lr_n.instructions, "        ldnull")
        acc_n = append_msil_line(acc_n, "        ceq")
        return body_lower_ok(acc_n, "")
    }
    # Nested `x.slice(0, x.length()-n)` has `.length()` inside parens — still a string method.
    # Depth-0 `.length()` (e.g. `x.trim().length()`) must win via emit_int_expr.
    if index_of_at_paren_depth0(e, ".length()") < 0 && (e.contains(".starts_with(") || e.contains(".ends_with(") || e.contains(".contains(") || e.contains(".trim(") || e.contains(".to_lower(") || e.contains(".index_of(") || e.contains(".last_index_of(") || e.contains(".equals(") || e.ends_with(".to_lower()") || e.ends_with(".trim()")) {
        let sm: BodyLowerResult = emit_string_receiver_call(msil, e, locals, structs, submission)
        if sm.ok {
            return sm
        }
        if sm.error.length() > 0 {
            return sm
        }
    }
    # arg.starts_with("...") / arg.contains("...")
    let sw: i32 = e.index_of(".starts_with(")
    if sw > 0 && e.ends_with(")") {
        let base: utf8 = e.slice(0, sw).trim()
        let lit_part: utf8 = e.slice(sw + 13, e.length() - sw - 14).trim()
        let lr: BodyLowerResult = emit_value_expr(msil, base, locals, submission)
        if !lr.ok {
            return lr
        }
        let rr: BodyLowerResult = emit_value_expr(lr.instructions, lit_part, locals, submission)
        if !rr.ok {
            return rr
        }
        return body_lower_ok(append_msil_line(rr.instructions, "        callvirt instance bool [mscorlib]System.String::StartsWith(string)"), "")
    }
    let ct: i32 = e.index_of(".contains(")
    if ct > 0 && e.ends_with(")") {
        let base: utf8 = e.slice(0, ct).trim()
        let lit_part: utf8 = e.slice(ct + 10, e.length() - ct - 11).trim()
        let lr: BodyLowerResult = emit_value_expr(msil, base, locals, submission)
        if !lr.ok {
            return lr
        }
        let rr: BodyLowerResult = emit_value_expr(lr.instructions, lit_part, locals, submission)
        if !rr.ok {
            return rr
        }
        return body_lower_ok(append_msil_line(rr.instructions, "        callvirt instance bool [mscorlib]System.String::Contains(string)"), "")
    }
    return emit_int_expr(msil, e, locals, submission)
}

# `if c { e1 } else if c2 { e2 } else { e3 }` as a value expression.
micro emit_if_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission, lab: i32) -> BodyLowerResult {
    let mut rest: utf8 = expr.trim()
    if !rest.starts_with("if ") {
        return body_lower_fail("非 if 表达式：" + expr)
    }
    let end_l: utf8 = "IE" + format("{}", lab)
    let mut next_lab: i32 = lab + 1
    let mut parts: [utf8] = []
    if msil.length() > 0 {
        parts = push(parts, msil)
    }
    let mut saw_branch: bool = false
    while rest.starts_with("if ") {
        let after: utf8 = rest.slice(3, rest.length() - 3).trim()
        let brace: i32 = index_of_brace_outside_string(after)
        if brace < 0 {
            return body_lower_fail("if 表达式缺少体：" + rest)
        }
        let cond: utf8 = after.slice(0, brace).trim()
        let then_end: i32 = match_brace_close(after, brace)
        if then_end < 0 {
            return body_lower_fail("if 表达式体未闭合")
        }
        let then_inner: utf8 = after.slice(brace + 1, then_end - brace - 1).trim()
        let after_then: utf8 = after.slice(then_end + 1, after.length() - then_end - 1).trim()
        let skip_l: utf8 = "IS" + format("{}", next_lab)
        next_lab = next_lab + 1
        let cr: BodyLowerResult = emit_bool_condition("", cond, locals, submission)
        if !cr.ok {
            return cr
        }
        parts = push(parts, append_msil_line(cr.instructions, "        brfalse " + skip_l))
        let mut then_ok: bool = false
        if looks_like_call_expr(then_inner) {
            let tc: BodyLowerResult = emit_call_expr("", then_inner, locals, submission)
            if !tc.ok {
                return tc
            }
            parts = push(parts, tc.instructions)
            then_ok = true
        }
        if !then_ok {
            let tr: BodyLowerResult = emit_value_expr("", then_inner, locals, submission)
            if !tr.ok {
                return tr
            }
            parts = push(parts, tr.instructions)
        }
        parts = push(parts, "        br " + end_l + "\n")
        parts = push(parts, skip_l + ":\n")
        saw_branch = true
        if after_then.starts_with("else if ") {
            rest = "if " + after_then.slice(8, after_then.length() - 8).trim()
        }
        else if after_then == "else" || after_then.starts_with("else ") || after_then.starts_with("else{") || after_then.starts_with("else\n") || after_then.starts_with("else\t") {
            let eb: i32 = index_of_brace_outside_string(after_then)
            if eb < 0 {
                return body_lower_fail("else 缺少体")
            }
            let else_inner: utf8 = extract_function_inner_body("x" + after_then.slice(eb, after_then.length() - eb)).trim()
            let mut else_ok: bool = false
            if looks_like_call_expr(else_inner) {
                let ec: BodyLowerResult = emit_call_expr("", else_inner, locals, submission)
                if !ec.ok {
                    return ec
                }
                parts = push(parts, ec.instructions)
                else_ok = true
            }
            if !else_ok {
                let er: BodyLowerResult = emit_value_expr("", else_inner, locals, submission)
                if !er.ok {
                    return er
                }
                parts = push(parts, er.instructions)
            }
            rest = ""
            break
        }
        else {
            return body_lower_fail("if 表达式缺少 else：" + expr)
        }
    }
    if !saw_branch {
        return body_lower_fail("空 if 表达式")
    }
    parts = push(parts, end_l + ":\n")
    return body_lower_ok_lab(join_msil_parts(parts), "", next_lab)
}

structure PathLoadResult {
    ok: bool
    error: utf8
    instructions: utf8
    result_type: utf8
}

micro emit_load_path(msil: utf8, path: utf8, locals: [BodyLocal], structs: [ParsedStruct]) -> PathLoadResult {
    let e: utf8 = path.trim()
    if e.length() == 0 {
        return PathLoadResult {
            ok: false,
            error: "空路径",
            instructions: msil,
            result_type: ""
        }
    }
    # Split on '.' outside strings/parens — keep `find_unite_def(s.unite_defs, x).name` intact.
    let mut acc: utf8 = msil
    let mut seg_start: i32 = 0
    let mut first: bool = true
    let mut cur_type: utf8 = ""
    let mut i: i32 = 0
    let mut paren_d: i32 = 0
    let mut in_str: utf8 = ""
    while i <= e.length() {
        let at_end: bool = i == e.length()
        let ch: utf8 = "."
        if !at_end {
            ch = e.slice(i, 1)
        }
        if !at_end && in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
            }
            else {
                i = string_lit_advance(e, i)
                continue
            }
            i = i + 1
            continue
        }
        if !at_end && (ch == dq() || ch == "'") {
            in_str = ch
            i = i + 1
            continue
        }
        if !at_end && (ch == "(" || ch == "[" || ch == "⁅") {
            paren_d = paren_d + 1
            i = i + 1
            continue
        }
        if !at_end && (ch == ")" || ch == "]" || ch == "⁆") {
            paren_d = paren_d - 1
            i = i + 1
            continue
        }
        if at_end || (ch == "." && paren_d == 0) {
            let seg: utf8 = e.slice(seg_start, i - seg_start).trim()
            if seg.length() == 0 {
                return PathLoadResult {
                    ok: false,
                    error: "空字段段：" + path,
                    instructions: msil,
                    result_type: ""
                }
            }
            # Indexed paths (`arr⁅i⁆` / `obj.field⁅i⁆`) — not field segments.
            if seg.contains("⁅") || seg.contains("⁆") || (seg.contains("[") && seg.contains("]")) {
                return PathLoadResult {
                    ok: false,
                    error: "soft:path-index",
                    instructions: msil,
                    result_type: ""
                }
            }
            if seg.contains(" ") || seg.contains("=") || seg.contains("<") || seg.contains(">") {
                return PathLoadResult {
                    ok: false,
                    error: "soft:path-ops",
                    instructions: msil,
                    result_type: ""
                }
            }
            # `failure.unwrap().message` — Option erase: skip `.unwrap()` segments.
            if seg == "unwrap()" || seg == "unwrap" {
                if first {
                    return PathLoadResult {
                        ok: false,
                        error: "unwrap 缺少接收者：" + path,
                        instructions: msil,
                        result_type: ""
                    }
                }
                seg_start = i + 1
                i = i + 1
                continue
            }
            if first {
                let local: BodyLocal = find_local(locals, seg)
                if local.slot < 0 {
                    return PathLoadResult {
                        ok: false,
                        error: "未知局部/参数：" + seg,
                        instructions: msil,
                        result_type: ""
                    }
                }
                acc = append_ld_slot(acc, local)
                cur_type = local.clr_type
                first = false
            }
            else if seg == "length" && (cur_type.ends_with("[]") || cur_type == "string" || cur_type == "utf8" || cur_type == "class string") {
                # V property `.length` (no call parens) — arrays ldlen; strings get_Length.
                if cur_type.ends_with("[]") {
                    acc = append_msil_line(acc, "        ldlen")
                    acc = append_msil_line(acc, "        conv.i4")
                }
                else {
                    acc = append_msil_line(acc, "        callvirt instance int32 [mscorlib]System.String::get_Length()")
                }
                cur_type = "int32"
            }
            else {
                let mut type_name: utf8 = cur_type.trim()
                if type_name.starts_with("class ") {
                    type_name = type_name.slice(6, type_name.length() - 6).trim()
                }
                else if type_name.starts_with("class") {
                    type_name = type_name.slice(5, type_name.length() - 5).trim()
                }
                let st: ParsedStruct = find_struct_def(structs, type_name)
                if st.name.length() == 0 {
                    # Struct scrape miss — still emit ldfld when nominal class name is known.
                    if type_name.length() > 0 && type_name.index_of(" ") < 0 && type_name.index_of("[") < 0 {
                        acc = append_msil_line(acc, "        ldfld object " + type_name + "::" + msil_id(seg))
                        cur_type = "object"
                        seg_start = i + 1
                        i = i + 1
                        continue
                    }
                    return PathLoadResult {
                        ok: false,
                        error: "字段访问需要结构类型，当前为：" + cur_type + " ." + seg,
                        instructions: msil,
                        result_type: ""
                    }
                }
                let field: ParsedStructField = find_struct_field(st, seg)
                if field.name.length() == 0 {
                    return PathLoadResult {
                        ok: false,
                        error: "未知字段：" + type_name + "." + seg,
                        instructions: msil,
                        result_type: ""
                    }
                }
                let ft: utf8 = msil_field_type(field.type_text, structs)
                acc = append_msil_line(acc, "        ldfld " + ft + " " + type_name + "::" + msil_id(seg))
                cur_type = ft
            }
            seg_start = i + 1
        }
        i = i + 1
    }
    return PathLoadResult {
        ok: true,
        error: "",
        instructions: acc,
        result_type: cur_type
    }
}

micro append_ldloc_slot(msil: utf8, slot: i32) -> utf8 {
    if slot == 0 {
        return append_msil_line(msil, "        ldloc.0")
    }
    if slot == 1 {
        return append_msil_line(msil, "        ldloc.1")
    }
    if slot == 2 {
        return append_msil_line(msil, "        ldloc.2")
    }
    if slot == 3 {
        return append_msil_line(msil, "        ldloc.3")
    }
    return append_msil_line(msil, "        ldloc.s " + format("{}", slot))
}

micro append_stloc_slot(msil: utf8, slot: i32) -> utf8 {
    if slot == 0 {
        return append_msil_line(msil, "        stloc.0")
    }
    if slot == 1 {
        return append_msil_line(msil, "        stloc.1")
    }
    if slot == 2 {
        return append_msil_line(msil, "        stloc.2")
    }
    if slot == 3 {
        return append_msil_line(msil, "        stloc.3")
    }
    return append_msil_line(msil, "        stloc.s " + format("{}", slot))
}

# Count string literals in `[ "a", "b" ]` without storing slices (CLR push aliasing).
micro count_string_array_literals(expr: utf8) -> i32 {
    let t: utf8 = expr.trim()
    if !t.starts_with("[") || !t.ends_with("]") {
        return -1
    }
    let inner: utf8 = t.slice(1, t.length() - 2)
    let quote: utf8 = dq()
    let mut n: i32 = 0
    let mut i: i32 = 0
    while i < inner.length() {
        if inner.slice(i, 1) == quote {
            n = n + 1
            i = i + 1
            while i < inner.length() && inner.slice(i, 1) != quote {
                i = i + 1
            }
            if i >= inner.length() {
                return -1
            }
        }
        i = i + 1
    }
    return n
}

micro emit_string_array_new(msil: utf8, expr: utf8) -> BodyLowerResult {
    let n: i32 = count_string_array_literals(expr)
    if n < 0 {
        return body_lower_fail("无法解析字符串数组字面量：" + expr)
    }
    let mut parts: [utf8] = []
    parts = push(parts, msil)
    parts = push(parts, append_ldc_i4_digits("", format("{}", n)))
    parts = push(parts, "        newarr [mscorlib]System.String\n")
    let t: utf8 = expr.trim()
    let inner: utf8 = t.slice(1, t.length() - 2)
    let quote: utf8 = dq()
    let mut i: i32 = 0
    let mut idx: i32 = 0
    while i < inner.length() {
        if inner.slice(i, 1) == quote {
            # Avoid `i = i + 1` clobber — compute start/end with fresh locals.
            let content_start: i32 = i + 1
            let mut j: i32 = content_start
            while j < inner.length() && inner.slice(j, 1) != quote {
                j = j + 1
            }
            if j >= inner.length() {
                return body_lower_fail("字符串数组字面量未闭合")
            }
            let count: i32 = j - content_start
            let piece: utf8 = "" + inner.slice(content_start, count) + ""
            let line1: utf8 = "        dup\n"
            let line2: utf8 = append_ldc_i4_digits("", format("{}", idx))
            let line3: utf8 = msil_quote_string(piece) + "\n"
            let line4: utf8 = "        stelem.ref\n"
            parts = push(parts, line1 + line2 + line3 + line4)
            idx = idx + 1
            i = j + 1
            continue
        }
        i = i + 1
    }
    return body_lower_ok(join_msil_parts(parts), "")
}

# `[expr0, expr1, …]` → string[] (struct field locator_segments, etc.).
micro emit_string_array_from_exprs(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let t: utf8 = expr.trim()
    if !t.starts_with("[") || !t.ends_with("]") {
        return body_lower_fail("非表达式数组：" + expr)
    }
    let inner: utf8 = t.slice(1, t.length() - 2).trim()
    let elems: [utf8] = split_call_args(inner)
    let n: i32 = elems.length() as i32
    let mut parts: [utf8] = []
    if msil.length() > 0 {
        parts = push(parts, msil)
    }
    parts = push(parts, append_ldc_i4_digits("", format("{}", n)))
    parts = push(parts, "        newarr [mscorlib]System.String\n")
    let mut ei: usize = 0
    while ei < elems.length() {
        let el: utf8 = elems⁅ei⁆.trim()
        if el.length() == 0 {
            ei = ei + 1
            continue
        }
        parts = push(parts, "        dup\n")
        parts = push(parts, append_ldc_i4_digits("", format("{}", ei as i32)))
        let vr: BodyLowerResult = emit_value_expr("", el, locals, submission)
        if !vr.ok {
            return vr
        }
        parts = push(parts, vr.instructions)
        parts = push(parts, "        stelem.ref\n")
        ei = ei + 1
    }
    return body_lower_ok(join_msil_parts(parts), "")
}

# Emit int32 expression leaving value on stack.
micro emit_int_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let mut e: utf8 = expr.trim()
    if e.length() == 0 {
        return body_lower_fail("空表达式")
    }
    # `(open + 1)` / `((x))`
    let mut stripped: utf8 = strip_outer_parens(e)
    while stripped != e {
        e = stripped
        stripped = strip_outer_parens(e)
    }
    # Bool chains must not fall through as a single int expr.
    if top_level_bool_op_index(e, " || ") >= 0 || top_level_bool_op_index(e, " && ") >= 0 {
        return emit_bool_condition(msil, e, locals, submission)
    }
    if index_of_at_paren_depth0(e, ".get(") >= 0 {
        let gr0: BodyLowerResult = try_emit_array_list_get(msil, e, locals, submission)
        if gr0.ok {
            return gr0
        }
        if gr0.error.length() > 0 && !gr0.error.starts_with("soft:") {
            return gr0
        }
    }
    if looks_like_call_expr(e) {
        return emit_call_expr(msil, e, locals, submission)
    }
    if e.starts_with("if ") {
        return emit_if_expr(msil, e, locals, submission, msil.length() + 1)
    }
    if is_string_literal_expr(e) {
        return body_lower_fail("整型上下文得到字符串字面量：" + e)
    }
    # Erase `as i32` / `as usize` (CLR bootstrap: all integers are int32).
    let as_at: i32 = index_of_at_paren_depth0(e, " as ")
    if as_at > 0 {
        let left_as: utf8 = e.slice(0, as_at).trim()
        let right_as: utf8 = e.slice(as_at + 4, e.length() - as_at - 4).trim()
        # `parts.length() as i32 - 1` → `parts.length() - 1`
        let sp: i32 = right_as.index_of(" ")
        if sp > 0 {
            e = left_as + right_as.slice(sp, right_as.length() - sp)
        }
        else {
            e = left_as
        }
    }
    let mut acc: utf8 = msil
    # Index before `.length()` — `arr⁅arr.length() - 1⁆` contains `.length()` but is an index.
    let early_idx0: BodyLowerResult = emit_index_expr(acc, e, locals, submission)
    if early_idx0.ok {
        return early_idx0
    }
    if early_idx0.error.length() > 0 && !early_idx0.error.starts_with("soft:") {
        return early_idx0
    }
    # path.length() [> 0 / == 0 / bare] — arrays ldlen; utf8/string get_Length.
    # Only depth-0 `.length()` — not `arg.slice(11, arg.length() - 11)`.
    # Also not `i < packages.length()` — comparison must win over a stolen base `i < packages`.
    # Not `fl.length() - colon - 1` — chained arith/cmp after `.length()` must use top-level split
    # (peeling `- colon - 1` as one rhs yields `length - (colon - 1)`).
    let len_at: i32 = index_of_at_paren_depth0(e, ".length()")
    if len_at > 0 {
        let base: utf8 = e.slice(0, len_at).trim()
        let after_len: utf8 = e.slice(len_at + 9, e.length() - len_at - 9).trim()
        let base_is_cmp: bool = base.contains(" < ") || base.contains(" > ") || base.contains(" <= ") || base.contains(" >= ") || base.contains(" == ") || base.contains(" != ") || base.contains(" && ") || base.contains(" || ")
        # `at + marker.length()` must use `+`/`-` first — base must not be an arithmetic expr.
        let base_is_arith: bool = index_of_at_paren_depth0(base, " + ") >= 0 || index_of_at_paren_depth0(base, " - ") >= 0 || index_of_at_paren_depth0(base, " * ") >= 0
        let mut suffix_chained: bool = false
        if after_len.starts_with("- ") || after_len.starts_with("+ ") || after_len.starts_with("* ") {
            let rhs_peel: utf8 = after_len.slice(2, after_len.length() - 2).trim()
            if index_of_at_paren_depth0(rhs_peel, " - ") >= 0 || index_of_at_paren_depth0(rhs_peel, " + ") >= 0 || index_of_at_paren_depth0(rhs_peel, " * ") >= 0 || index_of_at_paren_depth0(rhs_peel, " > ") >= 0 || index_of_at_paren_depth0(rhs_peel, " < ") >= 0 || index_of_at_paren_depth0(rhs_peel, " >= ") >= 0 || index_of_at_paren_depth0(rhs_peel, " <= ") >= 0 || index_of_at_paren_depth0(rhs_peel, " == ") >= 0 || index_of_at_paren_depth0(rhs_peel, " != ") >= 0 {
                suffix_chained = true
            }
        }
        if !base_is_cmp && !base_is_arith && !suffix_chained {
        let mut len_acc: utf8 = acc
        let mut len_ty: utf8 = ""
        # Pure field path `obj.field.length()` — load path for typed ldlen (not String.get_Length).
        if base.contains(".") && base.index_of("(") < 0 && base.index_of("⁅") < 0 && !(base.contains("[") && !base.starts_with("[")) {
            let loaded_fp: PathLoadResult = emit_load_path(acc, base, locals, structs)
            if loaded_fp.ok {
                len_acc = loaded_fp.instructions
                len_ty = loaded_fp.result_type
            }
        }
        if len_ty.length() == 0 && (base.contains("(") || base.contains("⁅") || (base.contains("[") && !base.starts_with("[")) || base.contains(".")) {
            let br: BodyLowerResult = emit_value_expr(acc, base, locals, submission)
            if !br.ok {
                return br
            }
            len_acc = br.instructions
            # Infer array vs string for ldlen vs get_Length.
            len_ty = "string"
            let base_l: BodyLocal = find_local(locals, base)
            if base_l.clr_type.ends_with("[]") {
                len_ty = base_l.clr_type
            }
            else if base.contains("⁅") || (base.contains("[") && !base.starts_with("[")) {
                let mut cut_l: i32 = index_of_at_paren_depth0(base, "⁅")
                if cut_l < 0 {
                    cut_l = index_of_at_paren_depth0(base, "[")
                }
                if cut_l > 0 {
                    let bn: utf8 = base.slice(0, cut_l).trim()
                    let bl2: BodyLocal = find_local(locals, bn)
                    let mut et: utf8 = bl2.clr_type
                    if et.ends_with("[]") {
                        et = et.slice(0, et.length() - 2).trim()
                    }
                    # `modules⁅0⁆.functions` → field type often array
                    if base.contains(".functions") || base.contains(".members") || base.contains(".fields") || base.contains(".variants") || base.contains(".dependencies") || base.contains(".packages") || base.contains(".external_call_edges") || base.contains(".build_targets") || base.contains(".dependency_names") || base.contains(".dependency_order") {
                        len_ty = "object[]"
                    }
                    else if et == "string" || et == "utf8" || et == "class string" {
                        len_ty = "string"
                    }
                    else if et.ends_with("[]") {
                        len_ty = et
                    }
                    else if et.starts_with("class ") {
                        # Element is a class — `.length()` on indexed element is rare; treat as string.
                        len_ty = "string"
                    }
                    else if et.length() > 0 {
                        len_ty = "string"
                    }
                }
            }
            else if base.ends_with(".functions") || base.ends_with(".fields") || base.ends_with(".variants") || base.ends_with(".members") || base.ends_with(".dependencies") || base.ends_with(".packages") || base.ends_with(".external_call_edges") || base.ends_with(".build_targets") || base.ends_with(".dependency_names") || base.ends_with(".dependency_order") {
                len_ty = "object[]"
            }
        }
        else if len_ty.length() == 0 {
            let loaded: PathLoadResult = emit_load_path(acc, base, locals, structs)
            if !loaded.ok {
                if loaded.error.length() > 0 && !loaded.error.starts_with("soft:") {
                    return body_lower_fail(loaded.error)
                }
                # Indexed/complex base — try value expr.
                let br2: BodyLowerResult = emit_value_expr(acc, base, locals, submission)
                if !br2.ok {
                    return body_lower_fail(".length() 基路径失败：" + base)
                }
                len_acc = br2.instructions
                len_ty = "object[]"
                # fall into ldlen/get_Length below via len_ty
            }
            else {
                len_acc = loaded.instructions
                len_ty = loaded.result_type
            }
        }
        if len_ty.starts_with("class ") {
            len_ty = len_ty.slice(6, len_ty.length() - 6).trim()
        }
        if len_ty == "utf8" {
            len_ty = "string"
        }
        if len_ty == "Array" || len_ty.ends_with("Array") {
            len_ty = "object[]"
        }
        if len_ty.ends_with("[]") {
            acc = append_msil_line(len_acc, "        ldlen")
            acc = append_msil_line(acc, "        conv.i4")
        }
        else if len_ty == "string" {
            acc = append_msil_line(len_acc, "        callvirt instance int32 [mscorlib]System.String::get_Length()")
        }
        else if len_ty == "class ArrayList" || len_ty.ends_with(".ArrayList") || len_ty == "ArrayList" {
            # ArrayList.length → _items ldlen (source layout; not host List`1).
            acc = append_msil_line(len_acc, "        ldfld uint8[] ArrayList::_items")
            acc = append_msil_line(acc, "        ldlen")
            acc = append_msil_line(acc, "        conv.i4")
        }
        else {
            return body_lower_fail(".length() 需要数组或 string，实际为：" + len_ty)
        }
        if after_len.length() == 0 {
            return body_lower_ok(acc, "")
        }
        if after_len == "> 0" {
            acc = append_msil_line(acc, "        ldc.i4.0")
            acc = append_msil_line(acc, "        cgt")
            return body_lower_ok(acc, "")
        }
        if after_len == "== 0" {
            acc = append_msil_line(acc, "        ldc.i4.0")
            acc = append_msil_line(acc, "        ceq")
            return body_lower_ok(acc, "")
        }
        if after_len == "> 1" {
            acc = append_msil_line(acc, "        ldc.i4.1")
            acc = append_msil_line(acc, "        cgt")
            return body_lower_ok(acc, "")
        }
        if after_len.starts_with("- ") {
            let rhs: utf8 = after_len.slice(2, after_len.length() - 2).trim()
            let rr: BodyLowerResult = emit_int_expr(acc, rhs, locals, submission)
            if !rr.ok {
                return rr
            }
            return body_lower_ok(append_msil_line(rr.instructions, "        sub"), "")
        }
        if after_len.starts_with("+ ") {
            let rhs_add: utf8 = after_len.slice(2, after_len.length() - 2).trim()
            let rr_add: BodyLowerResult = emit_int_expr(acc, rhs_add, locals, submission)
            if !rr_add.ok {
                return rr_add
            }
            return body_lower_ok(append_msil_line(rr_add.instructions, "        add"), "")
        }
        if after_len.starts_with("* ") {
            let rhs_mul: utf8 = after_len.slice(2, after_len.length() - 2).trim()
            let rr_mul: BodyLowerResult = emit_int_expr(acc, rhs_mul, locals, submission)
            if !rr_mul.ok {
                return rr_mul
            }
            return body_lower_ok(append_msil_line(rr_mul.instructions, "        mul"), "")
        }
        # `a.length() >= b.length()` / `> ` / `< ` / `<= ` / `== `
        let mut cmp_op: utf8 = ""
        let mut rhs_cmp: utf8 = ""
        if after_len.starts_with(">= ") {
            cmp_op = "ge"
            rhs_cmp = after_len.slice(3, after_len.length() - 3).trim()
        }
        else if after_len.starts_with("<= ") {
            cmp_op = "le"
            rhs_cmp = after_len.slice(3, after_len.length() - 3).trim()
        }
        else if after_len.starts_with("> ") {
            cmp_op = "gt"
            rhs_cmp = after_len.slice(2, after_len.length() - 2).trim()
        }
        else if after_len.starts_with("< ") {
            cmp_op = "lt"
            rhs_cmp = after_len.slice(2, after_len.length() - 2).trim()
        }
        else if after_len.starts_with("== ") {
            cmp_op = "eq"
            rhs_cmp = after_len.slice(3, after_len.length() - 3).trim()
        }
        else if after_len.starts_with("!= ") {
            cmp_op = "ne"
            rhs_cmp = after_len.slice(3, after_len.length() - 3).trim()
        }
        if cmp_op.length() > 0 {
            let rr: BodyLowerResult = emit_int_expr(acc, rhs_cmp, locals, submission)
            if !rr.ok {
                return rr
            }
            if cmp_op == "gt" {
                return body_lower_ok(append_msil_line(rr.instructions, "        cgt"), "")
            }
            if cmp_op == "lt" {
                return body_lower_ok(append_msil_line(rr.instructions, "        clt"), "")
            }
            if cmp_op == "eq" {
                return body_lower_ok(append_msil_line(rr.instructions, "        ceq"), "")
            }
            if cmp_op == "ge" {
                let mut a2: utf8 = append_msil_line(rr.instructions, "        clt")
                a2 = append_msil_line(a2, "        ldc.i4.0")
                a2 = append_msil_line(a2, "        ceq")
                return body_lower_ok(a2, "")
            }
            if cmp_op == "le" {
                let mut a2: utf8 = append_msil_line(rr.instructions, "        cgt")
                a2 = append_msil_line(a2, "        ldc.i4.0")
                a2 = append_msil_line(a2, "        ceq")
                return body_lower_ok(a2, "")
            }
            if cmp_op == "ne" {
                let mut a2: utf8 = append_msil_line(rr.instructions, "        ceq")
                a2 = append_msil_line(a2, "        ldc.i4.0")
                a2 = append_msil_line(a2, "        ceq")
                return body_lower_ok(a2, "")
            }
        }
        return body_lower_fail(".length() 后缀尚不支持：" + after_len)
        }
    }
    # Index before `+` / comparisons so `args⁅i + 1⁆` is not split on ` + `.
    let early_idx: BodyLowerResult = emit_index_expr(acc, e, locals, submission)
    if early_idx.ok {
        return early_idx
    }
    if early_idx.error.length() > 0 && !early_idx.error.starts_with("soft:") {
        return early_idx
    }
    # `arr⁅i⁆.field` — only when index reported a trailing field (avoid value↔int recurse).
    if early_idx.error == "soft:index-suffix" {
        let trail_d: i32 = last_index_of_at_paren_depth0(e, ".")
        if trail_d > 0 {
            let left_i: utf8 = e.slice(0, trail_d).trim()
            let field_i: utf8 = e.slice(trail_d + 1, e.length() - trail_d - 1).trim()
            if field_i.length() > 0 && field_i.index_of("(") < 0 && field_i.index_of(" ") < 0 {
                let idx_r2: BodyLowerResult = emit_index_expr(acc, left_i, locals, submission)
                if idx_r2.ok {
                    let mut base_n: utf8 = left_i
                    let mut cut_n: i32 = index_of_at_paren_depth0(left_i, "⁅")
                    if cut_n < 0 {
                        cut_n = index_of_at_paren_depth0(left_i, "[")
                    }
                    if cut_n > 0 {
                        base_n = left_i.slice(0, cut_n).trim()
                    }
                    # Field path base: `manifest.dependencies`
                    if cut_n < 0 && left_i.contains(".") {
                        base_n = left_i
                    }
                    let bl_n: BodyLocal = find_local(locals, base_n)
                    let mut elem_n: utf8 = bl_n.clr_type
                    if elem_n.ends_with("[]") {
                        elem_n = elem_n.slice(0, elem_n.length() - 2).trim()
                    }
                    if elem_n.starts_with("class ") {
                        elem_n = elem_n.slice(6, elem_n.length() - 6).trim()
                    }
                    # `obj.field⁅i⁆` — load field type from struct when base is dotted.
                    if left_i.contains(".") && cut_n > 0 {
                        let obj_path: utf8 = left_i.slice(0, cut_n).trim()
                        let loaded_b: PathLoadResult = emit_load_path(acc, obj_path, locals, structs)
                        if loaded_b.ok {
                            let mut et2: utf8 = loaded_b.result_type
                            if et2.ends_with("[]") {
                                et2 = et2.slice(0, et2.length() - 2).trim()
                            }
                            if et2.starts_with("class ") {
                                et2 = et2.slice(6, et2.length() - 6).trim()
                            }
                            elem_n = et2
                            # Re-emit index from already-loaded array: use idx_r2 (includes load).
                        }
                    }
                    let mut ft_n: utf8 = "string"
                    if field_i == "slot" || field_i == "tag" {
                        ft_n = "int32"
                    }
                    else if field_i == "is_arg" || field_i == "ok" {
                        ft_n = "bool"
                    }
                    if elem_n.length() > 0 {
                        return body_lower_ok(append_msil_line(idx_r2.instructions, "        ldfld " + ft_n + " " + elem_n + "::" + msil_id(field_i)), "")
                    }
                }
            }
        }
    }
    # `ch >= "A"` / string relational → String.Compare
    let mut rel_at2: i32 = -1
    let mut rel_op2: utf8 = ""
    let mut rel_oplen: i32 = 4
    let ge_s: i32 = index_of_at_paren_depth0(e, " >= ")
    let le_s: i32 = index_of_at_paren_depth0(e, " <= ")
    let gt_s: i32 = index_of_at_paren_depth0(e, " > ")
    let lt_s: i32 = index_of_at_paren_depth0(e, " < ")
    if ge_s > 0 {
        rel_at2 = ge_s
        rel_op2 = "ge"
    }
    else if le_s > 0 {
        rel_at2 = le_s
        rel_op2 = "le"
    }
    else if gt_s > 0 {
        rel_at2 = gt_s
        rel_op2 = "gt"
        rel_oplen = 3
    }
    else if lt_s > 0 {
        rel_at2 = lt_s
        rel_op2 = "lt"
        rel_oplen = 3
    }
    if rel_at2 > 0 {
        let left_s: utf8 = e.slice(0, rel_at2).trim()
        let right_s: utf8 = e.slice(rel_at2 + rel_oplen, e.length() - rel_at2 - rel_oplen).trim()
        if is_string_literal_expr(left_s) || is_string_literal_expr(right_s) || find_local(locals, left_s).clr_type == "string" || find_local(locals, right_s).clr_type == "string" {
            let lr: BodyLowerResult = emit_value_expr(acc, left_s, locals, submission)
            if !lr.ok {
                return lr
            }
            let rr: BodyLowerResult = emit_value_expr(lr.instructions, right_s, locals, submission)
            if !rr.ok {
                return rr
            }
            let mut acc_rel: utf8 = append_msil_line(rr.instructions, "        call int32 [mscorlib]System.String::Compare(string, string)")
            acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
            if rel_op2 == "lt" {
                return body_lower_ok(append_msil_line(acc_rel, "        clt"), "")
            }
            if rel_op2 == "gt" {
                return body_lower_ok(append_msil_line(acc_rel, "        cgt"), "")
            }
            if rel_op2 == "le" {
                acc_rel = append_msil_line(acc_rel, "        cgt")
                acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
                return body_lower_ok(append_msil_line(acc_rel, "        ceq"), "")
            }
            acc_rel = append_msil_line(acc_rel, "        clt")
            acc_rel = append_msil_line(acc_rel, "        ldc.i4.0")
            return body_lower_ok(append_msil_line(acc_rel, "        ceq"), "")
        }
    }
    let le: i32 = index_of_at_paren_depth0(e, " <= ")
    if le > 0 {
        let left: utf8 = e.slice(0, le).trim()
        let right: utf8 = e.slice(le + 4, e.length() - le - 4).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        # a <= b → !(a > b)
        let mut acc2: utf8 = append_msil_line(right_r.instructions, "        cgt")
        acc2 = append_msil_line(acc2, "        ldc.i4.0")
        acc2 = append_msil_line(acc2, "        ceq")
        return body_lower_ok(acc2, "")
    }
    let ge: i32 = index_of_at_paren_depth0(e, " >= ")
    if ge > 0 {
        let left: utf8 = e.slice(0, ge).trim()
        let right: utf8 = e.slice(ge + 4, e.length() - ge - 4).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        # a >= b → !(a < b)
        let mut acc2: utf8 = append_msil_line(right_r.instructions, "        clt")
        acc2 = append_msil_line(acc2, "        ldc.i4.0")
        acc2 = append_msil_line(acc2, "        ceq")
        return body_lower_ok(acc2, "")
    }
    let lt: i32 = index_of_at_paren_depth0(e, " < ")
    if lt > 0 {
        let left: utf8 = e.slice(0, lt).trim()
        let right: utf8 = e.slice(lt + 3, e.length() - lt - 3).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        clt"), "")
    }
    let gt: i32 = index_of_at_paren_depth0(e, " > ")
    if gt > 0 {
        let left: utf8 = e.slice(0, gt).trim()
        let right: utf8 = e.slice(gt + 3, e.length() - gt - 3).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        cgt"), "")
    }
    let eq2: i32 = index_of_at_paren_depth0(e, " == ")
    if eq2 > 0 {
        let left: utf8 = e.slice(0, eq2).trim()
        let right: utf8 = e.slice(eq2 + 4, e.length() - eq2 - 4).trim()
        if is_string_literal_expr(left) || is_string_literal_expr(right) || find_local(locals, left).clr_type == "string" || find_local(locals, right).clr_type == "string" || looks_like_call_expr(left) || looks_like_call_expr(right) {
            let se: BodyLowerResult = try_emit_string_equality(acc, e, locals, submission)
            if se.ok {
                return se
            }
            let lr: BodyLowerResult = emit_value_expr(acc, left, locals, submission)
            if !lr.ok {
                return lr
            }
            let rr: BodyLowerResult = emit_value_expr(lr.instructions, right, locals, submission)
            if !rr.ok {
                return rr
            }
            return body_lower_ok(append_msil_line(rr.instructions, "        call bool [mscorlib]System.String::op_Equality(string, string)"), "")
        }
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        ceq"), "")
    }
    let ne2: i32 = index_of_at_paren_depth0(e, " != ")
    if ne2 > 0 {
        let left: utf8 = e.slice(0, ne2).trim()
        let right: utf8 = e.slice(ne2 + 4, e.length() - ne2 - 4).trim()
        if is_string_literal_expr(left) || is_string_literal_expr(right) || find_local(locals, left).clr_type == "string" || find_local(locals, right).clr_type == "string" {
            let se: BodyLowerResult = try_emit_string_equality(acc, e, locals, submission)
            if se.ok {
                return se
            }
        }
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        let mut acc_ne: utf8 = append_msil_line(right_r.instructions, "        ceq")
        acc_ne = append_msil_line(acc_ne, "        ldc.i4.0")
        acc_ne = append_msil_line(acc_ne, "        ceq")
        return body_lower_ok(acc_ne, "")
    }
    # Left-assoc: split on *last* depth-0 op so `a - b - c` → `(a - b) - c`.
    let plus: i32 = last_index_of_at_paren_depth0(e, " + ")
    if plus > 0 {
        let left: utf8 = e.slice(0, plus).trim()
        let right: utf8 = e.slice(plus + 3, e.length() - plus - 3).trim()
        # Never int-add string chains — emit_value_expr owns Concat.
        # Do not treat `arr⁅i⁆.slot + 1` as string (⁅ alone is not enough).
        if right.starts_with(dq()) || left.starts_with(dq()) || left.contains(dq()) || right.contains(dq()) || find_local(locals, left).clr_type == "string" || find_local(locals, right).clr_type == "string" || right.contains(".slice(") || left.contains(".slice(") || left.starts_with("format(") || right.starts_with("format(") || left.contains("format(") || right.contains("format(") || (left.contains(" + ") && (left.contains(dq()) || left.contains("format("))) {
            return body_lower_fail("soft:str-concat")
        }
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        add"), "")
    }
    let minus: i32 = last_index_of_at_paren_depth0(e, " - ")
    if minus > 0 {
        let left: utf8 = e.slice(0, minus).trim()
        let right: utf8 = e.slice(minus + 3, e.length() - minus - 3).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        sub"), "")
    }
    let mul: i32 = last_index_of_at_paren_depth0(e, " * ")
    if mul > 0 {
        let left: utf8 = e.slice(0, mul).trim()
        let right: utf8 = e.slice(mul + 3, e.length() - mul - 3).trim()
        let left_r: BodyLowerResult = emit_int_expr(acc, left, locals, submission)
        if !left_r.ok {
            return left_r
        }
        let right_r: BodyLowerResult = emit_int_expr(left_r.instructions, right, locals, submission)
        if !right_r.ok {
            return right_r
        }
        return body_lower_ok(append_msil_line(right_r.instructions, "        mul"), "")
    }
    let mut all_dig: bool = e.length() > 0
    let mut di: i32 = 0
    if e.length() > 0 && e.slice(0, 1) == "-" {
        di = 1
    }
    if di >= e.length() {
        all_dig = false
    }
    while di < e.length() {
        let ch: utf8 = e.slice(di, 1)
        if ch != "0" && ch != "1" && ch != "2" && ch != "3" && ch != "4" && ch != "5" && ch != "6" && ch != "7" && ch != "8" && ch != "9" {
            all_dig = false
        }
        di = di + 1
    }
    if all_dig {
        return body_lower_ok(append_ldc_i4_digits(acc, e), "")
    }
    if e == "true" {
        return body_lower_ok(append_msil_line(acc, "        ldc.i4.1"), "")
    }
    if e == "false" {
        return body_lower_ok(append_msil_line(acc, "        ldc.i4.0"), "")
    }
    # args[0] / args⁅0⁆
    let idx_result: BodyLowerResult = emit_index_expr(acc, e, locals, submission)
    if idx_result.ok {
        return idx_result
    }
    # `s.index_of(...)` / `s.last_index_of(...)` — not `a.contains(x) || b.contains(y)`.
    if index_of_at_paren_depth0(e, " || ") < 0 && index_of_at_paren_depth0(e, " && ") < 0 && (e.contains(".index_of(") || e.contains(".last_index_of(") || e.contains(".slice(") || e.contains(".starts_with(") || e.contains(".ends_with(") || e.contains(".contains(") || e.contains(".trim(") || e.contains(".replace(") || e.contains(".to_lower(") || e.ends_with(".to_lower()") || e.ends_with(".trim()")) {
        let sm: BodyLowerResult = emit_string_receiver_call(acc, e, locals, structs, submission)
        if sm.ok {
            return sm
        }
        if sm.error.length() > 0 && !sm.error.starts_with("字符串方法后还有后缀") {
            return sm
        }
    }
    # `find_local(locals, e).slot` / `find_unite_variant(...).tag` — call then int field.
    let trail_i: i32 = last_index_of_at_paren_depth0(e, ".")
    if trail_i > 0 {
        let left_c: utf8 = e.slice(0, trail_i).trim()
        let field_c: utf8 = e.slice(trail_i + 1, e.length() - trail_i - 1).trim()
        if looks_like_call_expr(left_c) && field_c.length() > 0 && field_c.index_of("(") < 0 && field_c.index_of(" ") < 0 {
            let cr: BodyLowerResult = emit_call_expr(acc, left_c, locals, submission)
            if !cr.ok {
                return cr
            }
            let open_c: i32 = left_c.index_of("(")
            let cname: utf8 = left_c.slice(0, open_c).trim()
            let ret_clr: utf8 = lookup_callee_return_clr(submission, cname)
            let mut type_name: utf8 = ret_clr.trim()
            if type_name.starts_with("class ") {
                type_name = type_name.slice(6, type_name.length() - 6).trim()
            }
            let mut ft: utf8 = "int32"
            if field_c == "name" || field_c == "clr_type" || field_c == "text" || field_c == "error" {
                ft = "string"
            }
            else if field_c == "ok" || field_c == "is_arg" {
                ft = "bool"
            }
            if type_name.length() > 0 {
                if ft == "string" {
                    return body_lower_fail("整型上下文得到：string 来自 " + e)
                }
                return body_lower_ok(append_msil_line(cr.instructions, "        ldfld " + ft + " " + type_name + "::" + msil_id(field_c)), "")
            }
            # Known result structs when scrape missed.
            let mut home: utf8 = ""
            if cname == "find_local" {
                home = "BodyLocal"
            }
            else if cname == "find_unite_variant" {
                home = "ParsedUniteVariant"
            }
            else if cname == "find_struct_field" {
                home = "ParsedStructField"
            }
            else if cname == "find_struct_def" {
                home = "ParsedStruct"
            }
            else if cname == "find_unite_def" {
                home = "ParsedUnite"
            }
            if home.length() > 0 {
                return body_lower_ok(append_msil_line(cr.instructions, "        ldfld int32 " + home + "::" + msil_id(field_c)), "")
            }
        }
    }
    if e.index_of(".") >= 0 && e.index_of(" ") < 0 && e.index_of("(") < 0 {
        let loaded: PathLoadResult = emit_load_path(acc, e, locals, structs)
        if loaded.ok {
            if loaded.result_type == "int32" || loaded.result_type == "bool" {
                return body_lower_ok(loaded.instructions, "")
            }
            return body_lower_fail("整型上下文得到：" + loaded.result_type + " 来自 " + e)
        }
        if loaded.error.length() > 0 && !loaded.error.starts_with("soft:") {
            return body_lower_fail(loaded.error)
        }
    }
    let local: BodyLocal = find_local(locals, e)
    if local.slot >= 0 {
        if local.clr_type == "int32" || local.clr_type == "bool" {
            return body_lower_ok(append_ld_slot(acc, local), "")
        }
        return body_lower_fail("非整型局部：" + e)
    }
    if e.starts_with("push(") {
        return body_lower_fail("push 仅支持赋值或语句形式： " + e)
    }
    return body_lower_fail("无法 lowering 整型表达式：" + e)
}

micro emit_std_io_call(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let e: utf8 = expr.trim()
    if e == "std.io.get_current_directory()" {
        return body_lower_ok(append_msil_line(msil, "        call string [System.IO.FileSystem]System.IO.Directory::GetCurrentDirectory()"), "")
    }
    if e.starts_with("std.io.file_exists(") && e.ends_with(")") {
        let arg: utf8 = e.slice(19, e.length() - 20).trim()
        let ar: BodyLowerResult = emit_stack_expr(msil, arg, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        call bool [System.IO.FileSystem]System.IO.File::Exists(string)"), "")
    }
    if e.starts_with("std.io.directory_exists(") && e.ends_with(")") {
        let arg: utf8 = e.slice(24, e.length() - 25).trim()
        let ar: BodyLowerResult = emit_stack_expr(msil, arg, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        call bool [System.IO.FileSystem]System.IO.Directory::Exists(string)"), "")
    }
    if e.starts_with("std.io.read_file_text(") && e.ends_with(")") {
        let arg: utf8 = e.slice(22, e.length() - 23).trim()
        let ar: BodyLowerResult = emit_stack_expr(msil, arg, locals, submission)
        if !ar.ok {
            return ar
        }
        return body_lower_ok(append_msil_line(ar.instructions, "        call string [System.IO.FileSystem]System.IO.File::ReadAllText(string)"), "")
    }
    if e.starts_with("std.io.write_file_text(") && e.ends_with(")") {
        let open: i32 = e.index_of("(")
        let close: i32 = matching_close_paren(e, open)
        let arglist: utf8 = e.slice(open + 1, close - open - 1).trim()
        let args: [utf8] = split_call_args(arglist)
        if args.length() != 2 {
            return body_lower_fail("write_file_text 需要两参数：" + e)
        }
        let a0: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !a0.ok {
            return a0
        }
        let a1: BodyLowerResult = emit_stack_expr(a0.instructions, args⁅1⁆, locals, submission)
        if !a1.ok {
            return a1
        }
        # File.WriteAllText → void; leave bool true for `-> bool` callers.
        let mut acc: utf8 = append_msil_line(a1.instructions, "        call void [System.IO.FileSystem]System.IO.File::WriteAllText(string, string)")
        acc = append_msil_line(acc, "        ldc.i4.1")
        return body_lower_ok(acc, "")
    }
    # Value form for `if !std.io.create_directory(path)` — DirectoryInfo non-null → true.
    if e.starts_with("std.io.create_directory(") && e.ends_with(")") {
        let open: i32 = e.index_of("(")
        let close: i32 = matching_close_paren(e, open)
        let arg: utf8 = e.slice(open + 1, close - open - 1).trim()
        let ar: BodyLowerResult = emit_stack_expr(msil, arg, locals, submission)
        if !ar.ok {
            return ar
        }
        let mut acc_cd: utf8 = append_msil_line(ar.instructions, "        call class [System.IO.FileSystem]System.IO.DirectoryInfo [System.IO.FileSystem]System.IO.Directory::CreateDirectory(string)")
        acc_cd = append_msil_line(acc_cd, "        ldnull")
        acc_cd = append_msil_line(acc_cd, "        cgt.un")
        return body_lower_ok(acc_cd, "")
    }
    if e.starts_with("std.io.get_files(") && e.ends_with(")") {
        let open: i32 = e.index_of("(")
        let close: i32 = matching_close_paren(e, open)
        let arglist: utf8 = e.slice(open + 1, close - open - 1).trim()
        let args: [utf8] = split_call_args(arglist)
        if args.length() != 3 {
            return body_lower_fail("get_files 需要三参数：" + e)
        }
        let a0: BodyLowerResult = emit_stack_expr(msil, args⁅0⁆, locals, submission)
        if !a0.ok {
            return a0
        }
        let a1: BodyLowerResult = emit_stack_expr(a0.instructions, args⁅1⁆, locals, submission)
        if !a1.ok {
            return a1
        }
        let mut acc: utf8 = a1.instructions
        let rec: utf8 = args⁅2⁆.trim()
        if rec == "true" {
            acc = append_msil_line(acc, "        ldc.i4.1")
        }
        else if rec == "false" {
            acc = append_msil_line(acc, "        ldc.i4.0")
        }
        else {
            let a2: BodyLowerResult = emit_bool_expr(acc, rec, locals, submission)
            if !a2.ok {
                return a2
            }
            acc = a2.instructions
        }
        # SearchOption: 0 = TopDirectoryOnly, 1 = AllDirectories
        return body_lower_ok(append_msil_line(acc, "        call string[] [System.IO.FileSystem]System.IO.Directory::GetFiles(string, string, valuetype [System.IO.FileSystem]System.IO.SearchOption)"), "")
    }
    return body_lower_fail("soft:io-none")
}

micro emit_struct_literal(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let e: utf8 = expr.trim()
    let brace: i32 = e.index_of("{")
    if brace <= 0 || !e.ends_with("}") {
        return body_lower_fail("非结构字面量：" + e)
    }
    let name: utf8 = e.slice(0, brace).trim()
    let structs: [ParsedStruct] = submission.struct_defs
    let st: ParsedStruct = find_struct_def(structs, name)
    if st.name.length() == 0 {
        return body_lower_fail("未知结构字面量类型：" + name)
    }
    let inner: utf8 = e.slice(brace + 1, e.length() - brace - 2).trim()
    let mut parts: [utf8] = []
    if msil.length() > 0 {
        parts = push(parts, msil)
    }
    parts = push(parts, "        newobj instance void " + name + "::.ctor()\n")
    # Split fields on top-level commas.
    let fields: [utf8] = split_call_args(inner)
    let mut fi: usize = 0
    while fi < fields.length() {
        let piece: utf8 = fields⁅fi⁆.trim()
        if piece.length() == 0 {
            fi = fi + 1
            continue
        }
        let colon: i32 = piece.index_of(":")
        if colon <= 0 {
            return body_lower_fail("结构字段缺少冒号：" + piece)
        }
        let fname: utf8 = piece.slice(0, colon).trim()
        let fexpr: utf8 = piece.slice(colon + 1, piece.length() - colon - 1).trim()
        let field: ParsedStructField = find_struct_field(st, fname)
        if field.name.length() == 0 {
            return body_lower_fail("结构无此字段：" + name + "." + fname)
        }
        let ft: utf8 = msil_field_type(field.type_text, structs)
        parts = push(parts, "        dup\n")
        if fexpr == "[]" && ft.ends_with("[]") {
            let elem: utf8 = ft.slice(0, ft.length() - 2).trim()
            parts = push(parts, "        ldc.i4.0\n")
            if elem == "string" {
                parts = push(parts, "        newarr [mscorlib]System.String\n")
            }
            else if elem.starts_with("class ") {
                let en: utf8 = elem.slice(6, elem.length() - 6).trim()
                parts = push(parts, "        newarr " + en + "\n")
            }
            else if elem == "uint8" {
                parts = push(parts, "        newarr [mscorlib]System.Byte\n")
            }
            else {
                parts = push(parts, "        newarr [mscorlib]System.Object\n")
            }
        }
        else if looks_like_struct_literal(fexpr) {
            let nest: BodyLowerResult = emit_struct_literal("", fexpr, locals, submission)
            if !nest.ok {
                return nest
            }
            parts = push(parts, nest.instructions)
        }
        else if looks_like_call_expr(fexpr) {
            let cr: BodyLowerResult = emit_call_expr("", fexpr, locals, submission)
            if !cr.ok {
                return cr
            }
            parts = push(parts, cr.instructions)
        }
        else if fexpr.starts_with("if ") {
            return body_lower_fail("结构字面量暂不支持 if 字段：" + fexpr)
        }
        else {
            let vr: BodyLowerResult = emit_value_expr("", fexpr, locals, submission)
            if !vr.ok {
                return vr
            }
            parts = push(parts, vr.instructions)
        }
        parts = push(parts, "        stfld " + ft + " " + name + "::" + msil_id(fname) + "\n")
        fi = fi + 1
    }
    return body_lower_ok(join_msil_parts(parts), "")
}

micro looks_like_struct_literal(expr: utf8) -> bool {
    let e: utf8 = expr.trim()
    if e.starts_with(dq()) || e.starts_with("'") || e.starts_with("if ") {
        return false
    }
    let brace: i32 = e.index_of("{")
    if brace <= 0 || !e.ends_with("}") {
        return false
    }
    let name: utf8 = e.slice(0, brace).trim()
    if name.length() == 0 || name.contains(" ") || name.contains("(") || name.contains("\\") {
        return false
    }
    let mut i: i32 = 0
    while i < name.length() {
        let ch: utf8 = name.slice(i, 1)
        if !is_ident_continue_char(ch) {
            return false
        }
        i = i + 1
    }
    return true
}

micro submission_with_structs(structs: [ParsedStruct]) -> FragmentSubmission {
    return FragmentSubmission {
        module_name: "",
        fragment_id: "functions",
        exported_operations: [],
        entry_operation: "",
        external_import_bindings: [],
        external_call_edges: [],
        internal_call_edges: [],
        literal_returns: [],
        literal_return_values: [],
        integer_returns: [],
        integer_return_values: [],
        void_returns: [],
        emit_blockers: [],
        body_symbols: [],
        body_sources: [],
        struct_defs: structs,
        unite_defs: []
    }
}

micro clr_class_name_for_cast(type_text: utf8, structs: [ParsedStruct]) -> utf8 {
    let t: utf8 = type_text.trim()
    if t == "any" || t == "`any`" || t == "object" {
        return "[mscorlib]System.Object"
    }
    let clr: utf8 = clr_type_for_annotation_with_structs(type_text, structs)
    if clr.starts_with("class ") && clr.ends_with("[]") {
        # class VonField[] → VonField[]
        return clr.slice(6, clr.length() - 6).trim()
    }
    if clr.starts_with("class ") {
        return clr.slice(6, clr.length() - 6).trim()
    }
    if clr == "string" {
        return "[mscorlib]System.String"
    }
    if clr == "bool" {
        return "bool"
    }
    if clr == "int32" || clr == "int64" || clr == "uint8" {
        return clr
    }
    if clr == "string[]" {
        return "string[]"
    }
    if clr.ends_with("[]") {
        return clr
    }
    let n: utf8 = nominal_type_name(type_text)
    if n.length() > 0 && n != "T" {
        return n
    }
    return ""
}

# Hardcoded tags when unite scrape / fragment unite_defs is empty on CLR.
micro bootstrap_unite_variant_tag(sum_name: utf8, variant: utf8) -> i32 {
    if sum_name == "Option" {
        if variant == "Some" { return 0 }
        if variant == "None" { return 1 }
    }
    if sum_name == "VonValue" {
        if variant == "Text" { return 0 }
        if variant == "Flag" { return 1 }
        if variant == "Number" { return 2 }
        if variant == "Name" { return 3 }
        if variant == "Array" { return 4 }
        if variant == "Object" { return 5 }
        if variant == "Empty" { return 6 }
    }
    if sum_name == "VonTokenKind" {
        if variant == "Identifier" { return 0 }
        if variant == "StringLiteral" { return 1 }
        if variant == "NumberLiteral" { return 2 }
        if variant == "BooleanLiteral" { return 3 }
        if variant == "LeftBrace" { return 4 }
        if variant == "RightBrace" { return 5 }
        if variant == "LeftBracket" { return 6 }
        if variant == "RightBracket" { return 7 }
        if variant == "Colon" { return 8 }
        if variant == "Comma" { return 9 }
        if variant == "EndOfFile" { return 10 }
    }
    if sum_name == "VonParseResult" {
        if variant == "Fine" { return 0 }
        if variant == "Fail" { return 1 }
    }
    return -1
}

# Resolve CLR box type for unite payload stored in `object` field (bool/i32 → box).
micro unite_payload_box_type(sum_name: utf8, variant: utf8, submission: FragmentSubmission) -> utf8 {
    let u: ParsedUnite = find_unite_def(submission.unite_defs, sum_name)
    let mut pty: utf8 = ""
    if u.name.length() > 0 {
        let v: ParsedUniteVariant = find_unite_variant(u, variant)
        pty = v.payload_type.trim()
    }
    if pty.length() == 0 {
        if sum_name == "VonValue" && variant == "Flag" {
            pty = "bool"
        }
    }
    if pty == "bool" || pty == "flag" {
        return "bool"
    }
    if pty == "i32" || pty == "int32" || pty == "usize" || pty == "isize" || pty == "i64" || pty == "int64" {
        if pty == "i64" || pty == "int64" {
            return "int64"
        }
        return "int32"
    }
    if pty == "u8" || pty == "uint8" || pty == "byte" {
        return "uint8"
    }
    return ""
}

# Fine/Fail → tagged unite object (Rust CLR: newobj + stfld tag + stfld payload).
micro emit_unite_variant_ctor(msil: utf8, variant: utf8, payload_expr: utf8, sum_name: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let u: ParsedUnite = find_unite_def(submission.unite_defs, sum_name)
    let mut tag: i32 = -1
    if u.name.length() > 0 {
        let v: ParsedUniteVariant = find_unite_variant(u, variant)
        tag = v.tag
    }
    if tag < 0 {
        tag = bootstrap_unite_variant_tag(sum_name, variant)
    }
    if tag < 0 {
        return body_lower_fail("未知 unite：" + sum_name + " / " + variant)
    }
    let class_name: utf8 = sum_name
    let box_ty: utf8 = unite_payload_box_type(sum_name, variant, submission)
    let mut parts: [utf8] = []
    if msil.length() > 0 {
        parts = push(parts, msil)
    }
    parts = push(parts, "        newobj instance void " + class_name + "::.ctor()\n")
    parts = push(parts, "        dup\n")
    parts = push(parts, append_ldc_i4_digits("", format("{}", tag)))
    parts = push(parts, "        stfld int32 " + class_name + "::tag\n")
    parts = push(parts, "        dup\n")
    if payload_expr.trim().length() == 0 {
        parts = push(parts, "        ldnull\n")
    }
    else {
        let pr: BodyLowerResult = emit_stack_expr("", payload_expr, locals, submission)
        if !pr.ok {
            return pr
        }
        parts = push(parts, pr.instructions)
        # Value-type payloads (Flag's bool) must box before stfld object.
        if box_ty.length() > 0 {
            parts = push(parts, "        box " + box_ty + "\n")
        }
    }
    parts = push(parts, "        stfld object " + class_name + "::payload\n")
    return body_lower_ok(join_msil_parts(parts), "")
}

micro infer_unite_sum_name(expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> utf8 {
    let e: utf8 = expr.trim()
    # Field path: `token.kind` / `tail.kind` → field's unite type (VonTokenKind).
    let dot_sc: i32 = last_index_of_text(e, ".")
    if dot_sc > 0 && e.index_of("(") < 0 {
        let obj_p: utf8 = e.slice(0, dot_sc).trim()
        let field_p: utf8 = e.slice(dot_sc + 1, e.length() - dot_sc - 1).trim()
        let obj_l: BodyLocal = find_local(locals, obj_p)
        if obj_l.slot >= 0 {
            let mut type_name: utf8 = obj_l.clr_type.trim()
            if type_name.starts_with("class ") {
                type_name = type_name.slice(6, type_name.length() - 6).trim()
            }
            let st: ParsedStruct = find_struct_def(submission.struct_defs, type_name)
            let sf: ParsedStructField = find_struct_field(st, field_p)
            let fnom: utf8 = nominal_type_name(sf.type_text)
            if fnom.length() > 0 && find_unite_def(submission.unite_defs, fnom).name.length() > 0 {
                return fnom
            }
            if type_name == "VonToken" && field_p == "kind" {
                if find_unite_def(submission.unite_defs, "VonTokenKind").name.length() > 0 {
                    return "VonTokenKind"
                }
            }
        }
    }
    let local0: BodyLocal = find_local(locals, e)
    if local0.slot >= 0 {
        if local0.clr_type == "class VonValue" || local0.clr_type == "object" {
            if find_unite_def(submission.unite_defs, "VonValue").name.length() > 0 {
                # Prefer VonValue when matching a von document/field value.
                if e == "value" || e == "document" || e == "ws_field" || e == "auto_link" || e == "deps_value" || e == "publish_config" || e == "core_val" || e == "std_val" || local0.clr_type == "class VonValue" {
                    return "VonValue"
                }
            }
        }
        let loc_nom: utf8 = ""
        if local0.clr_type.starts_with("class ") {
            loc_nom = local0.clr_type.slice(6, local0.clr_type.length() - 6).trim()
        }
        if loc_nom.length() > 0 && find_unite_def(submission.unite_defs, loc_nom).name.length() > 0 {
            return loc_nom
        }
    }
    if looks_like_call_expr(e) {
        let open: i32 = e.index_of("(")
        let cname: utf8 = e.slice(0, open).trim()
        let ret: utf8 = lookup_callee_return_clr(submission, cname)
        if ret.starts_with("class ") {
            let n: utf8 = ret.slice(6, ret.length() - 6).trim()
            if find_unite_def(submission.unite_defs, n).name.length() > 0 {
                return n
            }
        }
        # Known von helpers — always VonParseResult (unite scrape may be empty on CLR).
        if cname == "lex_von_string" || cname == "lex_von" || cname == "parse_von" || cname == "parse_von_tokens" || cname == "parse_von_value" || cname == "von_parse_take_fine" || cname == "von_parse_take_fail" {
            return "VonParseResult"
        }
        # Return annotation may still be VonParseResult<T> text in body — use callee body.
        let mut i: usize = 0
        while i < submission.body_symbols.length() {
            if unqualified_symbol(submission.body_symbols⁅i⁆) == cname {
                let body: utf8 = ""
                if i < submission.body_sources.length() {
                    body = submission.body_sources⁅i⁆
                }
                let ty: utf8 = extract_return_type_text(body)
                let n: utf8 = nominal_type_name(ty)
                if find_unite_def(submission.unite_defs, n).name.length() > 0 {
                    return n
                }
            }
            i = i + 1
        }
    }
    let local: BodyLocal = find_local(locals, e)
    if local.slot >= 0 && local.clr_type.starts_with("class ") {
        let n: utf8 = local.clr_type.slice(6, local.clr_type.length() - 6).trim()
        if find_unite_def(submission.unite_defs, n).name.length() > 0 {
            return n
        }
    }
    return ""
}

micro infer_unite_type_arg(expr: utf8, submission: FragmentSubmission) -> utf8 {
    let e: utf8 = expr.trim()
    if !looks_like_call_expr(e) {
        return ""
    }
    let open: i32 = e.index_of("(")
    let cname: utf8 = e.slice(0, open).trim()
    let mut i: usize = 0
    while i < submission.body_symbols.length() {
        if unqualified_symbol(submission.body_symbols⁅i⁆) == cname {
            let body: utf8 = ""
            if i < submission.body_sources.length() {
                body = submission.body_sources⁅i⁆
            }
            let ty: utf8 = extract_return_type_text(body)
            if ty.length() > 0 {
                return apply_type_argument(ty)
            }
        }
        i = i + 1
    }
    return ""
}

micro payload_cast_class_for_arm(variant: utf8, sum_name: utf8, type_arg: utf8, submission: FragmentSubmission) -> utf8 {
    let u: ParsedUnite = find_unite_def(submission.unite_defs, sum_name)
    let v: ParsedUniteVariant = find_unite_variant(u, variant)
    let mut pty: utf8 = v.payload_type
    if pty == "T" || pty.length() == 0 {
        pty = type_arg
    }
    # VonValue arms when unite parse missed payload text.
    if pty.length() == 0 {
        if variant == "Object" {
            pty = "[VonField]"
        }
        else if variant == "Array" {
            pty = "[VonValue]"
        }
        else if variant == "Text" || variant == "Name" || variant == "Number" {
            pty = "utf8"
        }
        else if variant == "Flag" {
            pty = "bool"
        }
        else if variant == "Some" {
            pty = type_arg
            if pty.length() == 0 {
                pty = "any"
            }
        }
        else if variant == "Fine" {
            pty = type_arg
            if pty.length() == 0 {
                pty = "any"
            }
        }
    }
    let cast: utf8 = clr_class_name_for_cast(pty, submission.struct_defs)
    if cast.length() == 0 && (variant == "Some" || variant == "Fine") {
        return "[mscorlib]System.Object"
    }
    return cast
}

# Next top-level `case ` / `default:` / `else:` in match arm body (brace-depth 0).
micro find_next_match_arm_boundary(body_rest: utf8) -> i32 {
    # Returns start index of the newline before the next arm, or -1. Sets nothing — caller rescans for at.
    let mut sci: i32 = 0
    let mut brace_d: i32 = 0
    let mut in_s: utf8 = ""
    while sci < body_rest.length() {
        let chb: utf8 = body_rest.slice(sci, 1)
        if in_s.length() > 0 {
            if chb == in_s {
                in_s = ""
            }
            else {
                sci = string_lit_advance(body_rest, sci)
                continue
            }
            sci = sci + 1
            continue
        }
        if chb == dq() || chb == "'" {
            in_s = chb
            sci = sci + 1
            continue
        }
        if chb == "{" {
            brace_d = brace_d + 1
        }
        else if chb == "}" {
            brace_d = brace_d - 1
        }
        else if chb == "\n" && brace_d == 0 {
            let mut sj: i32 = sci + 1
            while sj < body_rest.length() {
                let w: utf8 = body_rest.slice(sj, 1)
                if w == " " || w == "\t" {
                    sj = sj + 1
                    continue
                }
                break
            }
            if sj + 5 <= body_rest.length() && body_rest.slice(sj, 5) == "case " {
                return sci
            }
            if sj + 8 <= body_rest.length() && body_rest.slice(sj, 8) == "default:" {
                return sci
            }
            if sj + 5 <= body_rest.length() && body_rest.slice(sj, 5) == "else:" {
                return sci
            }
        }
        sci = sci + 1
    }
    return -1
}

micro match_arm_start_after_newline(body_rest: utf8, newline_at: i32) -> i32 {
    let mut sj: i32 = newline_at + 1
    while sj < body_rest.length() {
        let w: utf8 = body_rest.slice(sj, 1)
        if w == " " || w == "\t" {
            sj = sj + 1
            continue
        }
        break
    }
    return sj
}

# `match expr { case Fine(x): ... case Fail(e): ... }` — ldfld tag then payload per arm.
micro emit_match_stmt(stmt: utf8, locals: [BodyLocal], lab: i32, submission: FragmentSubmission, continue_label: utf8, fn_ret_ty: utf8, break_label: utf8) -> BodyLowerResult {
    let s: utf8 = stmt.trim()
    if !s.starts_with("match ") {
        return body_lower_fail("非 match 语句：" + stmt)
    }
    let after: utf8 = s.slice(6, s.length() - 6).trim()
    let brace: i32 = index_of_brace_outside_string(after)
    if brace < 0 {
        return body_lower_fail("match 缺少体：" + stmt)
    }
    let scrut: utf8 = after.slice(0, brace).trim()
    let inner: utf8 = extract_function_inner_body("x" + after.slice(brace, after.length() - brace))
    let sum_name: utf8 = infer_unite_sum_name(scrut, locals, submission)
    if sum_name.length() == 0 {
        return body_lower_fail("match 无法解析 unite 类型：" + scrut)
    }
    let type_arg: utf8 = infer_unite_type_arg(scrut, submission)
    let scrut_tmp: BodyLocal = find_local(locals, "__clr_match_scrut")
    if scrut_tmp.slot < 0 {
        return body_lower_fail("match 缺少临时局部 __clr_match_scrut")
    }
    let mut parts: [utf8] = []
    let sr: BodyLowerResult = emit_stack_expr("", scrut, locals, submission)
    if !sr.ok {
        return sr
    }
    parts = push(parts, append_stloc_slot(sr.instructions, scrut_tmp.slot))
    let end_l: utf8 = "ME" + format("{}", lab)
    let mut next_lab: i32 = lab + 1
    let mut end_used: bool = false
    # Split arms on top-level `case `
    let mut rest: utf8 = inner.trim()
    let mut saw_arm: bool = false
    while rest.starts_with("case ") {
        let arm_after: utf8 = rest.slice(5, rest.length() - 5).trim()
        let colon: i32 = arm_after.index_of(":")
        if colon < 0 {
            return body_lower_fail("match case 缺少冒号：" + rest)
        }
        let pat: utf8 = arm_after.slice(0, colon).trim()
        let body_rest: utf8 = arm_after.slice(colon + 1, arm_after.length() - colon - 1)
        let next_case: i32 = find_next_match_arm_boundary(body_rest)
        let mut arm_body: utf8 = body_rest
        if next_case >= 0 {
            let next_case_at: i32 = match_arm_start_after_newline(body_rest, next_case)
            arm_body = body_rest.slice(0, next_case)
            rest = body_rest.slice(next_case_at, body_rest.length() - next_case_at).trim()
        }
        else {
            rest = ""
        }
        let popen: i32 = pat.index_of("(")
        let pclose: i32 = last_index_of_text(pat, ")")
        let mut vname: utf8 = ""
        let mut bind: utf8 = ""
        let mut nullary: bool = false
        if popen > 0 && pclose > popen {
            vname = pat.slice(0, popen).trim()
            bind = pat.slice(popen + 1, pclose - popen - 1).trim()
        }
        else if pat.index_of(" ") < 0 && pat.length() > 0 {
            # Nullary: `case EndOfFile:` / `case Empty:`
            vname = pat
            nullary = true
        }
        else {
            return body_lower_fail("仅支持 case Variant(x) / case Variant：" + pat)
        }
        let uv: ParsedUniteVariant = find_unite_variant(find_unite_def(submission.unite_defs, sum_name), vname)
        let mut arm_tag: i32 = uv.tag
        if arm_tag < 0 {
            arm_tag = bootstrap_unite_variant_tag(sum_name, vname)
        }
        if arm_tag < 0 {
            return body_lower_fail("unite 无此变体：" + sum_name + "." + vname)
        }
        let cast_ty: utf8 = payload_cast_class_for_arm(vname, sum_name, type_arg, submission)
        let miss_l: utf8 = "MM" + format("{}", next_lab)
        next_lab = next_lab + 1
        parts = push(parts, append_ldloc_slot("", scrut_tmp.slot))
        parts = push(parts, "        ldfld int32 " + sum_name + "::tag\n")
        parts = push(parts, append_ldc_i4_digits("", format("{}", arm_tag)))
        parts = push(parts, "        bne.un " + miss_l + "\n")
        if nullary || bind == "_" || bind.length() == 0 {
            # No payload bind.
        }
        else {
            parts = push(parts, append_ldloc_slot("", scrut_tmp.slot))
            parts = push(parts, "        ldfld object " + sum_name + "::payload\n")
            if cast_ty.length() == 0 {
                return body_lower_fail("match 臂无法解析 payload 类型：" + vname + " / " + uv.payload_type)
            }
            let bind_l: BodyLocal = find_local(locals, bind)
            if bind_l.slot < 0 {
                return body_lower_fail("match 绑定未登记为局部：" + bind)
            }
            # Value-type payloads were boxed at ctor; unbox.any — never castclass bool/int32.
            if cast_ty == "bool" || cast_ty == "int32" || cast_ty == "int64" || cast_ty == "uint8" {
                parts = push(parts, "        unbox.any " + cast_ty + "\n")
            }
            else {
                parts = push(parts, "        castclass " + msil_cast_type(cast_ty) + "\n")
            }
            parts = push(parts, append_stloc_slot("", bind_l.slot))
        }
        let arm_stmts: [utf8] = split_top_level_statements(arm_body)
        let ar: BodyLowerResult = emit_statements_ret("", arm_stmts, locals, next_lab, submission, continue_label, fn_ret_ty, break_label)
        if !ar.ok {
            return ar
        }
        if ar.next_lab > next_lab {
            next_lab = ar.next_lab
        }
        parts = push(parts, ar.instructions)
        # Empty/`case Colon:` arms fall through the match — join at end_l (no ret).
        if !msil_ends_with_terminator(ar.instructions) {
            parts = push(parts, "        br " + end_l + "\n")
            end_used = true
        }
        parts = push(parts, miss_l + ":\n")
        saw_arm = true
    }
    # Trailing `default:` / `else:` after case arms.
    let mut saw_else: bool = false
    if rest.starts_with("default:") || rest.starts_with("else:") {
        let colon_at: i32 = rest.index_of(":")
        let def_body: utf8 = rest.slice(colon_at + 1, rest.length() - colon_at - 1)
        let def_stmts: [utf8] = split_top_level_statements(def_body)
        let dr: BodyLowerResult = emit_statements_ret("", def_stmts, locals, next_lab, submission, continue_label, fn_ret_ty, break_label)
        if !dr.ok {
            return dr
        }
        if dr.next_lab > next_lab {
            next_lab = dr.next_lab
        }
        parts = push(parts, dr.instructions)
        if !msil_ends_with_terminator(dr.instructions) {
            end_used = true
        }
        rest = ""
        saw_arm = true
        saw_else = true
    }
    if !saw_arm {
        return body_lower_fail("match 无有效臂")
    }
    if rest.trim().length() > 0 && !rest.trim().starts_with("#") && !rest.trim().starts_with("//") {
        return body_lower_fail("match 残留未解析：" + rest.trim())
    }
    # Only emit join when a live arm branches here. Never ldnull;ret on join —
    # that made empty arms (`case Colon:`) return null and NRE in callers.
    if end_used {
        parts = push(parts, end_l + ":\n")
    }
    # Exhaustiveness hole: final miss label with no else would fall off the method
    # (InvalidProgram). Emit an unreachable safety ret for non-void / void alike.
    if !saw_else && !end_used {
        if fn_ret_ty == "void" || fn_ret_ty.length() == 0 {
            parts = push(parts, "        ret\n")
        }
        else if fn_ret_ty == "bool" || fn_ret_ty == "int32" || fn_ret_ty == "int64" || fn_ret_ty == "uint8" {
            parts = push(parts, "        ldc.i4.0\n")
            parts = push(parts, "        ret\n")
        }
        else {
            parts = push(parts, "        ldnull\n")
            parts = push(parts, "        ret\n")
        }
    }
    return body_lower_ok_lab(join_msil_parts(parts), "", next_lab)
}

# Array/ArrayList.get(ordinal)[.unwrap()] → elem at ordinal-1 (1-based source layout).
micro try_emit_array_list_get(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let mut e: utf8 = expr.trim()
    if e.ends_with(".unwrap()") {
        e = e.slice(0, e.length() - 9).trim()
    }
    let get_at: i32 = index_of_at_paren_depth0(e, ".get(")
    if get_at <= 0 {
        return body_lower_fail("soft:alist-no-get")
    }
    let open: i32 = get_at + 4
    let close: i32 = matching_close_paren(e, open)
    if close <= open {
        return body_lower_fail("soft:alist-paren")
    }
    let after: utf8 = e.slice(close + 1, e.length() - close - 1).trim()
    if after.length() > 0 {
        return body_lower_fail("soft:alist-suffix")
    }
    let recv: utf8 = e.slice(0, get_at).trim()
    let arg: utf8 = e.slice(open + 1, close - open - 1).trim()
    let loaded: PathLoadResult = emit_load_path(msil, recv, locals, structs)
    if !loaded.ok {
        if loaded.error.length() == 0 || loaded.error.starts_with("soft:") {
            return body_lower_fail("soft:alist-recv")
        }
        return body_lower_fail(loaded.error)
    }
    let mut acc: utf8 = loaded.instructions
    let mut ld_elem: utf8 = "        ldelem.ref"
    let rt: utf8 = loaded.result_type
    if rt == "class ArrayList" || rt.ends_with(".ArrayList") || rt == "ArrayList" {
        acc = append_msil_line(acc, "        ldfld uint8[] ArrayList::_items")
        ld_elem = "        ldelem.u1"
    }
    else if rt.ends_with("[]") {
        if rt == "uint8[]" {
            ld_elem = "        ldelem.u1"
        }
        else if rt == "int32[]" {
            ld_elem = "        ldelem.i4"
        }
        else {
            ld_elem = "        ldelem.ref"
        }
    }
    else if rt == "class Array" || rt == "Array" || rt.ends_with(".Array") {
        ld_elem = "        ldelem.ref"
    }
    else {
        return body_lower_fail("soft:alist-type")
    }
    let ir: BodyLowerResult = emit_int_expr(acc, arg, locals, submission)
    if !ir.ok {
        return ir
    }
    acc = append_msil_line(ir.instructions, "        ldc.i4.1")
    acc = append_msil_line(acc, "        sub")
    acc = append_msil_line(acc, ld_elem)
    # `.unwrap()` is a no-op once Option is erased to the element on the stack.
    return body_lower_ok(acc, "")
}

micro emit_value_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let mut e: utf8 = expr.trim()
    let mut stripped_v: utf8 = strip_outer_parens(e)
    while stripped_v != e {
        e = stripped_v
        stripped_v = strip_outer_parens(e)
    }
    if e == "null" || e == "None" {
        return body_lower_ok(append_msil_line(msil, "        ldnull"), "")
    }
    # Triple-quote `'''"'''` / normal `"…"` string literals.
    if is_string_literal_expr(e) {
        return emit_string_literal_expr(msil, e)
    }
    # `["clr", "jvm", …]` string array literal OR `[expr, expr, …]` string[] exprs.
    if e.starts_with("[") && e.ends_with("]") {
        if e.contains(dq()) {
            return emit_string_array_new(msil, e)
        }
        return emit_string_array_from_exprs(msil, e, locals, submission)
    }
    if looks_like_call_expr(e) {
        return emit_call_expr(msil, e, locals, submission)
    }
    if e.starts_with("if ") {
        return emit_if_expr(msil, e, locals, submission, msil.length() + 1)
    }
    if looks_like_struct_literal(e) {
        return emit_struct_literal(msil, e, locals, submission)
    }
    let io: BodyLowerResult = emit_std_io_call(msil, e, locals, submission)
    if io.ok {
        return io
    }
    if io.error.length() > 0 && !io.error.starts_with("soft:") {
        return io
    }
    if index_of_at_paren_depth0(e, ".get(") >= 0 {
        let gr: BodyLowerResult = try_emit_array_list_get(msil, e, locals, submission)
        if gr.ok {
            return gr
        }
        if gr.error.length() > 0 && !gr.error.starts_with("soft:") {
            return gr
        }
    }
    # `s.split("/")` → String.Split(string[], StringSplitOptions) — Framework-safe
    # (mscorlib has no Split(string); Core Split(string) missing under Framework-ilasm PE).
    let split_at: i32 = e.index_of(".split(")
    if split_at > 0 && e.ends_with(")") {
        let open_s: i32 = split_at + 6
        let close_s: i32 = matching_close_paren(e, open_s)
        if close_s > open_s {
            let after_s: utf8 = e.slice(close_s + 1, e.length() - close_s - 1).trim()
            if after_s.length() == 0 {
                let recv_s: utf8 = e.slice(0, split_at).trim()
                let arg_s: utf8 = e.slice(open_s + 1, close_s - open_s - 1).trim()
                let lr: BodyLowerResult = emit_value_expr(msil, recv_s, locals, submission)
                if !lr.ok {
                    return lr
                }
                # stack: recv → newarr string[1] {sep} → Split(string[], None)
                let mut acc_sp: utf8 = append_msil_line(lr.instructions, "        ldc.i4.1")
                acc_sp = append_msil_line(acc_sp, "        newarr [mscorlib]System.String")
                acc_sp = append_msil_line(acc_sp, "        dup")
                acc_sp = append_msil_line(acc_sp, "        ldc.i4.0")
                let ar: BodyLowerResult = emit_value_expr(acc_sp, arg_s, locals, submission)
                if !ar.ok {
                    return ar
                }
                let mut done_sp: utf8 = append_msil_line(ar.instructions, "        stelem.ref")
                done_sp = append_msil_line(done_sp, "        ldc.i4.0")
                done_sp = append_msil_line(done_sp, "        callvirt instance string[] [mscorlib]System.String::Split(string[], valuetype [mscorlib]System.StringSplitOptions)")
                return body_lower_ok(done_sp, "")
            }
        }
    }
    if e.ends_with(".unwrap()") {
        let inner: utf8 = e.slice(0, e.length() - 9).trim()
        if looks_like_call_expr(inner) {
            return emit_call_expr(msil, inner, locals, submission)
        }
        return emit_value_expr(msil, inner, locals, submission)
    }
    # string concat / int add — try int first so `index + 1` is not Concat(string,string).
    let plus: i32 = last_index_of_at_paren_depth0(e, " + ")
    if plus > 0 {
        let as_int: BodyLowerResult = emit_int_expr(msil, e, locals, submission)
        if as_int.ok {
            return as_int
        }
        let left: utf8 = e.slice(0, plus).trim()
        let right: utf8 = e.slice(plus + 3, e.length() - plus - 3).trim()
        let lr: BodyLowerResult = emit_value_expr(msil, left, locals, submission)
        if !lr.ok {
            return lr
        }
        let rr: BodyLowerResult = emit_value_expr(lr.instructions, right, locals, submission)
        if !rr.ok {
            return rr
        }
        return body_lower_ok(append_msil_line(rr.instructions, "        call string [mscorlib]System.String::Concat(string, string)"), "")
    }
    # Index before string methods / `.length()` — `arr⁅arr.length()-1⁆` must not hit length path.
    let idx0: BodyLowerResult = emit_index_expr(msil, e, locals, submission)
    if idx0.ok {
        return idx0
    }
    # Soft rejects — fall through to field/concat paths.
    if idx0.error.length() > 0 && !idx0.error.starts_with("soft:") {
        return idx0
    }
    # Depth-0 `.length()` wins (`x.trim().length()`); nested length stays with string methods.
    if index_of_at_paren_depth0(e, ".length()") >= 0 {
        return emit_int_expr(msil, e, locals, submission)
    }
    if index_of_at_paren_depth0(e, " || ") < 0 && index_of_at_paren_depth0(e, " && ") < 0 && (e.contains(".slice(") || e.contains(".starts_with(") || e.contains(".ends_with(") || e.contains(".contains(") || e.contains(".trim(") || e.contains(".replace(") || e.contains(".to_lower(") || e.contains(".index_of(") || e.contains(".last_index_of(") || e.contains(".equals(") || e.ends_with(".to_lower()") || e.ends_with(".trim()")) {
        let sm: BodyLowerResult = emit_string_receiver_call(msil, e, locals, structs, submission)
        if sm.ok {
            return sm
        }
        if sm.error.length() > 0 && !sm.error.starts_with("字符串方法后还有后缀") {
            return sm
        }
        if sm.error.length() == 0 {
            return body_lower_fail("字符串方法 lowering 失败：" + e)
        }
    }
    # `find_unite_def(...).name` / `params⁅i⁆.clr_type` — call/index then field.
    let trail_dot: i32 = last_index_of_at_paren_depth0(e, ".")
    if trail_dot > 0 {
        let left_c: utf8 = e.slice(0, trail_dot).trim()
        let field_c: utf8 = e.slice(trail_dot + 1, e.length() - trail_dot - 1).trim()
        if field_c.length() > 0 && field_c.index_of("(") < 0 && field_c.index_of(" ") < 0 {
            if looks_like_call_expr(left_c) {
                let cr: BodyLowerResult = emit_call_expr(msil, left_c, locals, submission)
                if !cr.ok {
                    return cr
                }
                let open_c: i32 = left_c.index_of("(")
                let cname: utf8 = left_c.slice(0, open_c).trim()
                let ret_clr: utf8 = lookup_callee_return_clr(submission, cname)
                let mut type_name: utf8 = ret_clr.trim()
                if type_name.starts_with("class ") {
                    type_name = type_name.slice(5, type_name.length() - 5).trim()
                }
                let st: ParsedStruct = find_struct_def(structs, type_name)
                if st.name.length() == 0 {
                    return body_lower_fail("调用结果无字段：" + cname + " ." + field_c)
                }
                let field: ParsedStructField = find_struct_field(st, field_c)
                if field.name.length() == 0 {
                    return body_lower_fail("未知字段：" + type_name + "." + field_c)
                }
                let ft: utf8 = msil_field_type(field.type_text, structs)
                return body_lower_ok(append_msil_line(cr.instructions, "        ldfld " + ft + " " + type_name + "::" + msil_id(field_c)), "")
            }
            # `arr⁅i⁆.field` / `arr[i].field`
            if left_c.contains("⁅") || (left_c.contains("[") && !left_c.starts_with("[")) {
                let idx_r: BodyLowerResult = emit_index_expr(msil, left_c, locals, submission)
                if idx_r.ok {
                    let mut base_name: utf8 = left_c
                    let mut cut: i32 = index_of_at_paren_depth0(left_c, "⁅")
                    if cut < 0 {
                        cut = index_of_at_paren_depth0(left_c, "[")
                    }
                    if cut > 0 {
                        base_name = left_c.slice(0, cut).trim()
                    }
                    let bl: BodyLocal = find_local(locals, base_name)
                    let mut elem_ty: utf8 = bl.clr_type
                    if elem_ty.ends_with("[]") {
                        elem_ty = elem_ty.slice(0, elem_ty.length() - 2).trim()
                    }
                    if elem_ty.starts_with("class ") {
                        elem_ty = elem_ty.slice(6, elem_ty.length() - 6).trim()
                    }
                    let st2: ParsedStruct = find_struct_def(structs, elem_ty)
                    if st2.name.length() > 0 {
                        let field2: ParsedStructField = find_struct_field(st2, field_c)
                        if field2.name.length() > 0 {
                            let ft2: utf8 = msil_field_type(field2.type_text, structs)
                            return body_lower_ok(append_msil_line(idx_r.instructions, "        ldfld " + ft2 + " " + st2.name + "::" + msil_id(field_c)), "")
                        }
                    }
                    # Bootstrap field types when struct scrape missed.
                    if elem_ty.length() > 0 {
                        let mut ft_guess: utf8 = "string"
                        if field_c == "slot" || field_c == "tag" || field_c == "length" || field_c == "count" {
                            ft_guess = "int32"
                        }
                        else if field_c == "is_arg" || field_c == "ok" {
                            ft_guess = "bool"
                        }
                        else if field_c == "functions" || field_c == "fields" || field_c == "variants" || field_c == "members" || field_c == "dependencies" || field_c == "packages" || field_c == "external_call_edges" || field_c == "build_targets" || field_c == "body_sources" || field_c == "body_symbols" {
                            ft_guess = "object[]"
                        }
                        return body_lower_ok(append_msil_line(idx_r.instructions, "        ldfld " + ft_guess + " " + elem_ty + "::" + msil_id(field_c)), "")
                    }
                }
            }
        }
    }
    if e.index_of(".") >= 0 || find_local(locals, e).slot >= 0 {
        let loaded: PathLoadResult = emit_load_path(msil, e, locals, structs)
        if loaded.ok {
            return body_lower_ok(loaded.instructions, "")
        }
        if e.index_of(".") >= 0 && loaded.error.length() > 0 && !loaded.error.starts_with("soft:") {
            return body_lower_fail(loaded.error)
        }
    }
    # Bare local/arg of any CLR type (string utf8 params, etc.) — never fall into int-only path.
    let bare: BodyLocal = find_local(locals, e)
    if bare.slot >= 0 && e.index_of("(") < 0 {
        return body_lower_ok(append_ld_slot(msil, bare), "")
    }
    return emit_int_expr(msil, e, locals, submission)
}

micro emit_index_expr(msil: utf8, expr: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> BodyLowerResult {
    let structs: [ParsedStruct] = submission.struct_defs
    let e: utf8 = expr.trim()
    # Calls win — `compare_utf8_text(values⁅j⁆, x)` is not an index expr.
    if looks_like_call_expr(e) {
        return body_lower_fail("soft:index-call")
    }
    let card_open: i32 = index_of_at_paren_depth0(e, "⁅")
    if card_open > 0 {
        let mut card_close: i32 = -1
        let mut ci: i32 = card_open + 1
        while ci < e.length() {
            if e.slice(ci, 1) == "⁆" {
                card_close = ci
                break
            }
            ci = ci + 1
        }
        if card_close > card_open {
            let base: utf8 = e.slice(0, card_open).trim()
            if base.index_of("(") >= 0 || base.contains(" + ") || base.contains(" - ") {
                return body_lower_fail("soft:index-base-op")
            }
            let after_idx: utf8 = e.slice(card_close + 1, e.length() - card_close - 1).trim()
            if after_idx.length() > 0 {
                # `params⁅i⁆.clr_type` — not a pure index expr; let caller handle.
                return body_lower_fail("soft:index-suffix")
            }
            let index_text: utf8 = e.slice(card_open + 1, card_close - card_open - 1).trim()
            let loaded: PathLoadResult = emit_load_path(msil, base, locals, structs)
            if !loaded.ok {
                if loaded.error.length() == 0 || loaded.error.starts_with("soft:") {
                    return body_lower_fail("soft:index-base")
                }
                return body_lower_fail(loaded.error)
            }
            let ir: BodyLowerResult = emit_int_expr(loaded.instructions, index_text, locals, submission)
            if !ir.ok {
                return ir
            }
            let rt0: utf8 = loaded.result_type.trim()
            if rt0 == "string" || rt0 == "utf8" || rt0 == "class string" {
                # utf8/string ⁅i⁆ → one-char Substring (not ldelem on a string).
                let mut acc_ss: utf8 = append_msil_line(ir.instructions, "        ldc.i4.1")
                acc_ss = append_msil_line(acc_ss, "        callvirt instance string [mscorlib]System.String::Substring(int32, int32)")
                return body_lower_ok(acc_ss, "")
            }
            let mut ld_elem: utf8 = "        ldelem.ref"
            if rt0 == "int32[]" {
                ld_elem = "        ldelem.i4"
            }
            else if rt0 == "uint8[]" || rt0 == "bool[]" {
                ld_elem = "        ldelem.u1"
            }
            else if rt0 == "int64[]" {
                ld_elem = "        ldelem.i8"
            }
            return body_lower_ok(append_msil_line(ir.instructions, ld_elem), "")
        }
    }
    let bopen: i32 = index_of_at_paren_depth0(e, "[")
    if bopen > 0 && !e.starts_with("[") {
        let mut bclose: i32 = -1
        let mut bi: i32 = bopen + 1
        let mut bd: i32 = 1
        while bi < e.length() {
            let bc: utf8 = e.slice(bi, 1)
            if bc == "[" {
                bd = bd + 1
            }
            if bc == "]" {
                bd = bd - 1
                if bd == 0 {
                    bclose = bi
                    break
                }
            }
            bi = bi + 1
        }
        if bclose > bopen {
            let base: utf8 = e.slice(0, bopen).trim()
            if base.index_of("(") >= 0 || base.contains(" + ") || base.contains(" - ") {
                return body_lower_fail("soft:index-base-op")
            }
            let after_b: utf8 = e.slice(bclose + 1, e.length() - bclose - 1).trim()
            if after_b.length() > 0 {
                return body_lower_fail("soft:index-suffix")
            }
            let index_text: utf8 = e.slice(bopen + 1, bclose - bopen - 1).trim()
            let loaded: PathLoadResult = emit_load_path(msil, base, locals, structs)
            if !loaded.ok {
                if loaded.error.length() == 0 || loaded.error.starts_with("soft:") {
                    return body_lower_fail("soft:index-base")
                }
                return body_lower_fail(loaded.error)
            }
            let ir: BodyLowerResult = emit_int_expr(loaded.instructions, index_text, locals, submission)
            if !ir.ok {
                return ir
            }
            let rt1: utf8 = loaded.result_type.trim()
            if rt1 == "string" || rt1 == "utf8" || rt1 == "class string" {
                let mut acc_ss2: utf8 = append_msil_line(ir.instructions, "        ldc.i4.1")
                acc_ss2 = append_msil_line(acc_ss2, "        callvirt instance string [mscorlib]System.String::Substring(int32, int32)")
                return body_lower_ok(acc_ss2, "")
            }
            let mut ld_elem2: utf8 = "        ldelem.ref"
            if rt1 == "int32[]" {
                ld_elem2 = "        ldelem.i4"
            }
            else if rt1 == "uint8[]" || rt1 == "bool[]" {
                ld_elem2 = "        ldelem.u1"
            }
            else if rt1 == "int64[]" {
                ld_elem2 = "        ldelem.i8"
            }
            return body_lower_ok(append_msil_line(ir.instructions, ld_elem2), "")
        }
    }
    return body_lower_fail("soft:index-none")
}

micro split_top_level_statements(inner: utf8) -> [utf8] {
    let mut stmts: [utf8] = []
    let mut buf: utf8 = ""
    let mut depth: i32 = 0
    let mut paren: i32 = 0
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    while i < inner.length() {
        let ch: utf8 = inner.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                buf = buf + ch
                i = i + 1
                continue
            }
            let next: i32 = string_lit_advance(inner, i)
            buf = buf + inner.slice(i, next - i)
            i = next
            continue
        }
        if ch == "#" || (ch == "/" && i + 1 < inner.length() && inner.slice(i + 1, 1) == "/") {
            while i < inner.length() && inner.slice(i, 1) != "\n" {
                i = i + 1
            }
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            buf = buf + ch
            i = i + 1
            continue
        }
        if ch == "(" || ch == "[" || ch == "⁅" {
            paren = paren + 1
            buf = buf + ch
        }
        else if ch == ")" || ch == "]" || ch == "⁆" {
            paren = paren - 1
            buf = buf + ch
        }
        else if ch == "{" {
            depth = depth + 1
            buf = buf + ch
        }
        else if ch == "}" {
            depth = depth - 1
            buf = buf + ch
            if depth == 0 {
                # Keep `if {..} else {..}` as one statement (even if paren count is sticky).
                let mut j: i32 = i + 1
                while j < inner.length() {
                    let w: utf8 = inner.slice(j, 1)
                    if w == " " || w == "\t" || w == "\r" || w == "\n" {
                        j = j + 1
                        continue
                    }
                    break
                }
                if is_else_keyword_at(inner, j) {
                    i = i + 1
                    continue
                }
                if paren > 0 {
                    i = i + 1
                    continue
                }
                # `push(..., LockEntry { ... })` — `}` is not end of statement when `)` follows.
                if j < inner.length() {
                    let peek: utf8 = inner.slice(j, 1)
                    if peek == ")" || peek == "," || peek == "." || peek == "]" || peek == "⁆" || peek == "+" {
                        i = i + 1
                        continue
                    }
                }
                let piece: utf8 = buf.trim()
                if piece.length() > 0 {
                    stmts = push(stmts, piece)
                }
                buf = ""
            }
        }
        else if ch == "\n" && depth == 0 && paren <= 0 {
            # Line continuation: `+` / `.` / `else` after `}`.
            let mut j: i32 = i + 1
            while j < inner.length() {
                let w: utf8 = inner.slice(j, 1)
                if w == " " || w == "\t" || w == "\r" {
                    j = j + 1
                    continue
                }
                break
            }
            if j < inner.length() {
                let peek: utf8 = inner.slice(j, 1)
                if peek == "+" || peek == "." {
                    buf = buf + " "
                    i = i + 1
                    continue
                }
                # Continue `return (a)\n || (b)\n && c` across newlines.
                if j + 2 <= inner.length() && (inner.slice(j, 2) == "||" || inner.slice(j, 2) == "&&") {
                    buf = buf + " "
                    i = i + 1
                    continue
                }
                if is_else_keyword_at(inner, j) {
                    buf = buf + " "
                    i = i + 1
                    continue
                }
            }
            let piece: utf8 = buf.trim()
            if piece.length() > 0 {
                stmts = push(stmts, piece)
            }
            buf = ""
        }
        else {
            buf = buf + ch
        }
        i = i + 1
    }
    let tail: utf8 = buf.trim()
    if tail.length() > 0 {
        stmts = push(stmts, tail)
    }
    return stmts
}

micro join_msil_parts(parts: [utf8]) -> utf8 {
    # Dedicated concat loop — keep only a few locals to avoid CLR SSA home reuse.
    let mut acc: utf8 = ""
    let mut pi: usize = 0
    let pn: usize = parts.length()
    while pi < pn {
        acc = acc + parts⁅pi⁆
        pi = pi + 1
    }
    return acc
}

micro emit_statements(msil: utf8, stmts: [utf8], locals: [BodyLocal], label_seed: i32, submission: FragmentSubmission, continue_label: utf8) -> BodyLowerResult {
    return emit_statements_ret(msil, stmts, locals, label_seed, submission, continue_label, "", "")
}

micro emit_statements_ret(msil: utf8, stmts: [utf8], locals: [BodyLocal], label_seed: i32, submission: FragmentSubmission, continue_label: utf8, fn_ret_ty: utf8, break_label: utf8) -> BodyLowerResult {
    # Accumulate chunks in [utf8] then join — utf8 `acc = acc + …` in fat loops is clobbered on CLR.
    let structs: [ParsedStruct] = submission.struct_defs
    let mut parts: [utf8] = []
    if msil.length() > 0 {
        parts = push(parts, msil)
    }
    let mut lab: i32 = label_seed
    let mut si: usize = 0
    while si < stmts.length() {
        let stmt: utf8 = stmts⁅si⁆.trim()
        if stmt.length() == 0 {
            si = si + 1
            continue
        }
        if stmt.starts_with("#") || stmt.starts_with("//") {
            si = si + 1
            continue
        }
        if stmt.starts_with("match ") {
            let mr: BodyLowerResult = emit_match_stmt(stmt, locals, lab, submission, continue_label, fn_ret_ty, break_label)
            if !mr.ok {
                return mr
            }
            if mr.next_lab > lab {
                lab = mr.next_lab
            }
            parts = push(parts, mr.instructions)
            si = si + 1
            continue
        }
        if stmt == "continue" || stmt == "continue;" {
            if continue_label.length() == 0 {
                return body_lower_fail("continue 不在循环内")
            }
            parts = push(parts, "        br " + continue_label + "\n")
            si = si + 1
            continue
        }
        if stmt == "break" || stmt == "break;" {
            if break_label.length() == 0 {
                return body_lower_fail("break 不在循环内")
            }
            parts = push(parts, "        br " + break_label + "\n")
            si = si + 1
            continue
        }
        # let mut name: ty = expr   OR   let name: ty = expr
        if stmt.starts_with("let ") {
            let rest: utf8 = stmt.slice(4, stmt.length() - 4).trim()
            let mut name_part: utf8 = rest
            if name_part.starts_with("mut ") {
                name_part = name_part.slice(4, name_part.length() - 4).trim()
            }
            let colon: i32 = name_part.index_of(":")
            let eq: i32 = name_part.index_of("=")
            if eq < 0 {
                return body_lower_fail("无法解析 let：" + stmt)
            }
            let mut name: utf8 = ""
            let mut ty: utf8 = ""
            let mut rhs: utf8 = ""
            if colon > 0 && colon < eq {
                name = name_part.slice(0, colon).trim()
                ty = name_part.slice(colon + 1, eq - colon - 1).trim()
                rhs = name_part.slice(eq + 1, name_part.length() - eq - 1).trim()
            }
            else {
                # Untyped let
                name = name_part.slice(0, eq).trim()
                rhs = name_part.slice(eq + 1, name_part.length() - eq - 1).trim()
            }
            if rhs.ends_with(";") {
                rhs = rhs.slice(0, rhs.length() - 1).trim()
            }
            let slot: i32 = find_local_slot(locals, name)
            if slot < 0 {
                return body_lower_fail("let 局部未登记：" + name)
            }
            let mut clr: utf8 = clr_type_for_annotation_with_structs(ty, structs)
            if clr.length() == 0 {
                clr = find_local(locals, name).clr_type
            }
            if rhs.starts_with("if ") {
                let ir: BodyLowerResult = emit_if_expr("", rhs, locals, submission, lab)
                if !ir.ok {
                    return ir
                }
                if ir.next_lab > lab {
                    lab = ir.next_lab
                }
                parts = push(parts, append_stloc_slot(ir.instructions, slot))
                si = si + 1
                continue
            }
                    if looks_like_struct_literal(rhs) {
                let sr: BodyLowerResult = emit_struct_literal("", rhs, locals, submission)
                if !sr.ok {
                    return sr
                }
                parts = push(parts, append_stloc_slot(sr.instructions, slot))
                si = si + 1
                continue
            }
            # std.io.* as value (e.g. get_current_directory)
            let io_let: BodyLowerResult = emit_std_io_call("", rhs, locals, submission)
            if io_let.ok {
                parts = push(parts, append_stloc_slot(io_let.instructions, slot))
                si = si + 1
                continue
            }
            # `let visited = push(state.visited_..., x)` — dest may differ from src.
            if rhs.starts_with("push(") {
                let open_lp: i32 = rhs.index_of("(")
                let close_lp: i32 = matching_close_paren(rhs, open_lp)
                if close_lp > open_lp {
                    let arglist_lp: utf8 = rhs.slice(open_lp + 1, close_lp - open_lp - 1).trim()
                    let args_lp: [utf8] = split_call_args(arglist_lp)
                    if args_lp.length() == 2 {
                        let pr_lp: BodyLowerResult = emit_string_array_push(name, args_lp⁅0⁆.trim(), args_lp⁅1⁆.trim(), locals, lab, submission)
                        if !pr_lp.ok {
                            return pr_lp
                        }
                        if pr_lp.next_lab > lab {
                            lab = pr_lp.next_lab
                        }
                        parts = push(parts, pr_lp.instructions)
                        si = si + 1
                        continue
                    }
                }
            }
            if looks_like_call_expr(rhs) {
                let cr: BodyLowerResult = emit_call_expr_hint("", rhs, locals, submission, ty)
                if !cr.ok {
                    return cr
                }
                parts = push(parts, append_stloc_slot(cr.instructions, slot))
                si = si + 1
                continue
            }
            if clr.ends_with("[]") && rhs == "[]" {
                let elem: utf8 = clr.slice(0, clr.length() - 2).trim()
                let mut chunk: utf8 = "        ldc.i4.0\n"
                if elem == "string" {
                    chunk = chunk + "        newarr [mscorlib]System.String\n"
                }
                else if elem.starts_with("class ") {
                    let en: utf8 = elem.slice(6, elem.length() - 6).trim()
                    chunk = chunk + "        newarr " + en + "\n"
                }
                else if elem == "uint8" {
                    chunk = chunk + "        newarr [mscorlib]System.Byte\n"
                }
                else {
                    chunk = chunk + "        newarr [mscorlib]System.Object\n"
                }
                parts = push(parts, append_stloc_slot(chunk, slot))
            }
            else if clr == "string[]" {
                if rhs.starts_with("[") && rhs.ends_with("]") {
                    let arr: BodyLowerResult = emit_string_array_new("", rhs)
                    if !arr.ok {
                        return arr
                    }
                    parts = push(parts, append_stloc_slot(arr.instructions, slot))
                }
                else {
                    let vr: BodyLowerResult = emit_value_expr("", rhs, locals, submission)
                    if !vr.ok {
                        return vr
                    }
                    parts = push(parts, append_stloc_slot(vr.instructions, slot))
                }
            }
            else if clr == "int32" || clr == "bool" || ty == "bool" {
                # Bool lets (`||` / `==` / `.starts_with`) — not raw int.
                if rhs.contains(" || ") || rhs.contains(" && ") || rhs.contains(" == ") || rhs.contains(" != ") || rhs.contains(".starts_with(") || rhs.contains(".ends_with(") || rhs.contains(".contains(") || rhs.starts_with("!") {
                    let br: BodyLowerResult = emit_bool_condition("", rhs, locals, submission)
                    if !br.ok {
                        return br
                    }
                    parts = push(parts, append_stloc_slot(br.instructions, slot))
                }
                else {
                    let er: BodyLowerResult = emit_int_expr("", rhs, locals, submission)
                    if !er.ok {
                        return er
                    }
                    parts = push(parts, append_stloc_slot(er.instructions, slot))
                }
            }
            else if clr == "string" {
                let vr: BodyLowerResult = emit_value_expr("", rhs, locals, submission)
                if !vr.ok {
                    return vr
                }
                parts = push(parts, append_stloc_slot(vr.instructions, slot))
            }
            else if clr.starts_with("class ") {
                let vr: BodyLowerResult = emit_value_expr("", rhs, locals, submission)
                if !vr.ok {
                    return vr
                }
                parts = push(parts, append_stloc_slot(vr.instructions, slot))
            }
            else {
                return body_lower_fail("不支持的 let 类型：" + ty)
            }
            si = si + 1
            continue
        }
        # loop item in items { body } → indexed while (bootstrap).
        if stmt.starts_with("loop ") {
            let after_loop: utf8 = stmt.slice(5, stmt.length() - 5).trim()
            let in_at: i32 = after_loop.index_of(" in ")
            let brace_l: i32 = index_of_brace_outside_string(after_loop)
            if in_at <= 0 || brace_l <= in_at {
                return body_lower_fail("loop 语法无效：" + stmt)
            }
            let bind: utf8 = after_loop.slice(0, in_at).trim()
            let iter: utf8 = after_loop.slice(in_at + 4, brace_l - in_at - 4).trim()
            let body_inner: utf8 = after_loop.slice(brace_l, after_loop.length() - brace_l)
            let loop_body: utf8 = extract_function_inner_body("x" + body_inner)
            let idx_l: BodyLocal = find_local(locals, "__clr_loop_i")
            if idx_l.slot < 0 {
                return body_lower_fail("loop 缺少临时局部 __clr_loop_i")
            }
            let bind_l: BodyLocal = find_local(locals, bind)
            if bind_l.slot < 0 {
                return body_lower_fail("loop 绑定未登记为局部：" + bind)
            }
            let head: utf8 = "L" + format("{}", lab)
            let done: utf8 = "M" + format("{}", lab)
            lab = lab + 1
            parts = push(parts, append_stloc_slot(append_ldc_i4_digits("", "0"), idx_l.slot))
            parts = push(parts, head + ":\n")
            # while idx < iter.length()
            let mut cond_msil: utf8 = append_ldloc_slot("", idx_l.slot)
            let len_r2: BodyLowerResult = emit_int_expr(cond_msil, iter + ".length()", locals, submission)
            if !len_r2.ok {
                return len_r2
            }
            parts = push(parts, append_msil_line(len_r2.instructions, "        bge " + done))
            # bind = iter[idx]
            let load_r: BodyLowerResult = emit_index_expr("", iter + "⁅__clr_loop_i⁆", locals, submission)
            if !load_r.ok {
                return load_r
            }
            parts = push(parts, append_stloc_slot(load_r.instructions, bind_l.slot))
            let nested: [utf8] = split_top_level_statements(loop_body)
            let nr: BodyLowerResult = emit_statements_ret("", nested, locals, lab, submission, head, fn_ret_ty, done)
            if !nr.ok {
                return nr
            }
            if nr.next_lab > lab {
                lab = nr.next_lab
            }
            parts = push(parts, nr.instructions)
            # idx = idx + 1
            parts = push(parts, append_ldloc_slot("", idx_l.slot))
            parts = push(parts, "        ldc.i4.1\n")
            parts = push(parts, "        add\n")
            parts = push(parts, append_stloc_slot("", idx_l.slot))
            parts = push(parts, "        br " + head + "\n")
            parts = push(parts, done + ":\n")
            si = si + 1
            continue
        }
        # while cond { body }
        if stmt.starts_with("while ") {
            let after: utf8 = stmt.slice(6, stmt.length() - 6).trim()
            let brace: i32 = index_of_brace_outside_string(after)
            if brace < 0 {
                return body_lower_fail("while 缺少体：" + stmt)
            }
            let cond: utf8 = after.slice(0, brace).trim()
            let body_inner: utf8 = after.slice(brace, after.length() - brace)
            # body_inner is `{ ... }`
            let loop_body: utf8 = extract_function_inner_body("x" + body_inner)
            let head: utf8 = "W" + format("{}", lab)
            let done: utf8 = "D" + format("{}", lab)
            lab = lab + 1
            parts = push(parts, head + ":\n")
            # Bare `i < n` fast-path only — never split when `&&` / `||` / calls remain.
            let lt: i32 = cond.index_of(" < ")
            if lt > 0 && !cond.contains(" && ") && !cond.contains(" || ") && !cond.contains(".ends_with(") && !cond.contains(".starts_with(") && !cond.contains(".contains(") && cond.index_of("(") < 0 {
                let left: utf8 = cond.slice(0, lt).trim()
                let right: utf8 = cond.slice(lt + 3, cond.length() - lt - 3).trim()
                let lr: BodyLowerResult = emit_int_expr("", left, locals, submission)
                if !lr.ok {
                    return lr
                }
                let rr: BodyLowerResult = emit_int_expr(lr.instructions, right, locals, submission)
                if !rr.ok {
                    return rr
                }
                parts = push(parts, append_msil_line(rr.instructions, "        bge " + done))
            }
            else {
                let cr: BodyLowerResult = emit_bool_condition("", cond, locals, submission)
                if !cr.ok {
                    return cr
                }
                parts = push(parts, append_msil_line(cr.instructions, "        brfalse " + done))
            }
            let nested: [utf8] = split_top_level_statements(loop_body)
            let nr: BodyLowerResult = emit_statements_ret("", nested, locals, lab, submission, head, fn_ret_ty, done)
            if !nr.ok {
                return nr
            }
            if nr.next_lab > lab {
                lab = nr.next_lab
            }
            parts = push(parts, nr.instructions)
            parts = push(parts, "        br " + head + "\n")
            parts = push(parts, done + ":\n")
            si = si + 1
            continue
        }
        # name = expr  (incl. result = push(result, x) / obj.field = expr / arr⁅i⁆ = expr)
        let eq: i32 = stmt.index_of("=")
        if eq > 0 && !stmt.starts_with("if ") && !stmt.starts_with("return ") && !stmt.starts_with("let ") {
            let left: utf8 = stmt.slice(0, eq).trim()
            let mut right: utf8 = stmt.slice(eq + 1, stmt.length() - eq - 1).trim()
            if right.ends_with(";") {
                right = right.slice(0, right.length() - 1).trim()
            }
            # Drop trailing comments / CR so `push(...)\r` still matches.
            while right.length() > 0 {
                let last: utf8 = right.slice(right.length() - 1, 1)
                if last == "\r" || last == "\n" || last == " " || last == "\t" {
                    right = right.slice(0, right.length() - 1)
                    continue
                }
                break
            }
            # arr⁅i⁆ = value / arr[i] = value
            let card_o: i32 = left.index_of("⁅")
            let card_c: i32 = left.index_of("⁆")
            if card_o > 0 && card_c > card_o && card_c + 1 == left.length() {
                let base: utf8 = left.slice(0, card_o).trim()
                let idx_e: utf8 = left.slice(card_o + 1, card_c - card_o - 1).trim()
                let base_l: BodyLocal = find_local(locals, base)
                if base_l.slot >= 0 && base_l.clr_type.ends_with("[]") {
                    let mut acc_as: utf8 = append_ld_slot("", base_l)
                    let ir: BodyLowerResult = emit_int_expr(acc_as, idx_e, locals, submission)
                    if !ir.ok {
                        return ir
                    }
                    let vr: BodyLowerResult = emit_stack_expr(ir.instructions, right, locals, submission)
                    if !vr.ok {
                        return vr
                    }
                    let mut st_op: utf8 = "        stelem.ref"
                    if base_l.clr_type == "int32[]" {
                        st_op = "        stelem.i4"
                    }
                    else if base_l.clr_type == "uint8[]" {
                        st_op = "        stelem.i1"
                    }
                    parts = push(parts, append_msil_line(vr.instructions, st_op))
                    si = si + 1
                    continue
                }
            }
            # `submission.external_import_bindings = push(submission.external_import_bindings, x)`
            if left.contains(".") && left.index_of(" ") < 0 && left.index_of("(") < 0 && right.starts_with("push(") {
                let open_pf: i32 = right.index_of("(")
                let close_pf: i32 = matching_close_paren(right, open_pf)
                let after_pf: utf8 = ""
                if close_pf > open_pf && close_pf + 1 < right.length() {
                    after_pf = right.slice(close_pf + 1, right.length() - close_pf - 1).trim()
                }
                if close_pf > open_pf && after_pf.length() == 0 {
                    let arglist_f: utf8 = right.slice(open_pf + 1, close_pf - open_pf - 1).trim()
                    let args_f: [utf8] = split_call_args(arglist_f)
                    if args_f.length() == 2 {
                        let arr_f: utf8 = args_f⁅0⁆.trim()
                        let val_f: utf8 = args_f⁅1⁆.trim()
                        let pr_f: BodyLowerResult = emit_string_array_push(left, arr_f, val_f, locals, lab, submission)
                        if !pr_f.ok {
                            return pr_f
                        }
                        if pr_f.next_lab > lab {
                            lab = pr_f.next_lab
                        }
                        parts = push(parts, pr_f.instructions)
                        si = si + 1
                        continue
                    }
                }
            }
            if left.contains(".") && left.index_of(" ") < 0 && left.index_of("(") < 0 {
                let fr: BodyLowerResult = emit_field_store(left, right, locals, submission)
                if !fr.ok {
                    return fr
                }
                parts = push(parts, fr.instructions)
                si = si + 1
                continue
            }
            if left.index_of(" ") < 0 && left.index_of("(") < 0 {
                let slot: i32 = find_local_slot(locals, left)
                if slot < 0 {
                    return body_lower_fail("赋值未知局部：" + left)
                }
                if right.starts_with("push(") {
                    let open_p: i32 = right.index_of("(")
                    let close_p: i32 = matching_close_paren(right, open_p)
                    let after_push: utf8 = ""
                    if close_p > open_p && close_p + 1 < right.length() {
                        after_push = right.slice(close_p + 1, right.length() - close_p - 1).trim()
                    }
                    if close_p > open_p && after_push.length() == 0 {
                        let arglist: utf8 = right.slice(open_p + 1, close_p - open_p - 1).trim()
                        let args: [utf8] = split_call_args(arglist)
                        if args.length() != 2 {
                            return body_lower_fail("push 需要两参数：" + stmt)
                        }
                        let arr_e: utf8 = args⁅0⁆.trim()
                        let val_e: utf8 = args⁅1⁆.trim()
                        let pr: BodyLowerResult = emit_string_array_push(left, arr_e, val_e, locals, lab, submission)
                        if !pr.ok {
                            return pr
                        }
                        if pr.next_lab > lab {
                            lab = pr.next_lab
                        }
                        parts = push(parts, pr.instructions)
                        si = si + 1
                        continue
                    }
                }
                if looks_like_call_expr(right) {
                    let cr: BodyLowerResult = emit_call_expr("", right, locals, submission)
                    if !cr.ok {
                        return cr
                    }
                    parts = push(parts, append_stloc_slot(cr.instructions, slot))
                    si = si + 1
                    continue
                }
                let dest_l: BodyLocal = find_local(locals, left)
                if dest_l.clr_type == "string" || dest_l.clr_type == "string[]" || dest_l.clr_type.starts_with("class ") {
                    let vr: BodyLowerResult = emit_value_expr("", right, locals, submission)
                    if !vr.ok {
                        return vr
                    }
                    parts = push(parts, append_stloc_slot(vr.instructions, slot))
                    si = si + 1
                    continue
                }
                let er: BodyLowerResult = emit_int_expr("", right, locals, submission)
                if !er.ok {
                    return er
                }
                parts = push(parts, append_stloc_slot(er.instructions, slot))
                si = si + 1
                continue
            }
        }
        # return N / return expr
        if stmt.starts_with("return ") || stmt == "return" || stmt.starts_with("return;") {
            let mut ret_expr: utf8 = ""
            if stmt.starts_with("return ") {
                ret_expr = stmt.slice(7, stmt.length() - 7).trim()
            }
            if ret_expr.ends_with(";") {
                ret_expr = ret_expr.slice(0, ret_expr.length() - 1).trim()
            }
            if ret_expr.length() == 0 {
                parts = push(parts, "        ret\n")
                si = si + 1
                continue
            }
            # `return push(arr, x)` — build new array on stack, then ret.
            if ret_expr.starts_with("push(") {
                let open_rp: i32 = ret_expr.index_of("(")
                let close_rp: i32 = matching_close_paren(ret_expr, open_rp)
                if close_rp > open_rp {
                    let arglist_rp: utf8 = ret_expr.slice(open_rp + 1, close_rp - open_rp - 1).trim()
                    let args_rp: [utf8] = split_call_args(arglist_rp)
                    if args_rp.length() == 2 {
                        let pr_rp: BodyLowerResult = emit_string_array_push("", args_rp⁅0⁆.trim(), args_rp⁅1⁆.trim(), locals, lab, submission)
                        if !pr_rp.ok {
                            return pr_rp
                        }
                        if pr_rp.next_lab > lab {
                            lab = pr_rp.next_lab
                        }
                        parts = push(parts, append_msil_line(pr_rp.instructions, "        ret"))
                        si = si + 1
                        continue
                    }
                }
            }
            let str_lit: utf8 = body_contains_return_literal("return " + ret_expr)
            if str_lit.length() > 0 {
                parts = push(parts, append_msil_line(append_msil_line("", msil_quote_string(str_lit)), "        ret"))
                si = si + 1
                continue
            }
            if looks_like_struct_literal(ret_expr) {
                let sr: BodyLowerResult = emit_struct_literal("", ret_expr, locals, submission)
                if !sr.ok {
                    return sr
                }
                parts = push(parts, append_msil_line(sr.instructions, "        ret"))
                si = si + 1
                continue
            }
            # `return []` — empty array typed from function return annotation.
            if ret_expr == "[]" {
                let ret_clr: utf8 = clr_type_for_annotation_with_structs(fn_ret_ty, structs)
                if ret_clr.ends_with("[]") {
                    let elem: utf8 = ret_clr.slice(0, ret_clr.length() - 2).trim()
                    let mut chunk: utf8 = "        ldc.i4.0\n"
                    if elem == "string" {
                        chunk = chunk + "        newarr [mscorlib]System.String\n"
                    }
                    else if elem.starts_with("class ") {
                        let en: utf8 = elem.slice(6, elem.length() - 6).trim()
                        chunk = chunk + "        newarr " + en + "\n"
                    }
                    else if elem == "uint8" {
                        chunk = chunk + "        newarr [mscorlib]System.Byte\n"
                    }
                    else {
                        chunk = chunk + "        newarr [mscorlib]System.Object\n"
                    }
                    parts = push(parts, append_msil_line(chunk, "        ret"))
                    si = si + 1
                    continue
                }
            }
            # Bare unite nullary: `return Empty`
            if ret_expr == "Empty" || ret_expr == "None" {
                if ret_expr == "None" {
                    parts = push(parts, append_msil_line("", "        ldnull"))
                    parts = push(parts, "        ret\n")
                    si = si + 1
                    continue
                }
                let mut sum: utf8 = nominal_type_name(fn_ret_ty)
                if sum.length() == 0 {
                    sum = "VonValue"
                }
                let ur: BodyLowerResult = emit_unite_variant_ctor("", "Empty", "", sum, locals, submission)
                if !ur.ok {
                    return ur
                }
                parts = push(parts, append_msil_line(ur.instructions, "        ret"))
                si = si + 1
                continue
            }
            if looks_like_call_expr(ret_expr) {
                let cr: BodyLowerResult = emit_call_expr_hint("", ret_expr, locals, submission, fn_ret_ty)
                if !cr.ok {
                    return cr
                }
                parts = push(parts, append_msil_line(cr.instructions, "        ret"))
                si = si + 1
                continue
            }
            # `return ch == " " || …` / bool-typed returns — use condition lowering, not int expr.
            if fn_ret_ty == "bool" || ret_expr.contains(" || ") || ret_expr.contains(" && ") || ret_expr.contains(" == ") || ret_expr.contains(" != ") || ret_expr.contains(" >= ") || ret_expr.contains(" <= ") || ret_expr.contains(" > ") || ret_expr.contains(" < ") || ret_expr.contains(".contains(") || ret_expr.contains(".starts_with(") || ret_expr.contains(".ends_with(") {
                let br: BodyLowerResult = emit_bool_condition("", ret_expr, locals, submission)
                if br.ok {
                    parts = push(parts, append_msil_line(br.instructions, "        ret"))
                    si = si + 1
                    continue
                }
                if br.error.length() > 0 {
                    return br
                }
            }
            let vr: BodyLowerResult = emit_value_expr("", ret_expr, locals, submission)
            if !vr.ok {
                return vr
            }
            parts = push(parts, append_msil_line(vr.instructions, "        ret"))
            si = si + 1
            continue
        }
        # console_write_line("...") / std.io.print_line("...") / std.io.error("...")
        if stmt.starts_with("console_write_line(") || stmt.starts_with("std.io.print_line(") || stmt.starts_with("std.io.error(") {
            let callee: utf8 = "console_write_line"
            if stmt.starts_with("std.io.print_line(") {
                callee = "std.io.print_line"
            }
            if stmt.starts_with("std.io.error(") {
                callee = "std.io.error"
            }
            # Only treat as a pure literal when the whole arg is one string literal.
            # find_call_literal alone matches the first quote in `"…" + error.message`
            # and drops the concat — empty diagnostic after "解析 legion.von 失败 - ".
            let open_p: i32 = stmt.index_of("(")
            let close_p: i32 = last_index_of_text(stmt, ")")
            if open_p < 0 || close_p <= open_p {
                return body_lower_fail("无法解析打印调用：" + stmt)
            }
            let arg: utf8 = stmt.slice(open_p + 1, close_p - open_p - 1).trim()
            if is_string_literal_expr(arg) {
                let msg: utf8 = find_call_literal(stmt, callee)
                parts = push(parts, append_msil_line(append_msil_line("", msil_quote_string(msg)), "        call void [System.Console]System.Console::WriteLine(string)"))
                si = si + 1
                continue
            }
            let vr: BodyLowerResult = emit_value_expr("", arg, locals, submission)
            if !vr.ok {
                return vr
            }
            parts = push(parts, append_msil_line(vr.instructions, "        call void [System.Console]System.Console::WriteLine(string)"))
            si = si + 1
            continue
        }
        # Top-level `dest = push(dest, x)` only — never match `if … { dest = push(…) }`.
        if !stmt.starts_with("if ") && !stmt.starts_with("while ") && !stmt.starts_with("match ") && !stmt.starts_with("loop ") && stmt.contains(" = push(") {
            let eqp: i32 = stmt.index_of(" = push(")
            let dest: utf8 = stmt.slice(0, eqp).trim()
            if dest.index_of(" ") < 0 && dest.index_of("(") < 0 {
                let mut call_part: utf8 = stmt.slice(eqp + 3, stmt.length() - eqp - 3).trim()
                if call_part.ends_with(";") {
                    call_part = call_part.slice(0, call_part.length() - 1).trim()
                }
                let open_p: i32 = call_part.index_of("(")
                let close_p: i32 = matching_close_paren(call_part, open_p)
                if open_p > 0 && close_p > open_p {
                    let arglist: utf8 = call_part.slice(open_p + 1, close_p - open_p - 1).trim()
                    let args: [utf8] = split_call_args(arglist)
                    if args.length() == 2 {
                        let arr_e: utf8 = args⁅0⁆.trim()
                        let val_e: utf8 = args⁅1⁆.trim()
                        let pr: BodyLowerResult = emit_string_array_push(dest, arr_e, val_e, locals, lab, submission)
                        if !pr.ok {
                            return pr
                        }
                        if pr.next_lab > lab {
                            lab = pr.next_lab
                        }
                        parts = push(parts, pr.instructions)
                        si = si + 1
                        continue
                    }
                }
            }
        }
        # std.io.create_directory / write_file_text — side-effect statements
        if stmt.starts_with("std.io.create_directory(") && (stmt.ends_with(")") || stmt.ends_with(");")) {
            let close_p: i32 = last_index_of_text(stmt, ")")
            let arg: utf8 = stmt.slice(24, close_p - 24).trim()
            let ar: BodyLowerResult = emit_stack_expr("", arg, locals, submission)
            if !ar.ok {
                return ar
            }
            let mut chunk: utf8 = append_msil_line(ar.instructions, "        call class [System.IO.FileSystem]System.IO.DirectoryInfo [System.IO.FileSystem]System.IO.Directory::CreateDirectory(string)")
            chunk = append_msil_line(chunk, "        pop")
            parts = push(parts, chunk)
            si = si + 1
            continue
        }
        if stmt.starts_with("std.io.write_file_text(") && (stmt.ends_with(")") || stmt.ends_with(");")) {
            let mut call_e: utf8 = stmt.trim()
            if call_e.ends_with(";") {
                call_e = call_e.slice(0, call_e.length() - 1).trim()
            }
            let wr: BodyLowerResult = emit_std_io_call("", call_e, locals, submission)
            if !wr.ok {
                return wr
            }
            # value form leaves bool; statement discards it.
            parts = push(parts, append_msil_line(wr.instructions, "        pop"))
            si = si + 1
            continue
        }
        # recv.push(value) — ArrayList instance push → push(_items field).
        if stmt.contains(".push(") && (stmt.ends_with(")") || stmt.ends_with(");")) {
            let mut call_e: utf8 = stmt.trim()
            if call_e.ends_with(";") {
                call_e = call_e.slice(0, call_e.length() - 1).trim()
            }
            let push_at: i32 = call_e.index_of(".push(")
            if push_at > 0 {
                let open_p: i32 = push_at + 5
                let close_p: i32 = matching_close_paren(call_e, open_p)
                if close_p > open_p {
                    let after_p: utf8 = call_e.slice(close_p + 1, call_e.length() - close_p - 1).trim()
                    if after_p.length() == 0 {
                        let recv_p: utf8 = call_e.slice(0, push_at).trim()
                        let val_p: utf8 = call_e.slice(open_p + 1, close_p - open_p - 1).trim()
                        let loaded_p: PathLoadResult = emit_load_path("", recv_p, locals, structs)
                        if loaded_p.ok && (loaded_p.result_type == "class ArrayList" || loaded_p.result_type.ends_with(".ArrayList") || loaded_p.result_type.contains("ArrayList") || loaded_p.result_type.ends_with("List") || loaded_p.result_type.contains(" List") || (loaded_p.result_type.starts_with("class ") && loaded_p.result_type.contains("List"))) {
                            let items_p: utf8 = recv_p + "._items"
                            let pr: BodyLowerResult = emit_string_array_push(items_p, items_p, val_p, locals, lab, submission)
                            if !pr.ok {
                                return pr
                            }
                            if pr.next_lab > lab {
                                lab = pr.next_lab
                            }
                            parts = push(parts, pr.instructions)
                            si = si + 1
                            continue
                        }
                        if loaded_p.ok && loaded_p.result_type.ends_with("[]") {
                            let pr2: BodyLowerResult = emit_string_array_push(recv_p, recv_p, val_p, locals, lab, submission)
                            if !pr2.ok {
                                return pr2
                            }
                            if pr2.next_lab > lab {
                                lab = pr2.next_lab
                            }
                            parts = push(parts, pr2.instructions)
                            si = si + 1
                            continue
                        }
                    }
                }
            }
        }
        # Unit no-op in match arms / Result Fail arms: `()`.
        if stmt == "()" || stmt == "();" {
            si = si + 1
            continue
        }
        # bare `push(arr, x)` — mutate arr in place (same as arr = push(arr, x)).
        if stmt.starts_with("push(") {
            let open_bp: i32 = stmt.index_of("(")
            let close_bp: i32 = matching_close_paren(stmt, open_bp)
            if close_bp > open_bp {
                let arglist_bp: utf8 = stmt.slice(open_bp + 1, close_bp - open_bp - 1).trim()
                let args_bp: [utf8] = split_call_args(arglist_bp)
                if args_bp.length() == 2 {
                    let dest_bp: utf8 = args_bp⁅0⁆.trim()
                    let pr_bp: BodyLowerResult = emit_string_array_push(dest_bp, dest_bp, args_bp⁅1⁆.trim(), locals, lab, submission)
                    if !pr_bp.ok {
                        return pr_bp
                    }
                    if pr_bp.next_lab > lab {
                        lab = pr_bp.next_lab
                    }
                    parts = push(parts, pr_bp.instructions)
                    si = si + 1
                    continue
                }
            }
        }
        # bare call: print_root_help() / execute_build(cmd_args) / push(arr, x)
        if looks_like_call_expr(stmt) {
            let copen: i32 = stmt.index_of("(")
            let cname: utf8 = stmt.slice(0, copen).trim()
            if cname == "push" {
                let close_p: i32 = last_index_of_text(stmt, ")")
                let arglist: utf8 = stmt.slice(copen + 1, close_p - copen - 1).trim()
                let args: [utf8] = split_call_args(arglist)
                if args.length() != 2 {
                    return body_lower_fail("push 语句需要两参数：" + stmt)
                }
                let dest: utf8 = args⁅0⁆.trim()
                let pr: BodyLowerResult = emit_string_array_push(dest, dest, args⁅1⁆.trim(), locals, lab, submission)
                if !pr.ok {
                    return pr
                }
                if pr.next_lab > lab {
                    lab = pr.next_lab
                }
                parts = push(parts, pr.instructions)
                si = si + 1
                continue
            }
            let cr: BodyLowerResult = emit_call_expr("", stmt, locals, submission)
            if !cr.ok {
                return cr
            }
            # void calls leave nothing; non-void discarded → pop
            let ret_clr: utf8 = lookup_callee_return_clr(submission, cname)
            if ret_clr.length() > 0 && ret_clr != "void" {
                parts = push(parts, append_msil_line(cr.instructions, "        pop"))
            }
            else {
                parts = push(parts, cr.instructions)
            }
            si = si + 1
            continue
        }
        # if cond { ... } else { ... }
        if stmt.starts_with("if ") {
            let after: utf8 = stmt.slice(3, stmt.length() - 3).trim()
            let brace: i32 = index_of_brace_outside_string(after)
            if brace < 0 {
                return body_lower_fail("if 缺少体：" + stmt)
            }
            let cond: utf8 = after.slice(0, brace).trim()
            let then_end: i32 = match_brace_close(after, brace)
            if then_end < 0 {
                return body_lower_fail("if 体未闭合")
            }
            let then_inner: utf8 = after.slice(brace + 1, then_end - brace - 1)
            let rest: utf8 = after.slice(then_end + 1, after.length() - then_end - 1).trim()
            let mut else_inner: utf8 = ""
            # `else if cond { ... }` must stay a full `if` stmt in the else arm.
            # Extracting only the brace body drops the elif condition (→ always-run else).
            if rest.starts_with("else if ") {
                else_inner = rest.slice(5, rest.length() - 5).trim()
            }
            else {
                # Keyword `else` only — not locals like `else_inner`.
                let else_kw: bool = rest == "else" || rest.starts_with("else ") || rest.starts_with("else{") || rest.starts_with("else\n") || rest.starts_with("else\t")
                if else_kw {
                    let eb: i32 = index_of_brace_outside_string(rest)
                    if eb < 0 {
                        return body_lower_fail("else 缺少体")
                    }
                    else_inner = extract_function_inner_body("x" + rest.slice(eb, rest.length() - eb))
                }
            }
            let else_l: utf8 = "E" + format("{}", lab)
            let end_l: utf8 = "F" + format("{}", lab)
            let then_l: utf8 = "T" + format("{}", lab)
            lab = lab + 1
            let lt: i32 = cond.index_of(" < ")
            if lt > 0 && !cond.contains(" && ") && !cond.contains(" || ") && cond.index_of("(") < 0 {
                let left: utf8 = cond.slice(0, lt).trim()
                let right: utf8 = cond.slice(lt + 3, cond.length() - lt - 3).trim()
                let lr: BodyLowerResult = emit_int_expr("", left, locals, submission)
                if !lr.ok {
                    return lr
                }
                let rr: BodyLowerResult = emit_int_expr(lr.instructions, right, locals, submission)
                if !rr.ok {
                    return rr
                }
                parts = push(parts, append_msil_line(rr.instructions, "        bge " + else_l))
            }
            else if cond.ends_with(" == 0") && !cond.contains(" && ") && !cond.contains(" || ") && cond.index_of(".starts_with(") < 0 && cond.index_of(".ends_with(") < 0 {
                let left: utf8 = cond.slice(0, cond.length() - 5).trim()
                let lr: BodyLowerResult = emit_int_expr("", left, locals, submission)
                if !lr.ok {
                    return lr
                }
                parts = push(parts, append_msil_line(lr.instructions, "        brtrue " + else_l))
            }
            else if cond.contains(" || ") && !cond.contains(" && ") && cond.index_of("(") < 0 {
                let mut rest_or: utf8 = cond
                let mut any_or: bool = false
                while rest_or.contains(" || ") {
                    let op: i32 = rest_or.index_of(" || ")
                    let piece: utf8 = rest_or.slice(0, op).trim()
                    rest_or = rest_or.slice(op + 4, rest_or.length() - op - 4).trim()
                    let er: BodyLowerResult = emit_bool_condition("", piece, locals, submission)
                    if !er.ok {
                        return body_lower_fail("|| 子条件无法 lowering：" + piece + " / " + er.error)
                    }
                    parts = push(parts, append_msil_line(er.instructions, "        brtrue " + then_l))
                    any_or = true
                }
                let last_er: BodyLowerResult = emit_bool_condition("", rest_or, locals, submission)
                if !last_er.ok || !any_or {
                    return body_lower_fail("|| 条件无法 lowering：" + cond + " / " + last_er.error)
                }
                parts = push(parts, append_msil_line(last_er.instructions, "        brfalse " + else_l))
                parts = push(parts, then_l + ":\n")
            }
            else {
                let bc: BodyLowerResult = emit_bool_condition("", cond, locals, submission)
                if !bc.ok {
                    return bc
                }
                parts = push(parts, append_msil_line(bc.instructions, "        brfalse " + else_l))
            }
            let then_stmts: [utf8] = split_top_level_statements(then_inner)
            let tr: BodyLowerResult = emit_statements_ret("", then_stmts, locals, lab, submission, continue_label, fn_ret_ty, break_label)
            if !tr.ok {
                return tr
            }
            if tr.next_lab > lab {
                lab = tr.next_lab
            }
            parts = push(parts, tr.instructions)
            parts = push(parts, "        br " + end_l + "\n")
            parts = push(parts, else_l + ":\n")
            if else_inner.length() > 0 {
                let else_stmts: [utf8] = split_top_level_statements(else_inner)
                let er: BodyLowerResult = emit_statements_ret("", else_stmts, locals, lab, submission, continue_label, fn_ret_ty, break_label)
                if !er.ok {
                    return er
                }
                if er.next_lab > lab {
                    lab = er.next_lab
                }
                parts = push(parts, er.instructions)
            }
            parts = push(parts, end_l + ":\n")
            si = si + 1
            continue
        }
        # Match-arm / block bare expression → implicit return (`case Some(value): value`).
        if fn_ret_ty.length() > 0 && fn_ret_ty != "unit" && fn_ret_ty != "void" {
            let vr: BodyLowerResult = emit_value_expr("", stmt, locals, submission)
            if vr.ok {
                parts = push(parts, append_msil_line(vr.instructions, "        ret"))
                si = si + 1
                continue
            }
            let ir: BodyLowerResult = emit_int_expr("", stmt, locals, submission)
            if ir.ok {
                parts = push(parts, append_msil_line(ir.instructions, "        ret"))
                si = si + 1
                continue
            }
            let br: BodyLowerResult = emit_bool_condition("", stmt, locals, submission)
            if br.ok {
                parts = push(parts, append_msil_line(br.instructions, "        ret"))
                si = si + 1
                continue
            }
        }
        return body_lower_fail("不支持的语句（需扩展 body→MSIL / MIR）：" + stmt)
    }
    return body_lower_ok_lab(join_msil_parts(parts), "", lab)
}

micro try_register_let_local(locals: [BodyLocal], slot: i32, stmt: utf8, submission: FragmentSubmission) -> BodyLocal {
    # Returns a BodyLocal with slot>=0 if registered; slot field holds next slot to use when name empty.
    let structs: [ParsedStruct] = submission.struct_defs
    let unites: [ParsedUnite] = submission.unite_defs
    let s: utf8 = stmt.trim()
    if !s.starts_with("let ") {
        return BodyLocal {
            name: "",
            clr_type: "",
            slot: slot,
            is_arg: false
        }
    }
    let rest: utf8 = s.slice(4, s.length() - 4).trim()
    let mut name_part: utf8 = rest
    if name_part.starts_with("mut ") {
        name_part = name_part.slice(4, name_part.length() - 4).trim()
    }
    let colon: i32 = name_part.index_of(":")
    let eq: i32 = name_part.index_of("=")
    if colon > 0 && eq > colon {
        let name: utf8 = name_part.slice(0, colon).trim()
        let ty: utf8 = name_part.slice(colon + 1, eq - colon - 1).trim()
        let mut clr: utf8 = clr_type_for_annotation_with_defs(ty, structs, unites)
        if clr.length() == 0 {
            let n: utf8 = nominal_type_name(ty)
            if find_unite_def(unites, n).name.length() > 0 || find_struct_def(structs, n).name.length() > 0 {
                clr = msil_class_ty(n)
            }
        }
        if clr.length() == 0 && ty.length() > 0 {
            # Unknown nominal — object erase (Rust layout miss → Object), do not invent `class Name`.
            clr = "object"
        }
        if name.length() > 0 && name.index_of(" ") < 0 && find_local_slot(locals, name) < 0 {
            return BodyLocal {
                name: name,
                clr_type: clr,
                slot: slot,
                is_arg: false
            }
        }
    }
    # Untyped let: `let text = std.io.read_file_text(...)` → infer string.
    if (colon < 0 || (eq > 0 && colon > eq)) && eq > 0 {
        let name: utf8 = name_part.slice(0, eq).trim()
        let mut rhs: utf8 = name_part.slice(eq + 1, name_part.length() - eq - 1).trim()
        if rhs.ends_with(";") {
            rhs = rhs.slice(0, rhs.length() - 1).trim()
        }
        let mut clr: utf8 = ""
        if rhs.starts_with("std.io.read_file_text(") || rhs.starts_with("std.io.get_current_directory(") {
            clr = "string"
        }
        else if rhs == "true" || rhs == "false" {
            clr = "int32"
        }
        else if rhs.length() > 0 {
            # digit / `-digit` literal → int32 (untyped `let mut i = 0`).
            let mut all_dig: bool = true
            let mut di: i32 = 0
            if rhs.starts_with("-") {
                if rhs.length() == 1 {
                    all_dig = false
                }
                di = 1
            }
            while di < rhs.length() {
                let ch: utf8 = rhs.slice(di, 1)
                if ch < "0" || ch > "9" {
                    all_dig = false
                }
                di = di + 1
            }
            if all_dig {
                clr = "int32"
            }
        }
        if clr.length() == 0 && rhs.starts_with("[") && rhs.ends_with("]") {
            clr = "string[]"
        }
        else if clr.length() == 0 && looks_like_call_expr(rhs) {
            let open_c: i32 = rhs.index_of("(")
            let cname: utf8 = rhs.slice(0, open_c).trim()
            let ret_clr: utf8 = lookup_callee_return_clr(submission, cname)
            if ret_clr.length() > 0 && ret_clr != "void" {
                clr = ret_clr
            }
            else if cname == "digit_value" || cname.ends_with("_len") || cname.starts_with("count_") {
                clr = "int32"
            }
            else {
                clr = "object"
            }
        }
        else if clr.length() == 0 && find_local(locals, rhs).clr_type.length() > 0 {
            clr = find_local(locals, rhs).clr_type
        }
        else if clr.length() == 0 {
            clr = "string"
        }
        if name.length() > 0 && name.index_of(" ") < 0 && find_local_slot(locals, name) < 0 {
            return BodyLocal {
                name: name,
                clr_type: clr,
                slot: slot,
                is_arg: false
            }
        }
    }
    return BodyLocal {
        name: "",
        clr_type: "",
        slot: slot,
        is_arg: false
    }
}

micro collect_lets_as_locals(stmts: [utf8], structs: [ParsedStruct], submission: FragmentSubmission) -> [BodyLocal] {
    let mut locals: [BodyLocal] = []
    let mut slot: i32 = 0
    let mut i: usize = 0
    while i < stmts.length() {
        let stmt: utf8 = stmts⁅i⁆.trim()
        let reg: BodyLocal = try_register_let_local(locals, slot, stmt, submission)
        if reg.name.length() > 0 {
            locals = push(locals, reg)
            slot = slot + 1
        }
        if stmt.starts_with("match ") {
            let after: utf8 = stmt.slice(6, stmt.length() - 6).trim()
            let brace: i32 = index_of_brace_outside_string(after)
            if brace >= 0 {
                let scrut: utf8 = after.slice(0, brace).trim()
                let type_arg: utf8 = infer_unite_type_arg(scrut, submission)
                let sum_name: utf8 = infer_unite_sum_name(scrut, locals, submission)
                let inner: utf8 = extract_function_inner_body("x" + after.slice(brace, after.length() - brace))
                let mut rest: utf8 = inner.trim()
                while rest.starts_with("case ") {
                    let arm_after: utf8 = rest.slice(5, rest.length() - 5).trim()
                    let colon: i32 = arm_after.index_of(":")
                    if colon < 0 {
                        break
                    }
                    let pat: utf8 = arm_after.slice(0, colon).trim()
                    let body_rest: utf8 = arm_after.slice(colon + 1, arm_after.length() - colon - 1)
                    # Brace-depth aware — nested `match { case Fine(...): }` must not steal outer Fine binds.
                    let next_case: i32 = find_next_match_arm_boundary(body_rest)
                    let mut arm_body: utf8 = body_rest
                    if next_case >= 0 {
                        let next_at: i32 = match_arm_start_after_newline(body_rest, next_case)
                        arm_body = body_rest.slice(0, next_case)
                        rest = body_rest.slice(next_at, body_rest.length() - next_at).trim()
                    }
                    else {
                        rest = ""
                    }
                    let popen: i32 = pat.index_of("(")
                    let pclose: i32 = last_index_of_text(pat, ")")
                    if popen > 0 && pclose > popen {
                        let vname: utf8 = pat.slice(0, popen).trim()
                        let bind: utf8 = pat.slice(popen + 1, pclose - popen - 1).trim()
                        let uv: ParsedUniteVariant = find_unite_variant(find_unite_def(submission.unite_defs, sum_name), vname)
                        let mut pay_ty: utf8 = uv.payload_type
                        if pay_ty == "T" || pay_ty.length() == 0 {
                            pay_ty = type_arg
                        }
                        if pay_ty.length() == 0 {
                            if vname == "Object" {
                                pay_ty = "[VonField]"
                            }
                            else if vname == "Array" {
                                pay_ty = "[VonValue]"
                            }
                            else if vname == "Text" || vname == "Name" || vname == "Number" {
                                pay_ty = "utf8"
                            }
                            else if vname == "Flag" {
                                pay_ty = "bool"
                            }
                        }
                        let mut clr: utf8 = clr_type_for_annotation_with_structs(pay_ty, structs)
                        if clr.length() == 0 {
                            let cast_ty: utf8 = payload_cast_class_for_arm(vname, sum_name, type_arg, submission)
                            if cast_ty == "string" || cast_ty.contains("System.String") {
                                clr = "string"
                            }
                            else if cast_ty.ends_with("[]") {
                                if cast_ty == "string[]" {
                                    clr = "string[]"
                                }
                                else {
                                    clr = msil_class_ty(cast_ty)
                                }
                            }
                            else if cast_ty.length() > 0 && !cast_ty.starts_with("[") {
                                clr = msil_class_ty(cast_ty)
                            }
                            else {
                                clr = "object"
                            }
                        }
                        if bind.length() > 0 && bind != "_" && find_local_slot(locals, bind) < 0 {
                            locals = push(locals, BodyLocal {
                                name: bind,
                                clr_type: clr,
                                slot: slot,
                                is_arg: false
                            })
                            slot = slot + 1
                        }
                    }
                    let nested: [utf8] = split_top_level_statements(arm_body)
                    let nested_locals: [BodyLocal] = collect_lets_as_locals(nested, structs, submission)
                    let mut ni: usize = 0
                    while ni < nested_locals.length() {
                        let nl: BodyLocal = nested_locals⁅ni⁆
                        if find_local_slot(locals, nl.name) < 0 {
                            locals = push(locals, BodyLocal {
                                name: nl.name,
                                clr_type: nl.clr_type,
                                slot: slot,
                                is_arg: false
                            })
                            slot = slot + 1
                        }
                        ni = ni + 1
                    }
                }
            }
        }
        # loop bind + nested lets
        if stmt.starts_with("loop ") {
            let after_loop: utf8 = stmt.slice(5, stmt.length() - 5).trim()
            let in_at: i32 = after_loop.index_of(" in ")
            let brace_l: i32 = index_of_brace_outside_string(after_loop)
            if in_at > 0 && brace_l > in_at {
                let bind: utf8 = after_loop.slice(0, in_at).trim()
                let iter: utf8 = after_loop.slice(in_at + 4, brace_l - in_at - 4).trim()
                let mut bind_clr: utf8 = "string"
                let iter_l: BodyLocal = find_local(locals, iter)
                if iter_l.slot >= 0 && iter_l.clr_type.ends_with("[]") {
                    let elem: utf8 = iter_l.clr_type.slice(0, iter_l.clr_type.length() - 2).trim()
                    if elem.starts_with("class ") {
                        bind_clr = elem
                    }
                    else if elem == "string" {
                        bind_clr = "string"
                    }
                    else if elem == "int32" || elem == "uint8" {
                        bind_clr = "int32"
                    }
                    else {
                        bind_clr = msil_class_ty(elem)
                    }
                }
                if find_local_slot(locals, bind) < 0 {
                    locals = push(locals, BodyLocal {
                        name: bind,
                        clr_type: bind_clr,
                        slot: slot,
                        is_arg: false
                    })
                    slot = slot + 1
                }
                let inner: utf8 = extract_function_inner_body("x" + after_loop.slice(brace_l, after_loop.length() - brace_l))
                let nested: [utf8] = split_top_level_statements(inner)
                let nested_locals: [BodyLocal] = collect_lets_as_locals(nested, structs, submission)
                let mut ni: usize = 0
                while ni < nested_locals.length() {
                    let nl: BodyLocal = nested_locals⁅ni⁆
                    if find_local_slot(locals, nl.name) < 0 {
                        locals = push(locals, BodyLocal {
                            name: nl.name,
                            clr_type: nl.clr_type,
                            slot: slot,
                            is_arg: false
                        })
                        slot = slot + 1
                    }
                    ni = ni + 1
                }
            }
        }
        # Nested lets inside while/if bodies (same function activation).
        if stmt.starts_with("while ") || stmt.starts_with("if ") {
            let brace: i32 = stmt.index_of("{")
            if brace >= 0 {
                let inner: utf8 = extract_function_inner_body("x" + stmt.slice(brace, stmt.length() - brace))
                let nested: [utf8] = split_top_level_statements(inner)
                let nested_locals: [BodyLocal] = collect_lets_as_locals(nested, structs, submission)
                let mut ni: usize = 0
                while ni < nested_locals.length() {
                    let nl: BodyLocal = nested_locals⁅ni⁆
                    if find_local_slot(locals, nl.name) < 0 {
                        locals = push(locals, BodyLocal {
                            name: nl.name,
                            clr_type: nl.clr_type,
                            slot: slot,
                            is_arg: false
                        })
                        slot = slot + 1
                    }
                    ni = ni + 1
                }
                # else branch of if
                if stmt.starts_with("if ") {
                    let else_at: i32 = stmt.index_of("else")
                    if else_at > 0 {
                        let else_part: utf8 = stmt.slice(else_at, stmt.length() - else_at).trim()
                        let eb: i32 = else_part.index_of("{")
                        if eb >= 0 {
                            let else_inner: utf8 = extract_function_inner_body("x" + else_part.slice(eb, else_part.length() - eb))
                            let else_stmts: [utf8] = split_top_level_statements(else_inner)
                            let else_locals: [BodyLocal] = collect_lets_as_locals(else_stmts, structs, submission)
                            let mut ei: usize = 0
                            while ei < else_locals.length() {
                                let el: BodyLocal = else_locals⁅ei⁆
                                if find_local_slot(locals, el.name) < 0 {
                                    locals = push(locals, BodyLocal {
                                        name: el.name,
                                        clr_type: el.clr_type,
                                        slot: slot,
                                        is_arg: false
                                    })
                                    slot = slot + 1
                                }
                                ei = ei + 1
                            }
                        }
                    }
                }
            }
        }
        i = i + 1
    }
    return locals
}

# Register one `let` starting at `at` (after optional spaces). Returns next index (>= at+1).
micro scan_text_lets_take(text: utf8, at: i32, locals: [BodyLocal], slot: i32, submission: FragmentSubmission) -> BodyLocal {
    # Reuse BodyLocal.slot as "next_i"; name empty means no register. Avoid fat loop locals (CLR SSA).
    let mut k: i32 = at
    while k < text.length() {
        let w: utf8 = text.slice(k, 1)
        if w == " " || w == "\t" {
            k = k + 1
            continue
        }
        break
    }
    if k + 4 > text.length() || text.slice(k, 4) != "let " {
        return BodyLocal {
            name: "",
            clr_type: "",
            slot: at + 1,
            is_arg: false
        }
    }
    let start: i32 = k
    let mut end: i32 = k + 4
    while end < text.length() {
        let cj: utf8 = text.slice(end, 1)
        if cj == "\n" || cj == "{" || cj == "#" {
            break
        }
        end = end + 1
    }
    let mut next_i: i32 = end
    if next_i <= start {
        next_i = start + 1
    }
    if end <= start {
        return BodyLocal {
            name: "",
            clr_type: "",
            slot: next_i,
            is_arg: false
        }
    }
    let count: i32 = end - start
    let stmt: utf8 = text.slice(start, count).trim()
    let reg: BodyLocal = try_register_let_local(locals, slot, stmt, submission)
    if reg.name.length() > 0 {
        return BodyLocal {
            name: reg.name,
            clr_type: reg.clr_type,
            slot: next_i,
            is_arg: false
        }
    }
    return BodyLocal {
        name: "",
        clr_type: "",
        slot: next_i,
        is_arg: false
    }
}

# Scan raw body text for `let`/`let mut` (catches deep nesting split missed).
micro scan_text_lets(text: utf8, locals: [BodyLocal], submission: FragmentSubmission) -> [BodyLocal] {
    let mut acc: [BodyLocal] = locals
    let mut slot: i32 = locals.length() as i32
    let mut i: i32 = 0
    let mut in_str: utf8 = ""
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if in_str.length() > 0 {
            if ch == in_str {
                in_str = ""
                i = i + 1
                continue
            }
            i = string_lit_advance(text, i)
            continue
        }
        if ch == dq() || ch == "'" {
            in_str = ch
            i = i + 1
            continue
        }
        if ch == "#" || (ch == "/" && i + 1 < text.length() && text.slice(i + 1, 1) == "/") {
            while i < text.length() && text.slice(i, 1) != "\n" {
                i = i + 1
            }
            continue
        }
        let at_line: bool = i == 0
        if !at_line {
            let prev: utf8 = text.slice(i - 1, 1)
            at_line = prev == "\n" || prev == "\r" || prev == "{" || prev == ";"
        }
        # Indented lets: walk back over spaces/tabs/CR to a line opener.
        if !at_line && ch != " " && ch != "\t" && ch != "\n" && ch != "\r" {
            let mut j: i32 = i - 1
            while j >= 0 {
                let p: utf8 = text.slice(j, 1)
                if p == "\n" || p == "\r" || p == "{" || p == ";" {
                    at_line = true
                    break
                }
                if p != " " && p != "\t" {
                    break
                }
                if j == 0 {
                    at_line = true
                    break
                }
                j = j - 1
            }
        }
        if at_line {
            let step: BodyLocal = scan_text_lets_take(text, i, acc, slot, submission)
            if step.slot > i {
                if step.name.length() > 0 {
                    acc = push(acc, BodyLocal {
                        name: step.name,
                        clr_type: step.clr_type,
                        slot: slot,
                        is_arg: false
                    })
                    slot = slot + 1
                }
                i = step.slot
                continue
            }
        }
        i = i + 1
    }
    return acc
}

micro build_locals_clause(locals: [BodyLocal]) -> utf8 {
    if locals.length() == 0 {
        return ""
    }
    let mut clause: utf8 = "    .locals init ("
    let mut i: usize = 0
    while i < locals.length() {
        if i > 0 {
            clause = clause + ", "
        }
        # Always quote local names — Framework ilasm rejects bare `package` / similar.
        clause = clause + locals⁅i⁆.clr_type + " '" + locals⁅i⁆.name + "'"
        i = i + 1
    }
    clause = clause + ")"
    return clause
}

micro merge_params_and_locals(params: [BodyLocal], lets: [BodyLocal]) -> [BodyLocal] {
    let mut all: [BodyLocal] = []
    let mut i: usize = 0
    while i < params.length() {
        all = push(all, params⁅i⁆)
        i = i + 1
    }
    i = 0
    while i < lets.length() {
        all = push(all, lets⁅i⁆)
        i = i + 1
    }
    return all
}

micro rewrite_self_type_in_text(text: utf8, owner: utf8) -> utf8 {
    if owner.length() == 0 || !text.contains("Self") {
        return text
    }
    # Avoid nested `let b`/`let a` (CLR let-scan + SSA); keep few homes.
    let mut acc: utf8 = ""
    let mut i: i32 = 0
    while i < text.length() {
        if i + 4 <= text.length() && text.slice(i, 4) == "Self" {
            let before_ok: bool = i == 0 || text.slice(i - 1, 1) == " " || text.slice(i - 1, 1) == "(" || text.slice(i - 1, 1) == "{" || text.slice(i - 1, 1) == "\n" || text.slice(i - 1, 1) == "\t" || text.slice(i - 1, 1) == ">" || text.slice(i - 1, 1) == ","
            let after_ok: bool = i + 4 >= text.length() || text.slice(i + 4, 1) == " " || text.slice(i + 4, 1) == "{" || text.slice(i + 4, 1) == "\n" || text.slice(i + 4, 1) == "\t" || text.slice(i + 4, 1) == "," || text.slice(i + 4, 1) == ")"
            if before_ok && after_ok {
                acc = acc + owner
                i = i + 4
                continue
            }
        }
        acc = acc + text.slice(i, 1)
        i = i + 1
    }
    return acc
}

# True if the last non-label opcode is `ret` / `throw` (early rets elsewhere do not count).
# A trailing label is fall-through (nested match join) — do NOT walk past it to an earlier `ret`,
# or the outer arm skips `br end` and falls into the next miss/ldnull (collect_source_closure NRE).
micro msil_ends_with_terminator(instr: utf8) -> bool {
    let mut cur: utf8 = ""
    let mut seen_line: bool = false
    let mut j: i32 = instr.length() - 1
    while j >= 0 {
        let ch: utf8 = instr.slice(j, 1)
        if ch == "\n" {
            if seen_line || cur.length() > 0 {
                let t: utf8 = cur.trim()
                cur = ""
                seen_line = false
                if t.length() == 0 {
                    j = j - 1
                    continue
                }
                # Trailing label = join / fall-through, not a terminator.
                if t.ends_with(":") && !t.contains(" ") {
                    return false
                }
                if t == "ret" || t == "throw" {
                    return true
                }
                return false
            }
            j = j - 1
            continue
        }
        if ch != "\r" {
            cur = ch + cur
            seen_line = true
        }
        j = j - 1
    }
    let t2: utf8 = cur.trim()
    if t2.length() == 0 {
        return false
    }
    if t2.ends_with(":") && !t2.contains(" ") {
        return false
    }
    return t2 == "ret" || t2 == "throw"
}

micro lower_function_body_to_msil(body_source: utf8, returns_void: bool, submission: FragmentSubmission) -> BodyLowerResult {
    if body_source_bypass_retired() {
        return body_lower_fail(body_source_bypass_retired_error())
    }
    # LEGACY BYPASS (not nyar.emitter). Expand coverage via MIR instead.
    # Forward / extern decls: header-only (optional `;`, no `{`) — emit stub.
    # Use comment-aware brace find — `# … `{` …` must not look like a body.
    let open_brace: i32 = index_of_brace_outside_string(body_source)
    if body_source.trim().length() == 0 || open_brace < 0 {
        if returns_void {
            return body_lower_ok(append_msil_line("", "        ret"), "")
        }
        return body_lower_ok(append_msil_line(append_msil_line("", "        ldc.i4.0"), "        ret"), "")
    }
    let close_brace: i32 = match_brace_close(body_source, open_brace)
    if close_brace < 0 {
        return body_lower_fail("soft:unbalanced-braces")
    }
    let structs: [ParsedStruct] = submission.struct_defs
    let owner: utf8 = extract_body_owner_type(body_source)
    let mut inner: utf8 = ""
    if close_brace > open_brace + 1 {
        inner = body_source.slice(open_brace + 1, close_brace - open_brace - 1)
    }
    inner = strip_match_arch_else(inner)
    inner = rewrite_self_type_in_text(inner, owner)
    if inner.length() == 0 {
        if returns_void {
            return body_lower_ok(append_msil_line("", "        ret"), "")
        }
        # Fail-closed: non-void `{}` must not become ldnull/0 (parse_module_source NRE).
        # Forward decls without `{` still use the open_brace < 0 path above.
        return body_lower_fail("非 void 函数体为空（拒绝空桩）")
    }
    let params: [BodyLocal] = parse_function_params(body_source, structs)
    let stmts: [utf8] = split_top_level_statements(inner)
    let mut lets: [BodyLocal] = collect_lets_as_locals(stmts, structs, submission)
    lets = scan_text_lets(inner, lets, submission)
    lets = append_push_temps(lets, body_source)
    # Args use ldarg; lets use ldloc from 0 (is_arg distinguishes).
    let locals: [BodyLocal] = merge_params_and_locals(params, lets)
    let locals_clause: utf8 = build_locals_clause(lets)
    let fn_ret_ty: utf8 = extract_return_type_text(body_source)
    let emitted: BodyLowerResult = emit_statements_ret("", stmts, locals, 0, submission, "", fn_ret_ty, "")
    if !emitted.ok {
        return emitted
    }
    let mut instr: utf8 = emitted.instructions
    # Early `ret` in if-arms must not skip a fall-through terminator (InvalidProgram).
    if !msil_ends_with_terminator(instr) {
        if returns_void {
            instr = append_msil_line(instr, "        ret")
        }
        else if instr.length() == 0 {
            return body_lower_fail("非 void 函数缺少 return")
        }
        else {
            # Bootstrap: fall through with typed default when arms/loops omitted a ret.
            let ret_ty: utf8 = extract_return_type_text(body_source)
            let ret_clr: utf8 = clr_type_for_annotation_with_structs(ret_ty, submission.struct_defs)
            if ret_clr == "string" {
                instr = append_msil_line(instr, "        ldstr " + dq() + dq())
            }
            else if ret_clr.ends_with("[]") {
                instr = append_msil_line(instr, "        ldnull")
            }
            else if ret_clr.starts_with("class ") || ret_clr == "object" {
                instr = append_msil_line(instr, "        ldnull")
            }
            else {
                instr = append_msil_line(instr, "        ldc.i4.0")
            }
            instr = append_msil_line(instr, "        ret")
        }
    }
    # Non-empty source must not collapse to a pure null/0 stub (parse_module_source NRE).
    if !returns_void && stmts.length() > 0 {
        let tstub: utf8 = instr.trim()
        if tstub == "ldnull\n        ret" || tstub == "        ldnull\n        ret" || tstub == "ldc.i4.0\n        ret" || tstub == "        ldc.i4.0\n        ret" {
            return body_lower_fail("非 void 函数被降成空桩（拒绝 ldnull/0;ret）")
        }
        if !tstub.contains("call") && !tstub.contains("stloc") && !tstub.contains("newobj") && !tstub.contains("ldloc") && (tstub.contains("ldnull") || tstub.starts_with("ldc.i4.0")) && tstub.ends_with("ret") {
            return body_lower_fail("非 void 函数被降成空桩（拒绝 ldnull/0;ret）")
        }
    }
    # Method-local label uniquify (von_* / nested if-expr collisions).
    instr = uniquify_msil_labels(instr)
    return body_lower_ok(instr, locals_clause)
}

micro lower_function_body_to_msil_plain(body_source: utf8, returns_void: bool) -> BodyLowerResult {
    return lower_function_body_to_msil(body_source, returns_void, empty_fragment_submission())
}
