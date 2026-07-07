namespace std.data.text.valkyrie;

# Body / term shell — isomorphic to Rust `ast::{FunctionStatement, DeclarationBody, LiteralExpression, IfStatement}`
# and a flat `TermExpression` (full term tree lands incrementally).

unite LiteralExpression {
    Integer { text: utf8 }
    Float { text: utf8 }
    String { text: utf8 }
    Bool { value: bool }
    Unit
    Null
}

unite UnaryOperator {
    Neg
    Not
}

unite BinaryOperator {
    And
    Or
    Add
    Sub
    Mul
    Div
    Rem
    Eq
    Ne
    Lt
    Le
    Gt
    Ge
}

# Flat term shell (no recursive Box) for CLR bootstrap.
unite TermExpression {
    Literal { lit: LiteralExpression }
    Name { path: utf8 }
    Call { callee: utf8, arguments: [utf8] }
    Field { object: utf8, field: utf8 }
    Binary { op: BinaryOperator, left: utf8, right: utf8 }
    Unary { op: UnaryOperator, operand: utf8 }
    Unit
}

structure LetStatement {
    is_mutable: bool
    name: utf8
    ty: utf8
    has_init: bool
    initializer: TermExpression
    span: TextSpan
}

# Flat if (statement lists) — avoids recursive DeclarationBody unite issues.
structure IfStatement {
    condition: TermExpression
    then_statements: [FunctionStatement]
    has_else: bool
    else_statements: [FunctionStatement]
    span: TextSpan
}

unite FunctionStatement {
    Let { stmt: LetStatement }
    Term { expression: TermExpression, span: TextSpan }
    Return { has_value: bool, value: TermExpression, span: TextSpan }
    If { stmt: IfStatement }
    Break { span: TextSpan }
    Continue { span: TextSpan }
}

structure DeclarationBody {
    statements: [FunctionStatement]
    has_tail: bool
    tail_expression: TermExpression
    span: TextSpan
}

micro empty_span() -> TextSpan {
    return TextSpan { start: 0, stop: 0 }
}

micro empty_declaration_body() -> DeclarationBody {
    return DeclarationBody {
        statements: [],
        has_tail: false,
        tail_expression: Unit,
        span: empty_span()
    }
}

micro empty_term() -> TermExpression {
    return Unit
}

micro term_literal_int(text: utf8) -> TermExpression {
    return Literal { lit: Integer { text: text } }
}

micro term_literal_bool(value: bool) -> TermExpression {
    return Literal { lit: Bool { value: value } }
}

micro term_literal_string(text: utf8) -> TermExpression {
    return Literal { lit: String { text: text } }
}

micro term_literal_null() -> TermExpression {
    return Literal { lit: Null }
}

micro term_name(path: utf8) -> TermExpression {
    return Name { path: path }
}

micro term_call(callee: utf8, arguments: [utf8]) -> TermExpression {
    return Call { callee: callee, arguments: arguments }
}

micro term_binary(op: BinaryOperator, left: utf8, right: utf8) -> TermExpression {
    return Binary { op: op, left: left, right: right }
}

micro term_unary(op: UnaryOperator, operand: utf8) -> TermExpression {
    return Unary { op: op, operand: operand }
}

micro function_statement_return_void() -> FunctionStatement {
    return Return { has_value: false, value: Unit, span: empty_span() }
}

micro function_statement_return_value(value: TermExpression) -> FunctionStatement {
    return Return { has_value: true, value: value, span: empty_span() }
}

micro function_statement_let(name: utf8, ty: utf8, initializer: TermExpression) -> FunctionStatement {
    return Let {
        stmt: LetStatement {
            is_mutable: false,
            name: name,
            ty: ty,
            has_init: true,
            initializer: initializer,
            span: empty_span()
        }
    }
}

micro function_statement_if(condition: TermExpression, then_statements: [FunctionStatement], else_statements: [FunctionStatement]) -> FunctionStatement {
    return If {
        stmt: IfStatement {
            condition: condition,
            then_statements: then_statements,
            has_else: else_statements.length() > 0,
            else_statements: else_statements,
            span: empty_span()
        }
    }
}

