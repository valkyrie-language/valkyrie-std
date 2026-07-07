namespace nyar.language.valkyrie;

using std.io;

micro push_unique_text(items: [utf8], value: utf8) -> [utf8] {
    let mut i: usize = 0
    while i < items.length() {
        if items⁅i⁆ == value {
            return items
        }
        i = i + 1
    }
    return push(items, value)
}

micro contains_text(items: [utf8], value: utf8) -> bool {
    let mut i: usize = 0
    while i < items.length() {
        if items⁅i⁆ == value {
            return true
        }
        i = i + 1
    }
    return false
}

micro build_fragment_from_modules(modules: [ParsedModule], module_count: usize, project_name: utf8) -> FragmentSubmission {
    let mut submission: FragmentSubmission = empty_fragment_submission()
    submission.fragment_id = "functions"
    if module_count == 0 {
        return submission
    }

    let primary: ParsedModule = modules⁅0⁆
    submission.module_name = namespace_to_symbol(primary.namespace_name)
    if submission.module_name.length() == 0 {
        submission.module_name = project_name
    }

    let mut mi: usize = 0
    while mi < module_count {
        let parsed: ParsedModule = modules⁅mi⁆
        let fn_count: usize = parsed.functions.length()
        let mut fi: usize = 0
        while fi < fn_count {
            let item: ParsedFunction = parsed.functions⁅fi⁆
            let symbol: utf8 = qualified_symbol(parsed.namespace_name, item.name)
            submission.exported_operations = push_unique_text(submission.exported_operations, symbol)
            if item.is_clr_extern {
                std.io.print_line("[v1-debug] clr_bind=" + symbol + " => [" + item.clr_extern.assembly + "]" + item.clr_extern.owner_type + "::" + item.clr_extern.method_name)
                submission.external_import_bindings = push(submission.external_import_bindings, ExternalImportBinding {
                    symbol: symbol,
                    link: ExternalImportLink {
                        boundary: "clr",
                        platform_tag: "clr",
                        locator_segments: [
                            item.clr_extern.assembly,
                            item.clr_extern.owner_type,
                            item.clr_extern.method_name
                        ]
                    }
                })
            }
            if item.return_is_unit {
                submission.void_returns = push_unique_text(submission.void_returns, symbol)
            }
            # Prefer `legion` over later `[main]` entries (voa/vcc/main).
            if item.name == "legion" {
                submission.entry_operation = symbol
            }
            else if submission.entry_operation.length() == 0 {
                if item.is_main || item.name == "main" {
                    submission.entry_operation = symbol
                }
            }
            # Avoid Option — CLR Some(utf8) often lowers to bare string / null.
            let literal: utf8 = body_contains_return_literal(item.body_source)
            if literal.length() > 0 {
                submission.literal_returns = push_unique_text(submission.literal_returns, symbol)
                submission.literal_return_values = push(submission.literal_return_values, literal)
            }
            let int_digits: utf8 = body_return_integer_digits(item.body_source)
            if int_digits.length() > 0 {
                submission.integer_returns = push_unique_text(submission.integer_returns, symbol)
                submission.integer_return_values = push(submission.integer_return_values, int_digits)
            }
            if !item.is_clr_extern {
                submission.body_symbols = push(submission.body_symbols, symbol)
                submission.body_sources = push(submission.body_sources, item.body_source)
            }
            fi = fi + 1
        }
        mi = mi + 1
    }

    mi = 0
    while mi < module_count {
        let parsed: ParsedModule = modules⁅mi⁆
        let fn_count: usize = parsed.functions.length()
        let mut fi: usize = 0
        while fi < fn_count {
            let item: ParsedFunction = parsed.functions⁅fi⁆
            if item.is_clr_extern {
                fi = fi + 1
                continue
            }
            let caller: utf8 = qualified_symbol(parsed.namespace_name, item.name)
            if item.name == "main" || item.name == "legion" {
                std.io.print_line("[v1-debug] body_len_" + item.name + "=" + format("{}", item.body_source.length()))
                if item.body_source.length() > 0 {
                    let blen: i32 = item.body_source.length()
                    let preview_len: i32 = if blen < 80 { blen } else { 80 }
                    std.io.print_line("[v1-debug] body_preview=" + item.body_source.slice(0, preview_len))
                }
            }
            let message: utf8 = find_call_literal(item.body_source, "console_write_line")
            if item.name == "main" {
                std.io.print_line("[v1-debug] main_msg_len=" + format("{}", message.length()))
            }
            if message.length() > 0 {
                let callee: utf8 = qualified_symbol(parsed.namespace_name, "console_write_line")
                let mut dup: bool = false
                let mut ei: usize = 0
                let en: usize = submission.external_call_edges.length()
                while ei < en {
                    let prev: ExternalCallEdge = submission.external_call_edges⁅ei⁆
                    if prev.caller == caller && prev.callee_symbol == callee && prev.string_argument == message {
                        dup = true
                    }
                    ei = ei + 1
                }
                if !dup {
                    submission.external_call_edges = push(submission.external_call_edges, ExternalCallEdge {
                        caller: caller,
                        callee_symbol: callee,
                        string_argument: message
                    })
                }
            }
            # Internal calls: any same-fragment body callee mentioned as name(
            let mut ci: usize = 0
            while ci < submission.body_symbols.length() {
                let callee: utf8 = submission.body_symbols⁅ci⁆
                let short: utf8 = unqualified_symbol(callee)
                if short != item.name && body_contains_call(item.body_source, short) {
                    let mut dup: bool = false
                    let mut ei: usize = 0
                    while ei < submission.internal_call_edges.length() {
                        let prev: InternalCallEdge = submission.internal_call_edges⁅ei⁆
                        if prev.caller == caller && prev.callee_symbol == callee {
                            dup = true
                        }
                        ei = ei + 1
                    }
                    if !dup {
                        submission.internal_call_edges = push(submission.internal_call_edges, InternalCallEdge {
                            caller: caller,
                            callee_symbol: callee
                        })
                    }
                }
                ci = ci + 1
            }
            # Emit blockers: legacy body→MSIL gate; isomorphic path is ExecutableModule→emitter.
            fi = fi + 1
        }
        mi = mi + 1
    }

    return submission
}

