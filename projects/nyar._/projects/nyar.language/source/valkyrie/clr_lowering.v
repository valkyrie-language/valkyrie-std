namespace nyar.language.valkyrie;

using std.io;
using nyar.emitter;

structure LoweredClrModule {
    assembly_name: utf8
    msil: utf8
    console_message: utf8
}

micro append_msil_line(buffer: utf8, line: utf8) -> utf8 {
    return buffer + line + "\n"
}

micro dq() -> utf8 {
    return '''"'''
}

micro sanitize_symbol(value: utf8) -> utf8 {
    let mut result: utf8 = ""
    let mut i: i32 = 0
    while i < value.length() {
        let ch: utf8 = value⁅i⁆
        if ch == "." {
            result = result + "__"
        }
        else if ch == ":" || ch == "/" || ch == "\u{5c}" || ch == "'" {
            result = result + "_"
        }
        else {
            result = result + ch
        }
        i = i + 1
    }
    return result
}

# Quote method names for ilasm — bare `filter` / `value` / `class` are IL keywords.
# Avoid `"'" + x + "'"` — CLR body lower mis-parses that quote sandwich as a lone `'"'`.
micro msil_method_name(value: utf8) -> utf8 {
    let name: utf8 = sanitize_symbol(value)
    let mut out: utf8 = "\u{27}"
    out = out + name
    out = out + "\u{27}"
    return out
}

micro empty_external_import_binding() -> ExternalImportBinding {
    return ExternalImportBinding {
        symbol: "",
        link: ExternalImportLink {
            boundary: "",
            platform_tag: "",
            locator_segments: []
        }
    }
}

micro find_external_binding(submission: FragmentSubmission, symbol: utf8) -> ExternalImportBinding {
    let mut i: usize = 0
    while i < submission.external_import_bindings.length() {
        let binding: ExternalImportBinding = submission.external_import_bindings⁅i⁆
        if binding.symbol == symbol {
            return binding
        }
        i = i + 1
    }
    return empty_external_import_binding()
}

micro operation_is_void(submission: FragmentSubmission, symbol: utf8) -> bool {
    return contains_text(submission.void_returns, symbol)
}

micro literal_return_for(submission: FragmentSubmission, symbol: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.literal_returns.length() {
        if submission.literal_returns⁅i⁆ == symbol {
            if i < submission.literal_return_values.length() {
                return submission.literal_return_values⁅i⁆
            }
            return ""
        }
        i = i + 1
    }
    return ""
}

micro integer_return_for(submission: FragmentSubmission, symbol: utf8) -> utf8 {
    let mut i: usize = 0
    while i < submission.integer_returns.length() {
        if submission.integer_returns⁅i⁆ == symbol {
            if i < submission.integer_return_values.length() {
                return submission.integer_return_values⁅i⁆
            }
            return ""
        }
        i = i + 1
    }
    return ""
}

micro append_ldc_i4_digits(msil: utf8, digits: utf8) -> utf8 {
    if digits == "0" {
        return append_msil_line(msil, "        ldc.i4.0")
    }
    if digits == "1" {
        return append_msil_line(msil, "        ldc.i4.1")
    }
    if digits == "2" {
        return append_msil_line(msil, "        ldc.i4.2")
    }
    if digits == "3" {
        return append_msil_line(msil, "        ldc.i4.3")
    }
    if digits == "4" {
        return append_msil_line(msil, "        ldc.i4.4")
    }
    if digits == "5" {
        return append_msil_line(msil, "        ldc.i4.5")
    }
    if digits == "6" {
        return append_msil_line(msil, "        ldc.i4.6")
    }
    if digits == "7" {
        return append_msil_line(msil, "        ldc.i4.7")
    }
    if digits == "8" {
        return append_msil_line(msil, "        ldc.i4.8")
    }
    if digits == "m1" || digits == "-1" {
        return append_msil_line(msil, "        ldc.i4.m1")
    }
    return append_msil_line(msil, "        ldc.i4 " + digits)
}