micro declaration_body_from_statements(statements: [FunctionStatement]) -> DeclarationBody {
    return DeclarationBody {
        statements: statements,
        has_tail: false,
        tail_expression: Unit,
        span: empty_span()
    }
}

# --- Expression subset (literals / names / unary / single-level-or-nested binary text) ---

micro term_from_atom_text(rest: utf8) -> TermExpression {
    let t: utf8 = rest.trim()
    if t == "null" {
        return term_literal_null()
    }
    if t == "true" {
        return term_literal_bool(true)
    }
    if t == "false" {
        return term_literal_bool(false)
    }
    if t.starts_with("\"") && t.ends_with("\"") && t.length() >= 2 {
        return term_literal_string(t.slice(1, t.length() - 2))
    }
    if t == "0" || t == "1" || t == "2" || t == "3" || t == "4" || t == "5" || t == "6" || t == "7" || t == "8" || t == "9" || t == "-1" {
        return term_literal_int(t)
    }
    if t.length() > 0 {
        let c0: utf8 = t.slice(0, 1)
        if c0 == "-" {
            return empty_term()
        }
        if c0 == "0" || c0 == "1" || c0 == "2" || c0 == "3" || c0 == "4" || c0 == "5" || c0 == "6" || c0 == "7" || c0 == "8" || c0 == "9" {
            return empty_term()
        }
        return term_name(t)
    }
    return empty_term()
}

micro index_of_top_level_op(text: utf8, op: utf8) -> i32 {
    let n: i32 = text.length()
    let olen: i32 = op.length()
    if olen <= 0 || n < olen {
        return -1
    }
    let mut i: i32 = 0
    let mut in_string: bool = false
    let mut depth: i32 = 0
    while i <= n - olen {
        let ch: utf8 = text.slice(i, 1)
        if ch == "\"" {
            in_string = !in_string
            i = i + 1
            continue
        }
        if !in_string {
            if ch == "(" {
                depth = depth + 1
            }
            else if ch == ")" {
                depth = depth - 1
            }
            else if depth == 0 {
                if text.slice(i, olen) == op {
                    return i
                }
            }
        }
        i = i + 1
    }
    return -1
}

micro try_split_binary_expr(text: utf8, op_text: utf8, op: BinaryOperator) -> TermExpression {
    let idx: i32 = index_of_top_level_op(text, op_text)
    if idx <= 0 {
        return empty_term()
    }
    let left: utf8 = text.slice(0, idx).trim()
    let right: utf8 = text.slice(idx + op_text.length(), text.length() - idx - op_text.length()).trim()
    if left.length() == 0 || right.length() == 0 {
        return empty_term()
    }
    let left_term: TermExpression = term_from_expression_text(left)
    let right_term: TermExpression = term_from_expression_text(right)
    match left_term {
        case Unit: {
            return empty_term()
        }
        else: {
            match right_term {
                case Unit: {
                    return empty_term()
                }
                else: {
                    return term_binary(op, left, right)
                }
            }
        }
    }
}

micro term_from_expression_text(rest: utf8) -> TermExpression {
    let t: utf8 = rest.trim()
    if t.length() == 0 {
        return empty_term()
    }
    if t.starts_with("(") && t.ends_with(")") && t.length() >= 2 {
        return term_from_expression_text(t.slice(1, t.length() - 2))
    }
    let mut bin: TermExpression = try_split_binary_expr(t, "!=", Ne)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "==", Eq)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "<=", Le)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, ">=", Ge)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "<", Lt)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, ">", Gt)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "+", Add)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "-", Sub)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "*", Mul)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "/", Div)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    bin = try_split_binary_expr(t, "%", Rem)
    match bin {
        case Unit: { }
        else: { return bin }
    }
    if t.starts_with("!") {
        let operand: utf8 = t.slice(1, t.length() - 1).trim()
        if operand.length() > 0 {
            return term_unary(Not, operand)
        }
    }
    return term_from_atom_text(t)
}