micro struct_has_field(st: ParsedStruct, field: utf8) -> bool {
    let mut i: usize = 0
    while i < st.fields.length() {
        if st.fields⁅i⁆.name == field {
            return true
        }
        i = i + 1
    }
    return false
}

micro merge_struct_defs(dst: [ParsedStruct], src: [ParsedStruct]) -> [ParsedStruct] {
    let mut out: [ParsedStruct] = dst
    let mut i: usize = 0
    while i < src.length() {
        let st: ParsedStruct = src⁅i⁆
        let mut exists_at: i32 = -1
        let mut j: usize = 0
        while j < out.length() {
            if out⁅j⁆.name == st.name {
                exists_at = j as i32
            }
            j = j + 1
        }
        if exists_at < 0 && st.name.length() > 0 {
            out = push(out, st)
        }
        else if exists_at >= 0 {
            # Prefer TextSpan { start, stop } (std.data.text.valkyrie) over core { offset, length }.
            let old: ParsedStruct = out⁅exists_at as usize⁆
            if struct_has_field(st, "start") && !struct_has_field(old, "start") {
                let mut rebuilt: [ParsedStruct] = []
                let mut k: usize = 0
                while k < out.length() {
                    if k == exists_at as usize {
                        rebuilt = push(rebuilt, st)
                    }
                    else {
                        rebuilt = push(rebuilt, out⁅k⁆)
                    }
                    k = k + 1
                }
                out = rebuilt
            }
        }
        i = i + 1
    }
    return out
}

micro find_body_source(submission: FragmentSubmission, symbol: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.body_symbols.length() {
        if submission.body_symbols⁅i⁆ == symbol {
            if i < submission.body_sources.length() {
                return submission.body_sources⁅i⁆
            }
            return ""
        }
        i = i + 1
    }
    return ""
}