micro outgoing_external_edges(submission: FragmentSubmission, caller: utf8) -> [ExternalCallEdge] {
    let mut edges: [ExternalCallEdge] = []
    let mut i: usize = 0
    while i < submission.external_call_edges.length() {
        let edge: ExternalCallEdge = submission.external_call_edges⁅i⁆
        if edge.caller == caller {
            edges = push(edges, edge)
        }
        i = i + 1
    }
    return edges
}

micro outgoing_internal_edges(submission: FragmentSubmission, caller: utf8) -> [InternalCallEdge] {
    let mut edges: [InternalCallEdge] = []
    let mut i: usize = 0
    while i < submission.internal_call_edges.length() {
        let edge: InternalCallEdge = submission.internal_call_edges⁅i⁆
        if edge.caller == caller {
            edges = push(edges, edge)
        }
        i = i + 1
    }
    return edges
}

micro collect_local_operations(submission: FragmentSubmission) -> [utf8] {
    let mut operations: [utf8] = []
    let mut i: usize = 0
    while i < submission.exported_operations.length() {
        operations = push_unique_text(operations, submission.exported_operations⁅i⁆)
        i = i + 1
    }
    i = 0
    while i < submission.internal_call_edges.length() {
        let edge: InternalCallEdge = submission.internal_call_edges⁅i⁆
        operations = push_unique_text(operations, edge.caller)
        operations = push_unique_text(operations, edge.callee_symbol)
        i = i + 1
    }
    i = 0
    while i < submission.external_call_edges.length() {
        let edge: ExternalCallEdge = submission.external_call_edges⁅i⁆
        operations = push_unique_text(operations, edge.caller)
        i = i + 1
    }
    i = 0
    while i < submission.literal_returns.length() {
        operations = push_unique_text(operations, submission.literal_returns⁅i⁆)
        i = i + 1
    }
    if submission.entry_operation.length() > 0 {
        operations = push_unique_text(operations, submission.entry_operation)
    }
    return operations
}

micro clr_method_ref(binding: ExternalImportBinding) -> utf8 {
    let assembly: utf8 = binding.link.locator_segments⁅0⁆
    let owner: utf8 = binding.link.locator_segments⁅1⁆
    let method_name: utf8 = binding.link.locator_segments⁅2⁆
    return "call void [" + assembly + "]" + owner + "::" + method_name + "(string)"
}

micro operation_return_msil_type(submission: FragmentSubmission, operation: utf8) -> utf8 {
    if operation_is_void(submission, operation) {
        return "void"
    }
    let body: utf8 = find_body_source(submission, operation)
    if body.length() > 0 {
        return parse_return_clr_type(body, false, submission.struct_defs)
    }
    let literal: utf8 = literal_return_for(submission, operation)
    if literal.length() > 0 {
        return "string"
    }
    return "int32"
}

