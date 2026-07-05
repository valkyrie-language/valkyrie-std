namespace std.data.text.von;

structure VonParsedValue {
    value: VonValue
    next_index: usize
}

micro parse_von(source: utf8) -> VonParseResult<VonValue> {
    let lexed: VonParseResult<[VonToken]> = lex_von(source)
    let lex_failure: VonDiagnostic? = von_parse_take_fail(lexed)
    if lex_failure.is_some() {
        return Fail(lex_failure.unwrap())
    }
    let tokens: [VonToken] = von_parse_take_fine(lexed).unwrap()
    return parse_von_tokens(tokens)
}

micro parse_von_tokens(tokens: [VonToken]) -> VonParseResult<VonValue> {
    let parsed_result: VonParseResult<VonParsedValue> = parse_von_value(tokens, 0)
    let parse_failure: VonDiagnostic? = von_parse_take_fail(parsed_result)
    if parse_failure.is_some() {
        return Fail(parse_failure.unwrap())
    }
    let parsed: VonParsedValue = von_parse_take_fine(parsed_result).unwrap()
    let tail: VonToken = peek_von_token(tokens, parsed.next_index)
    let tail_kind: VonTokenKind = tail.kind
    if tail_kind == EndOfFile {
        return Fine(parsed.value)
    }
    return Fail(new_von_diagnostic("VON 文档尾部存在多余内容", tail.span.start, tail.span.stop))
}

micro parse_von_value(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let token: VonToken = peek_von_token(tokens, index)
    let kind: VonTokenKind = token.kind
    if kind == StringLiteral {
        return Fine(VonParsedValue {
            value: Text(token.text),
            next_index: index + 1
        })
    }
    if kind == NumberLiteral {
        return Fine(VonParsedValue {
            value: Number(token.text),
            next_index: index + 1
        })
    }
    if kind == BooleanLiteral {
        return Fine(VonParsedValue {
            value: Flag(token.text == "true"),
            next_index: index + 1
        })
    }
    if kind == Identifier {
        return Fine(VonParsedValue {
            value: Name(token.text),
            next_index: index + 1
        })
    }
    if kind == LeftBrace {
        return parse_von_object(tokens, index)
    }
    if kind == LeftBracket {
        return parse_von_array(tokens, index)
    }
    return Fail(new_von_diagnostic("当前位置不能解析为 VON 值", token.span.start, token.span.stop))
}

micro parse_von_object(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let mut fields: [VonField] = []
    let mut current: usize = index + 1

    while true {
        let token: VonToken = peek_von_token(tokens, current)
        let kind: VonTokenKind = token.kind
        if kind == RightBrace {
            return Fine(VonParsedValue {
                value: Object(fields),
                next_index: current + 1
            })
        }
        if kind == EndOfFile {
            return Fail(new_von_diagnostic("对象缺少结束大括号", token.span.start, token.span.stop))
        }

        let key: utf8 = parse_von_field_name(tokens, current)
        if key.length() == 0 {
            return Fail(new_von_diagnostic("对象字段名必须是标识符或字符串", token.span.start, token.span.stop))
        }

        current = current + 1
        let colon: VonToken = peek_von_token(tokens, current)
        let colon_kind: VonTokenKind = colon.kind
        if colon_kind != Colon {
            return Fail(new_von_diagnostic("对象字段名后缺少冒号", colon.span.start, colon.span.stop))
        }
        current = current + 1

        let field_result: VonParseResult<VonParsedValue> = parse_von_value(tokens, current)
        let field_failure: VonDiagnostic? = von_parse_take_fail(field_result)
        if field_failure.is_some() {
            return Fail(field_failure.unwrap())
        }
        let parsed: VonParsedValue = von_parse_take_fine(field_result).unwrap()
        push(fields, new_von_field(key, parsed.value))
        current = parsed.next_index

        let separator: VonToken = peek_von_token(tokens, current)
        let separator_kind: VonTokenKind = separator.kind
        if separator_kind == Comma {
            current = current + 1
            continue
        }
        if separator_kind == RightBrace {
            continue
        }
        return Fail(new_von_diagnostic("对象字段后缺少逗号或结束大括号", separator.span.start, separator.span.stop))
    }
}

micro parse_von_array(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let mut items: [VonValue] = []
    let mut current: usize = index + 1

    while true {
        let token: VonToken = peek_von_token(tokens, current)
        let kind: VonTokenKind = token.kind
        if kind == RightBracket {
            return Fine(VonParsedValue {
                value: Array(items),
                next_index: current + 1
            })
        }
        if kind == EndOfFile {
            return Fail(new_von_diagnostic("数组缺少结束方括号", token.span.start, token.span.stop))
        }

        let item_result: VonParseResult<VonParsedValue> = parse_von_value(tokens, current)
        let item_failure: VonDiagnostic? = von_parse_take_fail(item_result)
        if item_failure.is_some() {
            return Fail(item_failure.unwrap())
        }
        let parsed: VonParsedValue = von_parse_take_fine(item_result).unwrap()
        push(items, parsed.value)
        current = parsed.next_index

        let separator: VonToken = peek_von_token(tokens, current)
        let separator_kind: VonTokenKind = separator.kind
        if separator_kind == Comma {
            current = current + 1
            continue
        }
        if separator_kind == RightBracket {
            continue
        }
        return Fail(new_von_diagnostic("数组元素后缺少逗号或结束方括号", separator.span.start, separator.span.stop))
    }
}

micro parse_von_field_name(tokens: [VonToken], index: usize) -> utf8 {
    let token: VonToken = peek_von_token(tokens, index)
    let kind: VonTokenKind = token.kind
    if kind == Identifier {
        return token.text
    }
    if kind == StringLiteral {
        return token.text
    }
    return ""
}

micro peek_von_token(tokens: [VonToken], index: usize) -> VonToken {
    if index >= tokens.length() {
        return eof_von_token(index)
    }
    return tokens[index]
}
