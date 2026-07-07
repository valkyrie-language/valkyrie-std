namespace nyar.language.valkyrie;

using std.data.text.valkyrie;

# Bridge: FragmentSubmission / body_source subset → ValkyrieRoot AST
# (feeds HIR→MIR→ExecutableModule). Not MSIL emit — do not expand clr_body_lowering.
# Expression parsing lives in `std.data.text.valkyrie` (`term_from_expression_text`).

micro statement_from_return_line(line: utf8) -> FunctionStatement {
    let trimmed: utf8 = line.trim()
    if trimmed == "return" || trimmed == "return;" {
        return function_statement_return_void()
    }
    if trimmed.starts_with("return ") {
        let mut rest: utf8 = trimmed.slice(7, trimmed.length() - 7).trim()
        if rest.ends_with(";") {
            rest = rest.slice(0, rest.length() - 1).trim()
        }
        let value: TermExpression = term_from_expression_text(rest)
        match value {
            case Unit: {
                return function_statement_return_void()
            }
            else: {
                return function_statement_return_value(value)
            }
        }
    }
    return function_statement_return_void()
}

micro try_parse_let_line(line: utf8) -> FunctionStatement {
    let trimmed: utf8 = line.trim()
    if !trimmed.starts_with("let ") {
        return function_statement_return_void()
    }
    let mut rest: utf8 = trimmed.slice(4, trimmed.length() - 4).trim()
    if rest.ends_with(";") {
        rest = rest.slice(0, rest.length() - 1).trim()
    }
    let eq: i32 = rest.index_of("=")
    if eq <= 0 {
        return function_statement_return_void()
    }
    let left: utf8 = rest.slice(0, eq).trim()
    let right: utf8 = rest.slice(eq + 1, rest.length() - eq - 1).trim()
    let colon: i32 = left.index_of(":")
    let mut name: utf8 = left
    let mut ty: utf8 = ""
    if colon > 0 {
        name = left.slice(0, colon).trim()
        ty = left.slice(colon + 1, left.length() - colon - 1).trim()
    }
    let init: TermExpression = term_from_expression_text(right)
    match init {
        case Unit: {
            return function_statement_return_void()
        }
        else: {
            return function_statement_let(name, ty, init)
        }
    }
}

micro try_parse_statement_line(line: utf8) -> FunctionStatement {
    let trimmed: utf8 = line.trim()
    if trimmed.length() == 0 {
        return function_statement_return_void()
    }
    if trimmed.starts_with("let ") {
        return try_parse_let_line(trimmed)
    }
    if trimmed.starts_with("return") {
        return statement_from_return_line(trimmed)
    }
    return function_statement_return_void()
}

micro parse_statement_list(inner: utf8) -> [FunctionStatement] {
    let mut statements: [FunctionStatement] = []
    let mut start: i32 = 0
    let n: i32 = inner.length()
    let mut i: i32 = 0
    let mut in_string: bool = false
    let mut depth: i32 = 0
    while i < n {
        let ch: utf8 = inner.slice(i, 1)
        if ch == "\"" {
            in_string = !in_string
        }
        else if !in_string {
            if ch == "{" {
                depth = depth + 1
            }
            else if ch == "}" {
                depth = depth - 1
            }
            else if ch == ";" && depth == 0 {
                let piece: utf8 = inner.slice(start, i - start).trim()
                if piece.length() > 0 {
                    if piece.starts_with("if") {
                        let if_body: DeclarationBody = try_parse_simple_if_body(piece)
                        if if_body.statements.length() > 0 {
                            let mut fi: usize = 0
                            while fi < if_body.statements.length() {
                                statements = push(statements, if_body.statements⁅fi⁆)
                                fi = fi + 1
                            }
                        }
                    }
                    else {
                        let stmt: FunctionStatement = try_parse_statement_line(piece)
                        match stmt {
                            case Return { has_value, value, span }: {
                                statements = push(statements, stmt)
                            }
                            case Let { stmt: ls }: {
                                statements = push(statements, stmt)
                            }
                            else: { }
                        }
                    }
                }
                start = i + 1
            }
        }
        i = i + 1
    }
    let tail: utf8 = inner.slice(start, n - start).trim()
    if tail.length() > 0 {
        if tail.starts_with("if") {
            let if_body2: DeclarationBody = try_parse_simple_if_body(tail)
            if if_body2.statements.length() > 0 {
                let mut fj: usize = 0
                while fj < if_body2.statements.length() {
                    statements = push(statements, if_body2.statements⁅fj⁆)
                    fj = fj + 1
                }
            }
        }
        else {
            let stmt2: FunctionStatement = try_parse_statement_line(tail)
            match stmt2 {
                case Return { has_value, value, span }: {
                    statements = push(statements, stmt2)
                }
                case Let { stmt: ls }: {
                    statements = push(statements, stmt2)
                }
                else: { }
            }
        }
    }
    return statements
}