micro append_operation_method(msil: utf8, submission: FragmentSubmission, operation: utf8) -> utf8 {
    # Use a mut local — reassigning the `msil` parameter is dropped by CLR body lower (ret ldarg.0).
    let mut acc: utf8 = msil
    let method_name: utf8 = msil_method_name(operation)
    let binding: ExternalImportBinding = find_external_binding(submission, operation)
    let returns_void: bool = operation_is_void(submission, operation) || binding.symbol.length() > 0
    let body: utf8 = find_body_source(submission, operation)
    let params: [BodyLocal] = parse_function_params(body, submission.struct_defs)
    let param_sig: utf8 = msil_param_signature(params)
    let return_type: utf8 = if returns_void { "void" } else { operation_return_msil_type(submission, operation) }
    acc = append_msil_line(acc, ".method public hidebysig static " + return_type + " " + method_name + "(" + param_sig + ") cil managed")
    acc = append_msil_line(acc, "{")

    # CLR host imports: call sites emit BCL calls directly; MethodDef is a void ret placeholder.
    if binding.symbol.length() > 0 {
        acc = append_msil_line(acc, "    .maxstack 8")
        acc = append_msil_line(acc, "        ret")
        acc = append_msil_line(acc, "}")
        acc = append_msil_line(acc, "")
        return acc
    }

    # Preferred: ExecutableModule → nyar.emitter.clr (frontend_facts / adapt_mir_module_to_executable).
    # LEGACY BYPASS only: body_source → MSIL via clr_body_lowering (do not expand).
    if body.length() > 0 {
        if body_source_bypass_retired() {
            acc = append_msil_line(acc, "    .maxstack 8")
            acc = append_msil_line(acc, "        ldstr " + dq() + body_source_bypass_retired_error() + dq())
            acc = append_msil_line(acc, "        call void [System.Console]System.Console::WriteLine(string)")
            acc = append_msil_line(acc, "        ldc.i4.1")
            acc = append_msil_line(acc, "        call void [System.Runtime]System.Environment::Exit(int32)")
            acc = append_msil_line(acc, "        ret")
            acc = append_msil_line(acc, "}")
            acc = append_msil_line(acc, "")
            return acc
        }
        let lowered: BodyLowerResult = lower_function_body_to_msil(body, returns_void, submission)
        if lowered.ok {
            acc = append_msil_line(acc, "    .maxstack 16")
            if lowered.locals_clause.length() > 0 {
                acc = append_msil_line(acc, lowered.locals_clause)
            }
            acc = acc + lowered.instructions
            if !lowered.instructions.contains("ret") {
                acc = append_msil_line(acc, "        ret")
            }
            acc = append_msil_line(acc, "}")
            acc = append_msil_line(acc, "")
            return acc
        }
    }

    # No silent empty stub — body gate should have failed already.
    acc = append_msil_line(acc, "    .maxstack 8")
    acc = append_msil_line(acc, "        ldstr " + dq() + "internal: missing body lower for " + operation + dq())
    acc = append_msil_line(acc, "        call void [System.Console]System.Console::WriteLine(string)")
    if !returns_void {
        acc = append_msil_line(acc, "        ldc.i4.1")
    }
    acc = append_msil_line(acc, "        ret")
    acc = append_msil_line(acc, "}")
    acc = append_msil_line(acc, "")
    return acc
}