micro push_unique_op(items: [utf8], value: utf8) -> [utf8] {
    return push_unique_text(items, value)
}

# Only entry + internal-call closure — do not require lowering every dependency export.
micro reachable_operations(submission: FragmentSubmission) -> [utf8] {
    let mut acc: [utf8] = []
    if submission.entry_operation.length() == 0 {
        return acc
    }
    acc = push_unique_op(acc, submission.entry_operation)
    let mut changed: bool = true
    while changed {
        changed = false
        let mut ei: usize = 0
        while ei < submission.internal_call_edges.length() {
            let edge: InternalCallEdge = submission.internal_call_edges⁅ei⁆
            if contains_text(acc, edge.caller) {
                let before: usize = acc.length()
                acc = push_unique_op(acc, edge.callee_symbol)
                if acc.length() != before {
                    changed = true
                }
            }
            ei = ei + 1
        }
    }
    return acc
}

micro collect_body_emit_blockers(submission: FragmentSubmission) -> [utf8] {
    let mut blockers: [utf8] = []
    let reachable: [utf8] = reachable_operations(submission)
    let mut i: usize = 0
    while i < reachable.length() {
        let symbol: utf8 = reachable⁅i⁆
        let binding: ExternalImportBinding = find_external_binding(submission, symbol)
        if binding.symbol.length() > 0 {
            i = i + 1
            continue
        }
        let body: utf8 = find_body_source(submission, symbol)
        let returns_void: bool = operation_is_void(submission, symbol)
        let lowered: BodyLowerResult = lower_function_body_to_msil(body, returns_void, submission)
        if !lowered.ok {
            blockers = push(blockers, symbol + ": " + lowered.error)
        }
        i = i + 1
    }
    return blockers
}

micro build_fragment_from_files(files: [utf8], file_count: usize, project_name: utf8) -> FragmentSubmission {
    # `file_count` must come from the caller — param `.length()` is often 0 on CLR.
    std.io.print_line("[v1-debug] parse_modules file_count=" + format("{}", file_count as i32))
    let modules: [ParsedModule] = parse_modules_from_files(files, file_count)
    let module_count: usize = modules.length()
    std.io.print_line("[v1-debug] module_count=" + format("{}", module_count as i32))
    if module_count > 0 {
        let fn0: i32 = modules⁅0⁆.functions.length() as i32
        std.io.print_line("[v1-debug] module0_fn_count=" + format("{}", fn0))
    }
    let mut submission: FragmentSubmission = build_fragment_from_modules(modules, module_count, project_name)
    let mut fi: usize = 0
    while fi < file_count {
        let path: utf8 = files⁅fi⁆
        if std.io.file_exists(path) {
            let src: utf8 = std.io.read_file_text(path)
            submission.struct_defs = merge_struct_defs(submission.struct_defs, parse_structures_from_source(src))
            submission.unite_defs = merge_unite_defs(submission.unite_defs, parse_unites_from_source(src))
        }
        fi = fi + 1
    }
    submission.struct_defs = filter_emitable_structs(submission.struct_defs)
    submission = ensure_bootstrap_von_types(submission)
    std.io.print_line("[v1-debug] struct_defs=" + format("{}", submission.struct_defs.length() as i32))
    std.io.print_line("[v1-debug] unite_defs=" + format("{}", submission.unite_defs.length() as i32))
    return submission
}

# When kind.v / ast.v scrape misses (GetFiles gaps), seed von unite/struct layout for CLR emit.
# Only when the fragment actually references von — avoid polluting tiny smokes with forward-ref structs.
micro fragment_needs_von_bootstrap(submission: FragmentSubmission) -> bool {
    let mut i: usize = 0
    while i < submission.body_sources.length() {
        let b: utf8 = submission.body_sources⁅i⁆
        if b.contains("VonValue") || b.contains("von_find_field") || b.contains("VonToken") || b.contains("lex_von") || b.contains("parse_von") {
            return true
        }
        i = i + 1
    }
    return false
}

