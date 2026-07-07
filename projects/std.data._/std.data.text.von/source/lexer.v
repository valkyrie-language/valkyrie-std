namespace std.data.text.von;

micro is_von_whitespace(ch: utf8) -> bool {
    # Use \u{…} — seed-compiled decode_v_string_content drops short `\n`/`\t`/`\r`
    # escapes, so `"\n"` becomes the two-char sequence backslash+n in MSIL ldstr.
    return ch == " " || ch == "\u{09}" || ch == "\u{0d}" || ch == "\u{0a}"
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

structure VonStringLex {
    text: utf8
    end: usize
}

# Scan a string whose opening quote is at `start`. Returns content + end offset (past close).
# Implemented as its own micro so the cursor SSA flows out via `return Fine(...)` instead of
# a while exit-edge (CLR currently drops carried stores on that edge).
micro lex_von_string(source: utf8, start: usize) -> VonParseResult<VonStringLex> {
    let length: usize = source.length()
    let mut cursor: usize = start + 1
    let mut text: utf8 = ""

    while cursor < length {
        let current: utf8 = source⁅cursor⁆
        if current == '''"''' {
            return Fine(VonStringLex {
                text: text,
                end: cursor + 1
            })
        }

        if current == "\\" {
            if cursor + 1 >= length {
                return Fail(new_von_diagnostic("字符串转义缺少后续字符", start, length))
            }

            let escaped: utf8 = source⁅cursor + 1⁆
            if escaped == "n" {
                text = text + "\u{0a}"
            } else {
                if escaped == "r" {
                    text = text + "\u{0d}"
                } else {
                    if escaped == "t" {
                        text = text + "\u{09}"
                    } else {
                        text = text + escaped
                    }
                }
            }
            cursor = cursor + 2
            continue
        }

        text = text + current
        cursor = cursor + 1
    }

    return Fail(new_von_diagnostic("字符串缺少结束引号", start, length))
}

micro lex_von_number(source: utf8, start: usize) -> VonStringLex {
    let length: usize = source.length()
    let mut cursor: usize = start
    let mut text: utf8 = ""

    while cursor < length {
        let current: utf8 = source⁅cursor⁆
        if is_von_digit(current) || current == "-" || current == "." {
            text = text + current
            cursor = cursor + 1
            continue
        }
        return VonStringLex {
            text: text,
            end: cursor
        }
    }

    return VonStringLex {
        text: text,
        end: cursor
    }
}

micro lex_von_identifier(source: utf8, start: usize) -> VonStringLex {
    let length: usize = source.length()
    let mut cursor: usize = start
    let mut text: utf8 = ""

    while cursor < length {
        let current: utf8 = source⁅cursor⁆
        if is_von_identifier_continue(current) {
            text = text + current
            cursor = cursor + 1
            continue
        }
        return VonStringLex {
            text: text,
            end: cursor
        }
    }

    return VonStringLex {
        text: text,
        end: cursor
    }
}

micro lex_von(source: utf8) -> VonParseResult<[VonToken]> {
    let mut tokens: [VonToken] = []
    let mut index: usize = 0
    let length: usize = source.length()

    while index < length {
        let ch: utf8 = source⁅index⁆

        if is_von_whitespace(ch) {
            index = index + 1
            continue
        }

        if ch == "#" {
            index = index + 1
            while index < length && source⁅index⁆ != "\u{0a}" {
                index = index + 1
            }
            continue
        }

        if ch == "{" {
            push(tokens, new_von_marker_token(LeftBrace, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "}" {
            push(tokens, new_von_marker_token(RightBrace, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "[" {
            push(tokens, new_von_marker_token(LeftBracket, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "]" {
            push(tokens, new_von_marker_token(RightBracket, index, index + 1))
            index = index + 1
            continue
        }

        if ch == ":" {
            push(tokens, new_von_marker_token(Colon, index, index + 1))
            index = index + 1
            continue
        }

        if ch == "," {
            push(tokens, new_von_marker_token(Comma, index, index + 1))
            index = index + 1
            continue
        }

        if ch == '''"''' {
            match lex_von_string(source, index) {
                case Fine(lexed):
                    push(tokens, new_von_token(StringLiteral, lexed.text, index, lexed.end))
                    index = lexed.end
                    continue
                case Fail(error):
                    return Fail(error)
            }
        }

        if is_von_digit(ch) || ch == "-" {
            let lexed: VonStringLex = lex_von_number(source, index)
            push(tokens, new_von_token(NumberLiteral, lexed.text, index, lexed.end))
            index = lexed.end
            continue
        }

        if is_von_identifier_start(ch) {
            let lexed: VonStringLex = lex_von_identifier(source, index)
            if lexed.text == "true" || lexed.text == "false" {
                push(tokens, new_von_token(BooleanLiteral, lexed.text, index, lexed.end))
            } else {
                push(tokens, new_von_token(Identifier, lexed.text, index, lexed.end))
            }
            index = lexed.end
            continue
        }

        return Fail(new_von_diagnostic("存在无法识别的 VON 字符", index, index + 1))
    }

    push(tokens, eof_von_token(length))
    return Fine(tokens)
}