micro lower_fragment_via_executable_module(submission: FragmentSubmission) -> LoweredClrModule {
    let emit: EmitterResult = emit_clr_from_fragment_submission(submission)
    let assembly_name: utf8 = submission_assembly_name(submission)
    if !emit.ok {
        return LoweredClrModule {
            assembly_name: assembly_name,
            msil: "",
            console_message: emit.error
        }
    }
    let mut msil: utf8 = ""
    msil = append_msil_line(msil, ".assembly extern mscorlib {}")
    msil = append_msil_line(msil, ".assembly extern System.Console {}")
    msil = append_msil_line(msil, ".assembly extern System.Runtime {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".assembly " + assembly_name + " {}")
    msil = append_msil_line(msil, "")
    msil = msil + emit.msil_text
    return LoweredClrModule {
        assembly_name: assembly_name,
        msil: msil,
        console_message: submission_console_message(submission)
    }
}

micro lower_fragment_to_clr(submission: FragmentSubmission) -> LoweredClrModule {
    let assembly_name: utf8 = submission_assembly_name(submission)
    # No template-copy shortcut for legion — caller must fail-closed before this.

    let mut msil: utf8 = ""
    msil = append_msil_line(msil, ".assembly extern mscorlib {}")
    msil = append_msil_line(msil, ".assembly extern System.Console {}")
    msil = append_msil_line(msil, ".assembly extern System.IO.FileSystem {}")
    msil = append_msil_line(msil, ".assembly extern System.Runtime {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".assembly " + assembly_name + " {}")
    msil = append_msil_line(msil, "")
    # Unites before structs — structs may reference VonValue / VonTokenKind fields.
    msil = msil + emit_unite_classes(submission.unite_defs)
    msil = msil + emit_struct_classes(submission.struct_defs)

    # Emit only entry call-closure (plus CLR import MethodDefs referenced by bodies).
    let operations: [utf8] = reachable_operations(submission)
    let mut oi: usize = 0
    let op_count: usize = operations.length()
    while oi < op_count {
        msil = append_operation_method(msil, submission, operations⁅oi⁆)
        oi = oi + 1
    }
    # Ensure CLR import symbols used by external edges still have MethodDefs if referenced.
    let mut ei: usize = 0
    while ei < submission.external_import_bindings.length() {
        let binding: ExternalImportBinding = submission.external_import_bindings⁅ei⁆
        if !contains_text(operations, binding.symbol) {
            # Import MethodDefs are optional when bodies call BCL directly.
        }
        ei = ei + 1
    }

    let entry: utf8 = submission.entry_operation
    if entry.length() > 0 && !contains_text(operations, entry) {
        msil = append_operation_method(msil, submission, entry)
    }

    let entry_body: utf8 = find_body_source(submission, entry)
    let entry_params: [BodyLocal] = parse_function_params(entry_body, submission.struct_defs)
    let entry_return_void: bool = operation_is_void(submission, entry)
    let entry_return_type: utf8 = if entry_return_void { "void" } else { operation_return_msil_type(submission, entry) }
    let entry_call_type: utf8 = entry_return_type
    let entry_wrapper: utf8 = msil_method_name("entry_" + sanitize_symbol(entry))
    let entry_callee: utf8 = msil_method_name(entry)
    let entry_ptypes: utf8 = msil_param_types(entry_params)

    if entry_params.length() == 1 && entry_params⁅0⁆.clr_type == "string[]" {
        msil = append_msil_line(msil, ".method public hidebysig static " + entry_return_type + " " + entry_wrapper + "(string[] args) cil managed")
        msil = append_msil_line(msil, "{")
        msil = append_msil_line(msil, "    .entrypoint")
        msil = append_msil_line(msil, "    .maxstack 8")
        msil = append_msil_line(msil, "        ldarg.0")
        msil = append_msil_line(msil, "        call " + entry_call_type + " " + entry_callee + "(string[])")
        msil = append_msil_line(msil, "        ret")
        msil = append_msil_line(msil, "}")
    }
    else if entry_params.length() == 1 && entry_params⁅0⁆.clr_type.starts_with("class ") {
        let st_name: utf8 = entry_params⁅0⁆.clr_type.slice(6, entry_params⁅0⁆.clr_type.length() - 6).trim()
        let def_new: BodyLowerResult = emit_default_struct_new(st_name, submission.struct_defs)
        msil = append_msil_line(msil, ".method public hidebysig static " + entry_return_type + " " + entry_wrapper + "() cil managed")
        msil = append_msil_line(msil, "{")
        msil = append_msil_line(msil, "    .entrypoint")
        msil = append_msil_line(msil, "    .maxstack 16")
        if def_new.ok {
            msil = msil + def_new.instructions
            msil = append_msil_line(msil, "        call " + entry_call_type + " " + entry_callee + "(" + entry_ptypes + ")")
        }
        else {
            msil = append_msil_line(msil, "        ldstr " + dq() + "entry default struct failed: " + def_new.error + dq())
            msil = append_msil_line(msil, "        call void [System.Console]System.Console::WriteLine(string)")
            if !entry_return_void {
                msil = append_msil_line(msil, "        ldc.i4.1")
            }
        }
        msil = append_msil_line(msil, "        ret")
        msil = append_msil_line(msil, "}")
    }
    else {
        msil = append_msil_line(msil, ".method public hidebysig static " + entry_return_type + " " + entry_wrapper + "() cil managed")
        msil = append_msil_line(msil, "{")
        msil = append_msil_line(msil, "    .entrypoint")
        msil = append_msil_line(msil, "    .maxstack 8")
        msil = append_msil_line(msil, "        call " + entry_call_type + " " + entry_callee + "(" + entry_ptypes + ")")
        msil = append_msil_line(msil, "        ret")
        msil = append_msil_line(msil, "}")
    }

    return LoweredClrModule {
        assembly_name: assembly_name,
        msil: msil,
        console_message: submission_console_message(submission)
    }
}
