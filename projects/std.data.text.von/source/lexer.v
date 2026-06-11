namespace std.data.text.von;

micro is_von_whitespace(ch: utf8) -> bool {
    return ch == " " || ch == "\t" || ch == "\r" || ch == "\n"
}

micro is_von_digit(ch: utf8) -> bool {
    return ch >= "0" && ch <= "9"
}

micro is_von_identifier_start(ch: utf8) -> bool {
    return (ch >= "a" && ch <= "z")
        || (ch >= "A" && ch <= "Z")
        || ch == "_"
}

micro is_von_identifier_continue(ch: utf8) -> bool {
    return is_von_identifier_start(ch)
        || is_von_digit(ch)
        || ch == "."
        || ch == "-"
}

micro lex_von(source: utf8) -> VonParseResult<[VonToken]> {
    let mut tokens: [VonToken] = []
    let mut index: usize = 0
    let length: usize = len(source)

    while index < length {
        let ch: utf8 = source[index]

        if is_von_whitespace(ch) {
            index = index + 1
            continue
        }

        if ch == "#" {
            index = index + 1
            while index < length && source[index] != "\n" {
                index = index + 1
            }
            continue
        }

        if ch == "{" {
            push(tokens, new_von_token(LeftBrace, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "}" {
            push(tokens, new_von_token(RightBrace, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "[" {
            push(tokens, new_von_token(LeftBracket, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "]" {
            push(tokens, new_von_token(RightBracket, index, index + 1))
            index = index + 1
            continue
        }

        if ch == ":" {
            push(tokens, new_von_token(Colon, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "," {
            push(tokens, new_von_token(Comma, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "\"" {
            let start: usize = index
            let mut text: utf8 = ""
            index = index + 1
            while index < length {
                let current: utf8 = source[index]
                if current == "\"" {
                    index = index + 1
                    push(tokens, new_von_token(StringLiteral(text), start, index))
                    text = ""
                    break
                }

                if current == "\\" {
                    if index + 1 >= length {
                        return Fail(new_von_diagnostic("字符串转义缺少后续字符", start, length))
                    }

                    let escaped: utf8 = source[index + 1]
                    if escaped == "n" {
                        text = text + "\n"
                    } else {
                        if escaped == "r" {
                            text = text + "\r"
                        } else {
                            if escaped == "t" {
                                text = text + "\t"
                            } else {
                                text = text + escaped
                            }
                        }
                    }
                    index = index + 2
                    continue
                }

                text = text + current
                index = index + 1
            }

            if len(text) > 0 && (len(tokens) == 0 || tokens[len(tokens) - 1].span.start != start) {
                return Fail(new_von_diagnostic("字符串缺少结束引号", start, length))
            }
            continue
        }

        if is_von_digit(ch) || ch == "-" {
            let start: usize = index
            let mut text: utf8 = ""
            while index < length {
                let current: utf8 = source[index]
                if is_von_digit(current) || current == "-" || current == "." {
                    text = text + current
                    index = index + 1
                } else {
                    break
                }
            }
            push(tokens, new_von_token(NumberLiteral(text), start, index))
            continue
        }

        if is_von_identifier_start(ch) {
            let start: usize = index
            let mut text: utf8 = ""
            while index < length && is_von_identifier_continue(source[index]) {
                text = text + source[index]
                index = index + 1
            }

            if text == "true" || text == "false" {
                push(tokens, new_von_token(BooleanLiteral(text), start, index))
            } else {
                push(tokens, new_von_token(Identifier(text), start, index))
            }
            continue
        }

        return Fail(new_von_diagnostic("存在无法识别的 VON 字符", index, index + 1))
    }

    push(tokens, eof_von_token(length))
    return Fine(tokens)
}
