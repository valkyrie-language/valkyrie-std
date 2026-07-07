namespace nyar.language.valkyrie.hir;

using std.data.text.valkyrie;

# Isomorphic shell of Rust `nyar-language::valkyrie::types::hir`.

structure HirDocumentation {
    text: utf8
}

structure HirImportBinding {
    name: utf8
    alias: utf8
}

structure HirImport {
    path: utf8
    alias: utf8
    bindings: [HirImportBinding]
    glob: bool
}

structure HirParam {
    name: utf8
    ty: utf8
}

unite HirExprKind {
    Unit
    IntegerLiteral { text: utf8 }
    FloatLiteral { text: utf8 }
    StringLiteral { text: utf8 }
    BoolLiteral { value: bool }
    NullLiteral
    Name { path: utf8 }
    Call { callee: utf8, arguments: [utf8] }
    Field { object: utf8, field: utf8 }
    Binary { op: utf8, left: utf8, right: utf8 }
    Unary { op: utf8, operand: utf8 }
}

structure HirExpr {
    kind: HirExprKind
}

unite HirStatementKind {
    Let {
        is_mutable: bool
        name: utf8
        ty: utf8
        has_init: bool
        init: HirExpr
    }
    Expr { expr: HirExpr }
    Return { has_value: bool, value: HirExpr }
    If {
        condition: HirExpr
        then_body: HirBlock
        has_else: bool
        else_body: HirBlock
    }
    Break
    Continue
}

structure HirStatement {
    kind: HirStatementKind
}

structure HirBlock {
    statements: [HirStatement]
    has_tail: bool
    tail: HirExpr
}

structure HirFunction {
    name: utf8
    declaring_namespace: utf8
    doc: HirDocumentation
    params: [HirParam]
    return_type: utf8
    body: HirBlock
    is_abstract: bool
    is_final: bool
}

structure HirStruct {
    name: utf8
    namespace_name: utf8
    fields: [HirParam]
    is_value_type: bool
}

structure HirModule {
    name: utf8
    doc: HirDocumentation
    imports: [HirImport]
    functions: [HirFunction]
    structs: [HirStruct]
    namespace_name: utf8
}

micro empty_hir_expr() -> HirExpr {
    return HirExpr { kind: Unit }
}

micro empty_hir_block() -> HirBlock {
    return HirBlock {
        statements: [],
        has_tail: false,
        tail: empty_hir_expr()
    }
}

micro empty_hir_module() -> HirModule {
    return HirModule {
        name: "",
        doc: HirDocumentation { text: "" },
        imports: [],
        functions: [],
        structs: [],
        namespace_name: ""
    }
}

micro hir_param_from_text(piece: utf8) -> HirParam {
    let colon: i32 = piece.index_of(":")
    if colon > 0 {
        return HirParam {
            name: piece.slice(0, colon).trim(),
            ty: piece.slice(colon + 1, piece.length() - colon - 1).trim()
        }
    }
    return HirParam {
        name: piece.trim(),
        ty: ""
    }
}

micro hir_binary_op_text(op: BinaryOperator) -> utf8 {
    match op {
        case And: { return "&&" }
        case Or: { return "||" }
        case Add: { return "+" }
        case Sub: { return "-" }
        case Mul: { return "*" }
        case Div: { return "/" }
        case Rem: { return "%" }
        case Eq: { return "==" }
        case Ne: { return "!=" }
        case Lt: { return "<" }
        case Le: { return "<=" }
        case Gt: { return ">" }
        case Ge: { return ">=" }
    }
}

micro hir_unary_op_text(op: UnaryOperator) -> utf8 {
    match op {
        case Neg: { return "-" }
        case Not: { return "!" }
    }
}

micro hir_expr_from_term(term: TermExpression) -> HirExpr {
    match term {
        case Literal { lit }: {
            match lit {
                case Integer { text }: {
                    return HirExpr { kind: IntegerLiteral { text: text } }
                }
                case Float { text }: {
                    return HirExpr { kind: FloatLiteral { text: text } }
                }
                case String { text }: {
                    return HirExpr { kind: StringLiteral { text: text } }
                }
                case Bool { value }: {
                    return HirExpr { kind: BoolLiteral { value: value } }
                }
                case Unit: {
                    return HirExpr { kind: Unit }
                }
                case Null: {
                    return HirExpr { kind: NullLiteral }
                }
            }
        }
        case Name { path }: {
            return HirExpr { kind: Name { path: path } }
        }
        case Call { callee, arguments }: {
            return HirExpr { kind: Call { callee: callee, arguments: arguments } }
        }
        case Field { object, field }: {
            return HirExpr { kind: Field { object: object, field: field } }
        }
        case Binary { op, left, right }: {
            return HirExpr { kind: Binary { op: hir_binary_op_text(op), left: left, right: right } }
        }
        case Unary { op, operand }: {
            return HirExpr { kind: Unary { op: hir_unary_op_text(op), operand: operand } }
        }
        case Unit: {
            return HirExpr { kind: Unit }
        }
    }
}

