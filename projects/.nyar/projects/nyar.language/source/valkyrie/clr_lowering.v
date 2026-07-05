namespace nyar.language.valkyrie;

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
        let ch: utf8 = value[i]
        if ch == "." {
            result = result + "__"
        }
        else if ch == ":" || ch == "/" || ch == "\u{5c}" {
            result = result + "_"
        }
        else {
            result = result + ch
        }
        i = i + 1
    }
    return result
}

micro find_external_binding(submission: FragmentSubmission, symbol: utf8) -> Option<ExternalImportBinding> {
    loop binding in submission.external_import_bindings {
        if binding.symbol == symbol {
            return Some(binding)
        }
    }
    return None
}

micro operation_is_void(submission: FragmentSubmission, symbol: utf8) -> bool {
    return contains_text(submission.void_returns, symbol)
}

micro literal_return_for(submission: FragmentSubmission, symbol: utf8) -> Option<utf8> {
    let mut i: usize = 0
    while i < submission.literal_returns.length() {
        if submission.literal_returns[i] == symbol {
            if i < submission.literal_return_values.length() {
                return Some(submission.literal_return_values[i])
            }
            return Some("")
        }
        i = i + 1
    }
    return None
}

micro outgoing_external_edges(submission: FragmentSubmission, caller: utf8) -> [ExternalCallEdge] {
    let mut edges: [ExternalCallEdge] = []
    loop edge in submission.external_call_edges {
        if edge.caller == caller {
            push(edges, edge)
        }
    }
    return edges
}

micro outgoing_internal_edges(submission: FragmentSubmission, caller: utf8) -> [InternalCallEdge] {
    let mut edges: [InternalCallEdge] = []
    loop edge in submission.internal_call_edges {
        if edge.caller == caller {
            push(edges, edge)
        }
    }
    return edges
}

micro collect_local_operations(submission: FragmentSubmission) -> [utf8] {
    let mut operations: [utf8] = []
    loop symbol in submission.exported_operations {
        push_unique_text(operations, symbol)
    }
    loop edge in submission.internal_call_edges {
        push_unique_text(operations, edge.caller)
        push_unique_text(operations, edge.callee_symbol)
    }
    loop edge in submission.external_call_edges {
        push_unique_text(operations, edge.caller)
    }
    loop symbol in submission.literal_returns {
        push_unique_text(operations, symbol)
    }
    if submission.entry_operation.length() > 0 {
        push_unique_text(operations, submission.entry_operation)
    }
    return operations
}

micro clr_method_ref(binding: ExternalImportBinding) -> utf8 {
    let assembly: utf8 = binding.link.locator_segments[0]
    let owner: utf8 = binding.link.locator_segments[1]
    let method_name: utf8 = binding.link.locator_segments[2]
    return "call void [" + assembly + "]" + owner + "::" + method_name + "(string)"
}

micro append_operation_method(msil: utf8, submission: FragmentSubmission, operation: utf8) -> utf8 {
    let method_name: utf8 = sanitize_symbol(operation)
    let returns_void: bool = operation_is_void(submission, operation)
    let return_type: utf8 = if returns_void { "void" } else { "int32" }
    msil = append_msil_line(msil, ".method public hidebysig static " + return_type + " " + method_name + "() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .maxstack 8")

    loop edge in outgoing_external_edges(submission, operation) {
        msil = append_msil_line(msil, "        ldstr " + dq() + edge.string_argument + dq())
        let binding: Option<ExternalImportBinding> = find_external_binding(submission, edge.callee_symbol)
        if binding.is_some() {
            msil = append_msil_line(msil, "        " + clr_method_ref(binding.unwrap()))
        }
    }

    loop edge in outgoing_internal_edges(submission, operation) {
        let callee_void: bool = operation_is_void(submission, edge.callee_symbol)
        let callee_return: utf8 = if callee_void { "void" } else { "int32" }
        msil = append_msil_line(msil, "        call " + callee_return + " " + sanitize_symbol(edge.callee_symbol) + "()")
        if !callee_void {
            msil = append_msil_line(msil, "        pop")
        }
    }

    let literal: Option<utf8> = literal_return_for(submission, operation)
    if literal.is_some() {
        msil = append_msil_line(msil, "        ldstr " + dq() + literal.unwrap() + dq())
    }
    else {
            if !returns_void {
                msil = append_msil_line(msil, "        ldc.i4.0")
            }
    }
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")
    msil = append_msil_line(msil, "")
    return msil
}

micro lower_fragment_to_clr(submission: FragmentSubmission) -> LoweredClrModule {
    let assembly_name: utf8 = submission_assembly_name(submission)
    let mut msil: utf8 = ""
    msil = append_msil_line(msil, ".assembly extern mscorlib {}")
    msil = append_msil_line(msil, ".assembly extern System.Console {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".assembly " + assembly_name + " {}")
    msil = append_msil_line(msil, "")

    let operations: [utf8] = collect_local_operations(submission)
    loop operation in operations {
        msil = append_operation_method(msil, submission, operation)
    }

    let entry_return_void: bool = operation_is_void(submission, submission.entry_operation)
    let entry_return_type: utf8 = if entry_return_void { "void" } else { "int32" }
    let entry_call_type: utf8 = if entry_return_void { "void" } else { "int32" }
    msil = append_msil_line(msil, ".method public hidebysig static " + entry_return_type + " entry_" + sanitize_symbol(submission.entry_operation) + "() cil managed")
    msil = append_msil_line(msil, "{")
    msil = append_msil_line(msil, "    .entrypoint")
    msil = append_msil_line(msil, "    .maxstack 8")
    msil = append_msil_line(msil, "        call " + entry_call_type + " " + sanitize_symbol(submission.entry_operation) + "()")
    msil = append_msil_line(msil, "        ret")
    msil = append_msil_line(msil, "}")

    return LoweredClrModule {
        assembly_name: assembly_name,
        msil: msil,
        console_message: submission_console_message(submission)
    }
}