# Scan an if / else-if / else chain ending at the last closing brace of the chain.
micro find_if_chain_end(text: utf8, from: i32) -> i32 {
    let n: i32 = text.length()
    let mut i: i32 = from
    let mut in_string: bool = false
    let mut depth: i32 = 0
    let mut seen_brace: bool = false
    while i < n {
        let ch: utf8 = text.slice(i, 1)
        if ch == "\"" {
            in_string = !in_string
        }
        else if !in_string {
            if ch == "{" {
                depth = depth + 1
                seen_brace = true
            }
            else if ch == "}" {
                depth = depth - 1
                if seen_brace && depth == 0 {
                    let after: utf8 = text.slice(i + 1, n - i - 1).trim()
                    if after.starts_with("else") {
                        # continue into else / else if
                        i = i + 1
                    }
                    else {
                        return i
                    }
                }
            }
        }
        i = i + 1
    }
    return n - 1
}

micro parse_block_contents(inner: utf8) -> [FunctionStatement] {
    let t: utf8 = inner.trim()
    if t.length() == 0 {
        return []
    }
    # Mixed statements: walk top-level if-chains and `;`-terminated pieces.
    let mut statements: [FunctionStatement] = []
    let n: i32 = t.length()
    let mut pos: i32 = 0
    while pos < n {
        while pos < n {
            let c: utf8 = t.slice(pos, 1)
            if c == " " || c == "\n" || c == "\r" || c == "\t" {
                pos = pos + 1
            }
            else {
                break
            }
        }
        if pos >= n {
            return statements
        }
        let rest: utf8 = t.slice(pos, n - pos)
        if rest.starts_with("if") {
            let end: i32 = find_if_chain_end(t, pos)
            let chunk: utf8 = t.slice(pos, end - pos + 1).trim()
            let if_body: DeclarationBody = try_parse_simple_if_body(chunk)
            if if_body.statements.length() > 0 {
                let mut fi: usize = 0
                while fi < if_body.statements.length() {
                    statements = push(statements, if_body.statements⁅fi⁆)
                    fi = fi + 1
                }
            }
            pos = end + 1
        }
        else {
            # take until next `;` at depth 0, or rest of buffer
            let mut i: i32 = pos
            let mut in_string: bool = false
            let mut depth: i32 = 0
            let mut found: bool = false
            while i < n {
                let ch: utf8 = t.slice(i, 1)
                if ch == "\"" {
                    in_string = !in_string
                }
                else if !in_string {
                    if ch == "{" {
                        depth = depth + 1
                    }
                    else if ch == "}" {
                        depth = depth - 1
                    }
                    else if ch == ";" && depth == 0 {
                        let piece: utf8 = t.slice(pos, i - pos).trim()
                        if piece.length() > 0 {
                            let stmt: FunctionStatement = try_parse_statement_line(piece)
                            match stmt {
                                case Return { has_value, value, span }: {
                                    statements = push(statements, stmt)
                                }
                                case Let { stmt: ls }: {
                                    statements = push(statements, stmt)
                                }
                                else: { }
                            }
                        }
                        pos = i + 1
                        found = true
                        i = n
                    }
                }
                i = i + 1
            }
            if !found {
                let piece2: utf8 = t.slice(pos, n - pos).trim()
                if piece2.length() > 0 {
                    let stmt2: FunctionStatement = try_parse_statement_line(piece2)
                    match stmt2 {
                        case Return { has_value, value, span }: {
                            statements = push(statements, stmt2)
                        }
                        case Let { stmt: ls }: {
                            statements = push(statements, stmt2)
                        }
                        else: { }
                    }
                }
                pos = n
            }
        }
    }
    return statements
}