micro hir_statements_from_ast_list(stmts: [FunctionStatement]) -> [HirStatement] {
    let mut out: [HirStatement] = []
    let mut i: usize = 0
    while i < stmts.length() {
        out = push(out, hir_statement_from_ast(stmts⁅i⁆))
        i = i + 1
    }
    return out
}

micro hir_block_from_statement_list(stmts: [FunctionStatement]) -> HirBlock {
    return HirBlock {
        statements: hir_statements_from_ast_list(stmts),
        has_tail: false,
        tail: empty_hir_expr()
    }
}

micro hir_statement_from_ast(stmt: FunctionStatement) -> HirStatement {
    match stmt {
        case Let { stmt }: {
            let mut init: HirExpr = empty_hir_expr()
            if stmt.has_init {
                init = hir_expr_from_term(stmt.initializer)
            }
            return HirStatement {
                kind: Let {
                    is_mutable: stmt.is_mutable,
                    name: stmt.name,
                    ty: stmt.ty,
                    has_init: stmt.has_init,
                    init: init
                }
            }
        }
        case Term { expression, span }: {
            return HirStatement {
                kind: Expr { expr: hir_expr_from_term(expression) }
            }
        }
        case Return { has_value, value, span }: {
            let mut v: HirExpr = empty_hir_expr()
            if has_value {
                v = hir_expr_from_term(value)
            }
            return HirStatement {
                kind: Return { has_value: has_value, value: v }
            }
        }
        case If { stmt }: {
            return HirStatement {
                kind: If {
                    condition: hir_expr_from_term(stmt.condition),
                    then_body: hir_block_from_statement_list(stmt.then_statements),
                    has_else: stmt.has_else,
                    else_body: hir_block_from_statement_list(stmt.else_statements)
                }
            }
        }
        case Break { span }: {
            return HirStatement { kind: Break }
        }
        case Continue { span }: {
            return HirStatement { kind: Continue }
        }
    }
}

micro hir_block_from_ast(body: DeclarationBody) -> HirBlock {
    let mut out: HirBlock = HirBlock {
        statements: hir_statements_from_ast_list(body.statements),
        has_tail: body.has_tail,
        tail: empty_hir_expr()
    }
    if body.has_tail {
        out.tail = hir_expr_from_term(body.tail_expression)
    }
    return out
}

micro hir_function_from_ast(decl: FunctionDeclaration, ns: utf8) -> HirFunction {
    let mut params: [HirParam] = []
    let mut pi: usize = 0
    while pi < decl.parameters.length() {
        params = push(params, hir_param_from_text(decl.parameters⁅pi⁆))
        pi = pi + 1
    }
    let mut body: HirBlock = empty_hir_block()
    if decl.body_present {
        body = hir_block_from_ast(decl.body)
    }
    return HirFunction {
        name: decl.name.name,
        declaring_namespace: ns,
        doc: HirDocumentation { text: "" },
        params: params,
        return_type: decl.return_type,
        body: body,
        is_abstract: !decl.body_present,
        is_final: false
    }
}

# AST → HIR (decls + body statements / flat terms).
micro hir_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> HirModule {
    let mut module: HirModule = empty_hir_module()
    module.name = module_name
    let mut ns: utf8 = ""
    let mut i: usize = 0
    while i < root.statements.length() {
        let stmt: RootStatement = root.statements⁅i⁆
        match stmt {
            case Namespace { decl }: {
                ns = decl.path
                module.namespace_name = decl.path
            }
            case Using { stmt }: {
                module.imports = push(module.imports, HirImport {
                    path: stmt.path,
                    alias: "",
                    bindings: [],
                    glob: false
                })
            }
            case Function { decl }: {
                module.functions = push(module.functions, hir_function_from_ast(decl, ns))
            }
            case Class { decl }: {
                module.structs = push(module.structs, HirStruct {
                    name: decl.name.name,
                    namespace_name: ns,
                    fields: [],
                    is_value_type: false
                })
            }
            case Unite { decl }: {
                module.structs = push(module.structs, HirStruct {
                    name: decl.name.name,
                    namespace_name: ns,
                    fields: [],
                    is_value_type: false
                })
            }
            else: {
            }
        }
        i = i + 1
    }
    return module
}
