namespace std.data.text.wit;

micro is_wit_keyword(word: utf8) -> bool {
    return word == "interface" || word == "world" || word == "record" || word == "variant"
        || word == "enum" || word == "flags" || word == "use" || word == "type"
        || word == "resource" || word == "func" || word == "import" || word == "export"
        || word == "include" || word == "default" || word == "static" || word == "constructor"
        || word == "with" || word == "as"
}

micro is_wit_type_name(word: utf8) -> bool {
    return word == "u8" || word == "u16" || word == "u32" || word == "u64"
        || word == "s8" || word == "s16" || word == "s32" || word == "s64"
        || word == "float32" || word == "float64" || word == "char" || word == "bool"
        || word == "string" || word == "list" || word == "option" || word == "result"
        || word == "tuple" || word == "future" || word == "stream"
}

micro lex_wit(source: utf8) -> WitParseResult<[WitToken]> {
    let mut tokens: [WitToken] = []
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

        if ch == "/" && pos + 1 < length && source[pos + 1] == "/" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            while pos < length && source[pos] != "\n" {
                pos = pos + 1
            }
            push(tokens, new_wit_token(Comment, "", start, pos, start_line, start_col))
            continue
        }

        if ch == "/" && pos + 1 < length && source[pos + 1] == "*" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            pos = pos + 2
            while pos < length {
                if source[pos] == "*" && pos + 1 < length && source[pos + 1] == "/" {
                    pos = pos + 2
                    break
                }
                if source[pos] == "\n" {
                    line = line + 1
                    col = 0
                }
                pos = pos + 1
            }
            push(tokens, new_wit_token(Comment, "", start, pos, start_line, start_col))
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
            push(tokens, new_wit_token(String, text, start, pos, start_line, start_col))
            continue
        }

        let matched: bool = false
        if pos + 1 < length {
            if source[pos] == "-" && source[pos + 1] == ">" {
                let start: usize = pos
                push(tokens, new_wit_token(Punctuation, "->", start, pos + 2, line, col))
                pos = pos + 2
                col = col + 2
                matched = true
            } else {
                if source[pos] == ":" && source[pos + 1] == ":" {
                    let start: usize = pos
                    push(tokens, new_wit_token(Punctuation, "::", start, pos + 2, line, col))
                    pos = pos + 2
                    col = col + 2
                    matched = true
                } else {
                    if source[pos] == "%" {
                        let start: usize = pos
                        let mut pkg_text: utf8 = ""
                        pos = pos + 1
                        while pos < length && (is_wit_letter_or_digit(source[pos]) || source[pos] == "-" || source[pos] == ":") {
                            pkg_text = pkg_text + source[pos]
                            pos = pos + 1
                        }
                        push(tokens, new_wit_token(PackageRef, pkg_text, start, pos, line, col))
                        matched = true
                    }
                }
            }
        }

        if !matched {
            if ch == "{" || ch == "}" || ch == "(" || ch == ")" || ch == ";"
                || ch == "," || ch == ":" || ch == "=" || ch == "<" || ch == ">"
                || ch == "*" || ch == "_" && !(pos + 1 < length && is_wit_identifier_part(source[pos + 1])) {
                let start: usize = pos
                push(tokens, new_wit_token(Punctuation, ch, start, pos + 1, line, col))
                pos = pos + 1
                col = col + 1
                matched = true
            }
        }

        if matched {
            continue
        }

        if is_wit_digit(ch) {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = ""
            while pos < length && (is_wit_digit(source[pos]) || source[pos] == "_") {
                text = text + source[pos]
                pos = pos + 1
            }
            push(tokens, new_wit_token(Number, text, start, pos, start_line, start_col))
            continue
        }

        if is_wit_letter(ch) || ch == "_" || ch == "-" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = ""
            while pos < length && is_wit_identifier_part(source[pos]) {
                text = text + source[pos]
                pos = pos + 1
            }

            if is_wit_keyword(text) {
                push(tokens, new_wit_token(Keyword, text, start, pos, start_line, start_col))
            } else {
                if is_wit_type_name(text) {
                    push(tokens, new_wit_token(TypeName, text, start, pos, start_line, start_col))
                } else {
                    push(tokens, new_wit_token(Identifier, text, start, pos, start_line, start_col))
                }
            }
            continue
        }

        return Fail(new_wit_diagnostic("存在无法识别的 WIT 字符", pos, pos + 1))
    }

    push(tokens, eof_wit_token(pos, line, col))
    return Fine(tokens)
}

micro is_wit_digit(ch: utf8) -> bool {
    return ch >= "0" && ch <= "9"
}

micro is_wit_letter(ch: utf8) -> bool {
    return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z")
}

micro is_wit_letter_or_digit(ch: utf8) -> bool {
    return is_wit_letter(ch) || is_wit_digit(ch)
}

micro is_wit_identifier_part(ch: utf8) -> bool {
    return is_wit_letter_or_digit(ch) || ch == "-" || ch == "_" || ch == "/"
}
