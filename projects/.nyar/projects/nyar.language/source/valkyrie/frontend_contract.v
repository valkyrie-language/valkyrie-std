namespace nyar.language.valkyrie;

structure ExternalImportLink {
    boundary: utf8
    platform_tag: utf8
    locator_segments: [utf8]
}

structure ExternalImportBinding {
    symbol: utf8
    link: ExternalImportLink
}

structure ExternalCallEdge {
    caller: utf8
    callee_symbol: utf8
    string_argument: utf8
}

structure InternalCallEdge {
    caller: utf8
    callee_symbol: utf8
}

structure FragmentSubmission {
    module_name: utf8
    fragment_id: utf8
    exported_operations: [utf8]
    entry_operation: utf8
    external_import_bindings: [ExternalImportBinding]
    external_call_edges: [ExternalCallEdge]
    internal_call_edges: [InternalCallEdge]
    literal_returns: [utf8]
    literal_return_values: [utf8]
    void_returns: [utf8]
}

structure CompileOutput {
    assembly_name: utf8
    namespace_symbol: utf8
    console_message: utf8
    source_files: [utf8]
}

structure CompileResult {
    ok: bool
    error: utf8
    output: CompileOutput
}

micro empty_compile_output() -> CompileOutput {
    return CompileOutput {
        assembly_name: "",
        namespace_symbol: "",
        console_message: "",
        source_files: []
    }
}

micro empty_fragment_submission() -> FragmentSubmission {
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
        void_returns: []
    }
}
