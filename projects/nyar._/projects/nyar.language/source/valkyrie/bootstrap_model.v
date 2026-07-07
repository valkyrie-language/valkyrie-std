namespace nyar.language.valkyrie;

structure BootstrapSpan {
    start: i32
    stop: i32
    line: i32
    column: i32
}

structure BootstrapDiagnostic {
    path: utf8
    message: utf8
    span: BootstrapSpan
}

structure BootstrapToken {
    kind: utf8
    text: utf8
    span: BootstrapSpan
}

structure BootstrapLexResult {
    ok: bool
    tokens: [BootstrapToken]
    diagnostics: [BootstrapDiagnostic]
}

structure BootstrapPreprocessResult {
    ok: bool
    source: utf8
    diagnostics: [BootstrapDiagnostic]
}

structure BootstrapAttribute {
    name: utf8
    arguments: [utf8]
    span: BootstrapSpan
}

structure BootstrapParameter {
    name: utf8
    type_text: utf8
    is_mutable: bool
    is_self: bool
    default_text: utf8
    span: BootstrapSpan
}

structure BootstrapField {
    name: utf8
    type_text: utf8
    is_mutable: bool
    attributes: [BootstrapAttribute]
    span: BootstrapSpan
}

# Expressions and statements use indexes rather than recursive values. This
# keeps the bootstrap IR deterministic and simple for every managed backend.
structure BootstrapExpression {
    kind: utf8
    text: utf8
    operation: utf8
    left: i32
    right: i32
    items: [i32]
    names: [utf8]
    span: BootstrapSpan
}

structure BootstrapMatchArm {
    pattern_text: utf8
    guard_expression: i32
    body: [i32]
    span: BootstrapSpan
}

structure BootstrapStatement {
    kind: utf8
    name: utf8
    type_text: utf8
    is_mutable: bool
    expression: i32
    secondary_expression: i32
    body: [i32]
    else_body: [i32]
    match_arms: [BootstrapMatchArm]
    span: BootstrapSpan
}

structure BootstrapFunction {
    namespace_name: utf8
    owner_name: utf8
    name: utf8
    generic_parameters: [utf8]
    parameters: [BootstrapParameter]
    return_type: utf8
    attributes: [BootstrapAttribute]
    expressions: [BootstrapExpression]
    statements: [BootstrapStatement]
    body: [i32]
    is_extern: bool
    span: BootstrapSpan
}

structure BootstrapVariant {
    name: utf8
    fields: [BootstrapField]
    attributes: [BootstrapAttribute]
    span: BootstrapSpan
}

structure BootstrapDeclaration {
    kind: utf8
    namespace_name: utf8
    name: utf8
    generic_parameters: [utf8]
    base_types: [utf8]
    attributes: [BootstrapAttribute]
    fields: [BootstrapField]
    variants: [BootstrapVariant]
    functions: [BootstrapFunction]
    span: BootstrapSpan
}

structure BootstrapModule {
    path: utf8
    namespace_name: utf8
    imports: [utf8]
    declarations: [BootstrapDeclaration]
    functions: [BootstrapFunction]
    diagnostics: [BootstrapDiagnostic]
}

structure BootstrapClosure {
    ok: bool
    modules: [BootstrapModule]
    diagnostics: [BootstrapDiagnostic]
    source_file_count: i32
    declaration_count: i32
    function_count: i32
}

structure BootstrapParseContext {
    path: utf8
    tokens: [BootstrapToken]
    index: i32
    expressions: [BootstrapExpression]
    statements: [BootstrapStatement]
    diagnostics: [BootstrapDiagnostic]
}

structure BootstrapMirValue {
    kind: utf8
    type_text: utf8
    text: utf8
    source_expression: i32
}

structure BootstrapMirInstruction {
    operation: utf8
    result: i32
    operands: [i32]
    text_operands: [utf8]
    target_blocks: [i32]
    span: BootstrapSpan
}

structure BootstrapMirBlock {
    id: i32
    instructions: [BootstrapMirInstruction]
    predecessors: [i32]
    sealed: bool
}

structure BootstrapMirFunction {
    symbol: utf8
    return_type: utf8
    parameter_types: [utf8]
    values: [BootstrapMirValue]
    blocks: [BootstrapMirBlock]
    entry_block: i32
    attributes: [BootstrapAttribute]
}

structure BootstrapMirModule {
    target: utf8
    functions: [BootstrapMirFunction]
    entry_symbol: utf8
    diagnostics: [BootstrapDiagnostic]
}

micro bootstrap_empty_span() -> BootstrapSpan {
    return BootstrapSpan {
        start: 0,
        stop: 0,
        line: 1,
        column: 1
    }
}

micro bootstrap_span(start: i32, stop: i32, line: i32, column: i32) -> BootstrapSpan {
    return BootstrapSpan {
        start: start,
        stop: stop,
        line: line,
        column: column
    }
}

micro bootstrap_diagnostic(path: utf8, message: utf8, span: BootstrapSpan) -> BootstrapDiagnostic {
    return BootstrapDiagnostic {
        path: path,
        message: message,
        span: span
    }
}

micro bootstrap_empty_expression() -> BootstrapExpression {
    return BootstrapExpression {
        kind: "missing",
        text: "",
        operation: "",
        left: -1,
        right: -1,
        items: [],
        names: [],
        span: bootstrap_empty_span()
    }
}

micro bootstrap_empty_statement() -> BootstrapStatement {
    return BootstrapStatement {
        kind: "missing",
        name: "",
        type_text: "",
        is_mutable: false,
        expression: -1,
        secondary_expression: -1,
        body: [],
        else_body: [],
        match_arms: [],
        span: bootstrap_empty_span()
    }
}

micro bootstrap_empty_function() -> BootstrapFunction {
    return BootstrapFunction {
        namespace_name: "",
        owner_name: "",
        name: "",
        generic_parameters: [],
        parameters: [],
        return_type: "unit",
        attributes: [],
        expressions: [],
        statements: [],
        body: [],
        is_extern: false,
        span: bootstrap_empty_span()
    }
}

micro bootstrap_empty_module(path: utf8) -> BootstrapModule {
    return BootstrapModule {
        path: path,
        namespace_name: "",
        imports: [],
        declarations: [],
        functions: [],
        diagnostics: []
    }
}

micro bootstrap_new_parse_context(path: utf8, tokens: [BootstrapToken]) -> BootstrapParseContext {
    return BootstrapParseContext {
        path: path,
        tokens: tokens,
        index: 0,
        expressions: [],
        statements: [],
        diagnostics: []
    }
}
