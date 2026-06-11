namespace std.data.text.wat;

/// 将关键字文本映射为对应的 token kind
micro wat_keyword_kind(word: utf8) -> WatTokenKind {
    if word == "module" {
        return ModuleKeyword
    }
    if word == "func" {
        return FuncKeyword
    }
    if word == "import" {
        return ImportKeyword
    }
    if word == "export" {
        return ExportKeyword
    }
    if word == "memory" {
        return MemoryKeyword
    }
    if word == "table" {
        return TableKeyword
    }
    if word == "global" {
        return GlobalKeyword
    }
    if word == "data" {
        return DataKeyword
    }
    if word == "type" {
        return TypeKeyword
    }
    if word == "param" {
        return ParamKeyword
    }
    if word == "result" {
        return ResultKeyword
    }
    if word == "local" {
        return LocalKeyword
    }
    if word == "block" {
        return BlockKeyword
    }
    if word == "loop" {
        return LoopKeyword
    }
    if word == "if" {
        return IfKeyword
    }
    if word == "then" {
        return ThenKeyword
    }
    if word == "else" {
        return ElseKeyword
    }
    if word == "end" {
        return EndKeyword
    }
    if word == "start" {
        return StartKeyword
    }
    if word == "elem" {
        return ElemKeyword
    }
    if word == "offset" {
        return OffsetKeyword
    }
    if word == "item" {
        return ItemKeyword
    }
    if word == "mut" {
        return MutKeyword
    }
    return Identifier(word)
}

micro is_wat_keyword(word: utf8) -> bool {
    return word == "module" || word == "func" || word == "import" || word == "export"
        || word == "memory" || word == "table" || word == "global" || word == "data"
        || word == "type" || word == "param" || word == "result" || word == "local"
        || word == "block" || word == "loop" || word == "if" || word == "then"
        || word == "else" || word == "end" || word == "start" || word == "elem"
        || word == "offset" || word == "item" || word == "mut"
}

micro is_wat_plain_opcode(word: utf8) -> bool {
    return word == "call" || word == "call_indirect" || word == "nop"
        || word == "drop" || word == "select" || word == "return"
        || word == "unreachable" || word == "br" || word == "br_if"
        || word == "br_table"
}

micro is_wat_dotted_opcode(word: utf8) -> bool {
    let mut has_dot: bool = false
    let mut i: usize = 0
    while i < word.length {
        if word[i] == "." {
            has_dot = true
            break
        }
        i = i + 1
    }
    if !has_dot {
        return false
    }
    return word[0] != "." && is_wat_letter(word[0])
}

micro lex_wat(source: utf8) -> WatParseResult<[WatToken]> {
    let mut tokens: [WatToken] = []
    let mut pos: usize = 0
    let mut line: usize = 1
    let mut col: usize = 1
    let length: usize = source.length

    while pos < length {
        let ch: utf8 = source[pos]

        if ch == " " || ch == "\t" || ch == "\r" || ch == "\n" {
            if ch == "\n" {
                line = line + 1
                col = 0
            }
            pos = pos + 1
            col = col + 1
            continue
        }

        if ch == ";" && pos + 1 < length && source[pos + 1] == ";" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            while pos < length && source[pos] != "\n" {
                pos = pos + 1
            }
            push(tokens, new_wat_token(Comment(""), start, pos, start_line, start_col))
            continue
        }

        if ch == "(" && pos + 1 < length && source[pos + 1] == ";" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut depth: i32 = 1
            pos = pos + 2
            while pos < length && depth > 0 {
                if source[pos] == "(" && pos + 1 < length && source[pos + 1] == ";" {
                    depth = depth + 1
                    pos = pos + 2
                } else {
                    if source[pos] == ";" && pos + 1 < length && source[pos + 1] == ")" {
                        depth = depth - 1
                        pos = pos + 2
                    } else {
                        pos = pos + 1
                    }
                }
            }
            push(tokens, new_wat_token(Comment(""), start, pos, start_line, start_col))
            continue
        }

        if ch == "(" || ch == ")" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            pos = pos + 1
            col = col + 1
            push(tokens, new_wat_token(Punctuation(ch), start, pos, start_line, start_col))
            continue
        }

        if ch == "$" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = "$"
            pos = pos + 1
            while pos < length {
                let cur: utf8 = source[pos]
                if is_wat_letter_or_digit(cur) || cur == "_" || cur == "." || cur == "-" || cur == ">" || cur == "<" {
                    text = text + cur
                    pos = pos + 1
                } else {
                    break
                }
            }
            push(tokens, new_wat_token(Identifier(text), start, pos, start_line, start_col))
            continue
        }

        if ch == "\"" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = "\""
            pos = pos + 1
            while pos < length && source[pos] != "\"" {
                if source[pos] == "\\" {
                    text = text + "\\"
                    pos = pos + 1
                    if pos < length {
                        text = text + source[pos]
                        pos = pos + 1
                    }
                } else {
                    text = text + source[pos]
                    pos = pos + 1
                }
            }
            if pos < length {
                text = text + "\""
                pos = pos + 1
            }
            push(tokens, new_wat_token(String(text), start, pos, start_line, start_col))
            continue
        }

        if is_wat_digit(ch) || ch == "-" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = ""
            if ch == "-" {
                text = text + "-"
                pos = pos + 1
            }
            while pos < length {
                let cur: utf8 = source[pos]
                if is_wat_digit(cur) || cur == "." || cur == "x" || cur == "e" || cur == "E"
                    || cur == "+" || cur == "-" || cur == "p" || cur == "P"
                    || is_wat_hex_digit(cur) {
                    text = text + cur
                    pos = pos + 1
                } else {
                    break
                }
            }
            push(tokens, new_wat_token(Number(text), start, pos, start_line, start_col))
            continue
        }

        if is_wat_letter(ch) || ch == "_" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = ""
            while pos < length {
                let cur: utf8 = source[pos]
                if is_wat_letter_or_digit(cur) || cur == "_" || cur == "." || cur == "/" {
                    text = text + cur
                    pos = pos + 1
                } else {
                    break
                }
            }

            if is_wat_keyword(text) {
                let kind: WatTokenKind = wat_keyword_kind(text)
                push(tokens, new_wat_token(kind, start, pos, start_line, start_col))
            } else if is_wat_value_type(text) {
                push(tokens, new_wat_token(Identifier(text), start, pos, start_line, start_col))
            } else if is_wat_plain_opcode(text) || is_wat_dotted_opcode(text) {
                push(tokens, new_wat_token(Opcode(text), start, pos, start_line, start_col))
            } else {
                push(tokens, new_wat_token(Identifier(text), start, pos, start_line, start_col))
            }
            continue
        }

        return Fail(new_wat_diagnostic("存在无法识别的 WAT 字符", pos, pos + 1))
    }

    push(tokens, eof_wat_token(pos, line, col))
    return Fine(tokens)
}

micro is_wat_digit(ch: utf8) -> bool {
    return ch >= "0" && ch <= "9"
}

micro is_wat_letter(ch: utf8) -> bool {
    return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z")
}

micro is_wat_letter_or_digit(ch: utf8) -> bool {
    return is_wat_letter(ch) || is_wat_digit(ch)
}

micro is_wat_hex_digit(ch: utf8) -> bool {
    return is_wat_digit(ch)
        || (ch >= "a" && ch <= "f")
        || (ch >= "A" && ch <= "F")
}