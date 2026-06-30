namespace std.data.text.von;

structure VonParsedValue {
    value: VonValue
    next_index: usize
}

micro parse_von(source: utf8) -> VonParseResult<VonValue> {
    match lex_von(source) {
        case Fine(tokens):
            return parse_von_tokens(tokens)
        case Fail(error):
            return Fail(error)
    }
}

micro parse_von_tokens(tokens: [VonToken]) -> VonParseResult<VonValue> {
    match parse_von_value(tokens, 0) {
        case Fine(parsed):
            let tail: VonToken = peek_von_token(tokens, parsed.next_index)
            match tail.kind {
                case EndOfFile:
                    return Fine(parsed.value)
                else:
                    return Fail(new_von_diagnostic("VON 文档尾部存在多余内容", tail.span.start, tail.span.stop))
            }
        case Fail(error):
            return Fail(error)
    }
}

micro parse_von_value(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let token: VonToken = peek_von_token(tokens, index)
    match token.kind {
        case StringLiteral(text):
            return Fine(VonParsedValue {
                value: Text(text),
                next_index: index + 1
            })
        case NumberLiteral(text):
            return Fine(VonParsedValue {
                value: Number(text),
                next_index: index + 1
            })
        case BooleanLiteral(text):
            return Fine(VonParsedValue {
                value: Flag(text == "true"),
                next_index: index + 1
            })
        case Identifier(text):
            return Fine(VonParsedValue {
                value: Name(text),
                next_index: index + 1
            })
        case LeftBrace:
            return parse_von_object(tokens, index)
        case LeftBracket:
            return parse_von_array(tokens, index)
        else:
            return Fail(new_von_diagnostic("当前位置不能解析为 VON 值", token.span.start, token.span.stop))
    }
}

micro parse_von_object(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let mut fields: [VonField] = []
    let mut current: usize = index + 1

    while true {
        let token: VonToken = peek_von_token(tokens, current)
        match token.kind {
            case RightBrace:
                return Fine(VonParsedValue {
                    value: Object(fields),
                    next_index: current + 1
                })
            case EndOfFile:
                return Fail(new_von_diagnostic("对象缺少结束大括号", token.span.start, token.span.stop))
            else:
                let key: utf8 = parse_von_field_name(tokens, current)
                if key.length() == 0 {
                    return Fail(new_von_diagnostic("对象字段名必须是标识符或字符串", token.span.start, token.span.stop))
                }

                current = current + 1
                let colon: VonToken = peek_von_token(tokens, current)
                match colon.kind {
                    case Colon:
                        current = current + 1
                    else:
                        return Fail(new_von_diagnostic("对象字段名后缺少冒号", colon.span.start, colon.span.stop))
                }

                match parse_von_value(tokens, current) {
                    case Fine(parsed):
                        push(fields, new_von_field(key, parsed.value))
                        current = parsed.next_index
                    case Fail(error):
                        return Fail(error)
                }

                let separator: VonToken = peek_von_token(tokens, current)
                match separator.kind {
                    case Comma:
                        current = current + 1
                    case RightBrace:
                        continue
                    else:
                        return Fail(new_von_diagnostic("对象字段后缺少逗号或结束大括号", separator.span.start, separator.span.stop))
                }
        }
    }
}

micro parse_von_array(tokens: [VonToken], index: usize) -> VonParseResult<VonParsedValue> {
    let mut items: [VonValue] = []
    let mut current: usize = index + 1

    while true {
        let token: VonToken = peek_von_token(tokens, current)
        match token.kind {
            case RightBracket:
                return Fine(VonParsedValue {
                    value: Array(items),
                    next_index: current + 1
                })
            case EndOfFile:
                return Fail(new_von_diagnostic("数组缺少结束方括号", token.span.start, token.span.stop))
            else:
                match parse_von_value(tokens, current) {
                    case Fine(parsed):
                        push(items, parsed.value)
                        current = parsed.next_index
                    case Fail(error):
                        return Fail(error)
                }

                let separator: VonToken = peek_von_token(tokens, current)
                match separator.kind {
                    case Comma:
                        current = current + 1
                    case RightBracket:
                        continue
                    else:
                        return Fail(new_von_diagnostic("数组元素后缺少逗号或结束方括号", separator.span.start, separator.span.stop))
                }
        }
    }
}

micro parse_von_field_name(tokens: [VonToken], index: usize) -> utf8 {
    let token: VonToken = peek_von_token(tokens, index)
    match token.kind {
        case Identifier(text) | StringLiteral(text):
            return text
        else:
            return ""
    }
}

micro peek_von_token(tokens: [VonToken], index: usize) -> VonToken {
    if index >= tokens.length() {
        return eof_von_token(index)
    }
    return tokens[index]
}
