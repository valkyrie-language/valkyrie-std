namespace nyar.language.valkyrie;

micro push_unique_text(items: [utf8], value: utf8) -> unit {
    loop existing in items {
        if existing == value {
            return
        }
    }
    push(items, value)
}

micro contains_text(items: [utf8], value: utf8) -> bool {
    loop item in items {
        if item == value {
            return true
        }
    }
    return false
}

micro build_fragment_from_modules(modules: [ParsedModule], project_name: utf8) -> FragmentSubmission {
    let mut submission: FragmentSubmission = empty_fragment_submission()
    submission.fragment_id = "functions"
    if modules.length() == 0 {
        return submission
    }

    let primary: ParsedModule = modules[0]
    submission.module_name = namespace_to_symbol(primary.namespace_name)
    if submission.module_name.length() == 0 {
        submission.module_name = project_name
    }

    loop parsed in modules {
        loop item in parsed.functions {
            let symbol: utf8 = qualified_symbol(parsed.namespace_name, item.name)
            push_unique_text(submission.exported_operations, symbol)
            if item.is_clr_extern {
                push(submission.external_import_bindings, ExternalImportBinding {
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
                if item.return_is_unit {
                    push_unique_text(submission.void_returns, symbol)
                }
            }
            if item.is_main {
                submission.entry_operation = symbol
            }
            let literal: Option<utf8> = body_contains_return_literal(item.body_source)
            if literal.is_some() {
                push_unique_text(submission.literal_returns, symbol)
                push(submission.literal_return_values, literal.unwrap())
            }
        }
    }

    loop parsed in modules {
        loop item in parsed.functions {
            if item.is_clr_extern {
                continue
            }
            let caller: utf8 = qualified_symbol(parsed.namespace_name, item.name)
            let message: Option<utf8> = find_call_literal(item.body_source, "console_write_line")
            if message.is_some() {
                push(submission.external_call_edges, ExternalCallEdge {
                    caller: caller,
                    callee_symbol: qualified_symbol(parsed.namespace_name, "console_write_line"),
                    string_argument: message.unwrap()
                })
            }
            if body_contains_call(item.body_source, "helper_label") {
                push(submission.internal_call_edges, InternalCallEdge {
                    caller: caller,
                    callee_symbol: qualified_symbol(parsed.namespace_name, "helper_label")
                })
            }
            if body_contains_call(item.body_source, "version_text") {
                push(submission.internal_call_edges, InternalCallEdge {
                    caller: caller,
                    callee_symbol: qualified_symbol(parsed.namespace_name, "version_text")
                })
            }
        }
    }

    return submission
}

micro build_fragment_from_files(files: [utf8], project_name: utf8) -> FragmentSubmission {
    let modules: [ParsedModule] = parse_modules_from_files(files)
    return build_fragment_from_modules(modules, project_name)
}

micro submission_console_message(submission: FragmentSubmission) -> utf8 {
    if submission.external_call_edges.length() > 0 {
        return submission.external_call_edges[0].string_argument
    }
    return "legion.tools smoke"
}

micro submission_assembly_name(submission: FragmentSubmission) -> utf8 {
    return submission.module_name + "__" + submission.fragment_id
}