micro try_parse_simple_if_body(inner: utf8) -> DeclarationBody {
    let trimmed: utf8 = inner.trim()
    if !trimmed.starts_with("if") {
        return empty_declaration_body()
    }
    let paren_open: i32 = trimmed.index_of("(")
    if paren_open < 0 {
        return empty_declaration_body()
    }
    let paren_close: i32 = trimmed.index_of(")")
    if paren_close <= paren_open {
        return empty_declaration_body()
    }
    let cond_text: utf8 = trimmed.slice(paren_open + 1, paren_close - paren_open - 1).trim()
    let cond: TermExpression = term_from_expression_text(cond_text)
    match cond {
        case Unit: {
            return empty_declaration_body()
        }
        else: { }
    }
    let after_cond: utf8 = trimmed.slice(paren_close + 1, trimmed.length() - paren_close - 1).trim()
    let else_kw: i32 = after_cond.index_of("else")
    let mut then_part: utf8 = after_cond
    let mut else_part: utf8 = ""
    let mut has_else: bool = false
    if else_kw >= 0 {
        # Prefer the else that sits after the then-block closes (depth 0).
        let mut scan: i32 = 0
        let mut depth: i32 = 0
        let mut in_string: bool = false
        let an: i32 = after_cond.length()
        let mut else_at: i32 = -1
        while scan < an {
            let ch: utf8 = after_cond.slice(scan, 1)
            if ch == "\"" {
                in_string = !in_string
            }
            else if !in_string {
                if ch == "{" {
                    depth = depth + 1
                }
                else if ch == "}" {
                    depth = depth - 1
                }
                else if depth == 0 && after_cond.slice(scan, 4) == "else" {
                    else_at = scan
                    scan = an
                }
            }
            scan = scan + 1
        }
        if else_at >= 0 {
            then_part = after_cond.slice(0, else_at).trim()
            else_part = after_cond.slice(else_at + 4, after_cond.length() - else_at - 4).trim()
            has_else = true
        }
    }
    let then_open: i32 = then_part.index_of("{")
    if then_open < 0 {
        return empty_declaration_body()
    }
    let then_close: i32 = then_part.length() - 1
    if then_part.slice(then_close, 1) != "}" {
        return empty_declaration_body()
    }
    let then_inner: utf8 = then_part.slice(then_open + 1, then_close - then_open - 1).trim()
    let then_stmts: [FunctionStatement] = parse_block_contents(then_inner)
    if then_stmts.length() == 0 {
        return empty_declaration_body()
    }
    let mut else_stmts: [FunctionStatement] = []
    if has_else {
        # `else if (...) { ... }` → nested If; braced else → block.
        if else_part.starts_with("if") {
            else_stmts = parse_block_contents(else_part)
        }
        else {
            let else_open: i32 = else_part.index_of("{")
            if else_open < 0 {
                return empty_declaration_body()
            }
            let else_close: i32 = else_part.length() - 1
            if else_part.slice(else_close, 1) != "}" {
                return empty_declaration_body()
            }
            let else_inner: utf8 = else_part.slice(else_open + 1, else_close - else_open - 1).trim()
            else_stmts = parse_block_contents(else_inner)
        }
    }
    let mut statements: [FunctionStatement] = []
    statements = push(statements, function_statement_if(cond, then_stmts, else_stmts))
    return declaration_body_from_statements(statements)
}

micro declaration_body_parse_subset(body_source: utf8) -> DeclarationBody {
    let trimmed: utf8 = body_source.trim()
    if trimmed.length() == 0 {
        return empty_declaration_body()
    }
    let open: i32 = trimmed.index_of("{")
    let mut inner: utf8 = trimmed
    if open >= 0 {
        let mut close: i32 = -1
        let mut ci: i32 = trimmed.length() - 1
        while ci > open {
            if trimmed.slice(ci, 1) == "}" {
                close = ci
                ci = open
            }
            ci = ci - 1
        }
        if close > open {
            inner = trimmed.slice(open + 1, close - open - 1).trim()
        }
    }
    if inner.length() == 0 {
        return empty_declaration_body()
    }

    let stmts: [FunctionStatement] = parse_block_contents(inner)
    if stmts.length() > 0 {
        return declaration_body_from_statements(stmts)
    }
    return empty_declaration_body()
}

micro function_declaration_from_parsed(item: ParsedFunction, body: DeclarationBody) -> FunctionDeclaration {
    let mut return_type: utf8 = ""
    if item.return_is_unit {
        return_type = "unit"
    }
    else if item.return_is_i64 {
        return_type = "i64"
    }
    let body_present: bool = body.statements.length() > 0 || item.body_source.trim().length() > 0
    return FunctionDeclaration {
        name: new_identifier_node(item.name, 0, item.name.length()),
        parameters: [],
        return_type: return_type,
        body_present: body_present,
        body: body,
        span: empty_span()
    }
}

micro valkyrie_root_from_fragment_submission(submission: FragmentSubmission) -> ValkyrieRoot {
    let mut root: ValkyrieRoot = empty_valkyrie_root()
    if submission.module_name.length() > 0 {
        root.statements = push(root.statements, Namespace {
            decl: NamespaceDeclaration {
                path: submission.module_name,
                span: empty_span()
            }
        })
    }
    let mut i: usize = 0
    while i < submission.exported_operations.length() {
        let symbol: utf8 = submission.exported_operations⁅i⁆
        let body_source: utf8 = find_body_source(submission, symbol)
        let body: DeclarationBody = declaration_body_parse_subset(body_source)
        let mut parsed: ParsedFunction = empty_parsed_function()
        parsed.name = symbol
        parsed.return_is_unit = operation_is_void(submission, symbol)
        parsed.body_source = body_source
        root.statements = push(root.statements, Function {
            decl: function_declaration_from_parsed(parsed, body)
        })
        i = i + 1
    }
    return root
}