micro ensure_bootstrap_von_types(submission: FragmentSubmission) -> FragmentSubmission {
    let mut s: FragmentSubmission = submission
    if !fragment_needs_von_bootstrap(s) {
        return s
    }
    if find_unite_def(s.unite_defs, "VonValue").name.length() == 0 {
        let mut vs: [ParsedUniteVariant] = []
        vs = push(vs, ParsedUniteVariant { name: "Text", tag: 0, payload_type: "utf8" })
        vs = push(vs, ParsedUniteVariant { name: "Flag", tag: 1, payload_type: "bool" })
        vs = push(vs, ParsedUniteVariant { name: "Number", tag: 2, payload_type: "utf8" })
        vs = push(vs, ParsedUniteVariant { name: "Name", tag: 3, payload_type: "utf8" })
        vs = push(vs, ParsedUniteVariant { name: "Array", tag: 4, payload_type: "[VonValue]" })
        vs = push(vs, ParsedUniteVariant { name: "Object", tag: 5, payload_type: "[VonField]" })
        vs = push(vs, ParsedUniteVariant { name: "Empty", tag: 6, payload_type: "" })
        s.unite_defs = push(s.unite_defs, ParsedUnite { name: "VonValue", variants: vs })
    }
    if find_unite_def(s.unite_defs, "VonTokenKind").name.length() == 0 {
        let mut vs: [ParsedUniteVariant] = []
        vs = push(vs, ParsedUniteVariant { name: "Identifier", tag: 0, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "StringLiteral", tag: 1, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "NumberLiteral", tag: 2, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "BooleanLiteral", tag: 3, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "LeftBrace", tag: 4, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "RightBrace", tag: 5, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "LeftBracket", tag: 6, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "RightBracket", tag: 7, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "Colon", tag: 8, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "Comma", tag: 9, payload_type: "" })
        vs = push(vs, ParsedUniteVariant { name: "EndOfFile", tag: 10, payload_type: "" })
        s.unite_defs = push(s.unite_defs, ParsedUnite { name: "VonTokenKind", variants: vs })
    }
    if find_unite_def(s.unite_defs, "VonParseResult").name.length() == 0 {
        let mut vs: [ParsedUniteVariant] = []
        vs = push(vs, ParsedUniteVariant { name: "Fine", tag: 0, payload_type: "T" })
        vs = push(vs, ParsedUniteVariant { name: "Fail", tag: 1, payload_type: "VonDiagnostic" })
        s.unite_defs = push(s.unite_defs, ParsedUnite { name: "VonParseResult", variants: vs })
    }
    if find_struct_def(s.struct_defs, "VonField").name.length() == 0 {
        let mut fs: [ParsedStructField] = []
        fs = push(fs, ParsedStructField { name: "name", type_text: "utf8" })
        fs = push(fs, ParsedStructField { name: "value", type_text: "VonValue" })
        s.struct_defs = push(s.struct_defs, ParsedStruct { name: "VonField", fields: fs })
    }
    if find_struct_def(s.struct_defs, "VonToken").name.length() == 0 {
        let mut fs: [ParsedStructField] = []
        fs = push(fs, ParsedStructField { name: "kind", type_text: "VonTokenKind" })
        fs = push(fs, ParsedStructField { name: "text", type_text: "utf8" })
        fs = push(fs, ParsedStructField { name: "span", type_text: "TextSpan" })
        fs = push(fs, ParsedStructField { name: "line", type_text: "usize" })
        fs = push(fs, ParsedStructField { name: "column", type_text: "usize" })
        s.struct_defs = push(s.struct_defs, ParsedStruct { name: "VonToken", fields: fs })
    }
    return s
}

micro submission_console_message(submission: FragmentSubmission) -> utf8 {
    if submission.external_call_edges.length() > 0 {
        return submission.external_call_edges⁅0⁆.string_argument
    }
    return "legion.tools smoke"
}

micro submission_assembly_name(submission: FragmentSubmission) -> utf8 {
    return submission.module_name + "__" + submission.fragment_id
}
