namespace std.data.text.msil;

⍝ 将指令文本映射为对应的 token kind
micro msil_directive_kind(text: utf8) -> MsilTokenKind {
    if text == ".assembly" {
        return AssemblyDirective
    }
    if text == ".module" {
        return ModuleDirective
    }
    if text == ".class" {
        return ClassDirective
    }
    if text == ".override" {
        return OverrideDirective
    }
    if text == ".permission" {
        return PermissionDirective
    }
    if text == ".permissionset" {
        return PermissionSetDirective
    }
    if text == ".hash" {
        return HashDirective
    }
    if text == ".ver" {
        return VerDirective
    }
    if text == ".locale" {
        return LocaleDirective
    }
    if text == ".publickey" {
        return PublicKeyDirective
    }
    if text == ".custom" {
        return CustomDirective
    }
    if text == ".pack" {
        return PackDirective
    }
    if text == ".size" {
        return SizeDirective
    }
    if text == ".field" {
        return FieldDirective
    }
    if text == ".method" {
        return MethodDirective
    }
    if text == ".property" {
        return PropertyDirective
    }
    if text == ".event" {
        return EventDirective
    }
    if text == ".maxstack" {
        return MaxStackDirective
    }
    if text == ".locals" {
        return LocalsDirective
    }
    if text == ".try" {
        return TryDirective
    }
    if text == ".line" {
        return LineDirective
    }
    if text == ".language" {
        return LanguageDirective
    }
    if text == ".entrypoint" {
        return EntryPointDirective
    }
    if text == ".get" {
        return GetDirective
    }
    if text == ".set" {
        return SetDirective
    }
    if text == ".addon" {
        return AddOnDirective
    }
    if text == ".removeon" {
        return RemoveOnDirective
    }
    if text == ".fire" {
        return FireDirective
    }
    if text == ".pinvokeimpl" {
        return PInvokeImplDirective
    }
    return Opcode(text)
}

⍝ 将关键字文本映射为对应的 token kind
micro msil_keyword_kind(word: utf8) -> MsilTokenKind {
    if word == "extends" {
        return ExtendsKeyword
    }
    if word == "implements" {
        return ImplementsKeyword
    }
    if word == "catch" {
        return CatchKeyword
    }
    if word == "filter" {
        return FilterKeyword
    }
    if word == "finally" {
        return FinallyKeyword
    }
    if word == "fault" {
        return FaultKeyword
    }
    if word == "init" {
        return InitKeyword
    }
    if word == "default" {
        return DefaultKeyword
    }
    if word == "vararg" {
        return VarArgKeyword
    }
    if word == "at" {
        return AtKeyword
    }
    if word == "as" {
        return AsKeyword
    }
    if word == "cil" {
        return CilKeyword
    }
    if word == "managed" {
        return ManagedKeyword
    }
    return Identifier(word)
}

micro is_msil_type_ref(word: utf8) -> bool {
    return word == "void" || word == "bool" || word == "int8" || word == "int16"
        || word == "int32" || word == "int64" || word == "unsigned.int8"
        || word == "unsigned.int16" || word == "unsigned.int32" || word == "unsigned.int64"
        || word == "float32" || word == "float64" || word == "string"
        || word == "object" || word == "native" || word == "typedref"
}

micro is_msil_opcode(word: utf8) -> bool {
    let length: usize = word.length
    if length == 0 {
        return false
    }
    if word[0] == "." {
        return false
    }
    let mut has_dot: bool = false
    let mut i: usize = 0
    while i < length {
        if word[i] == "." {
            has_dot = true
            break
        }
        i = i + 1
    }
    return has_dot && is_msil_letter(word[0])
}

micro lex_msil(source: utf8) -> MsilParseResult<[MsilToken]> {
    let mut tokens: [MsilToken] = []
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
            let mut comment_text: utf8 = ""
            while pos < length && source[pos] != "\n" {
                comment_text = comment_text + source[pos]
                pos = pos + 1
            }
            push(tokens, new_msil_token(Comment(comment_text), start, pos, start_line, start_col))
            continue
        }

        if ch == "/" && pos + 1 < length && source[pos + 1] == "*" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut comment_text: utf8 = "/*"
            pos = pos + 2
            while pos < length {
                comment_text = comment_text + source[pos]
                if source[pos] == "*" && pos + 1 < length && source[pos + 1] == "/" {
                    comment_text = comment_text + "/"
                    pos = pos + 2
                    break
                }
                if source[pos] == "\n" {
                    line = line + 1
                    col = 0
                }
                pos = pos + 1
            }
            push(tokens, new_msil_token(Comment(comment_text), start, pos, start_line, start_col))
            continue
        }

        if ch == '''"''' {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = '''"'''
            pos = pos + 1
            while pos < length && source[pos] != '''"''' {
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
                text = text + '''"'''
                pos = pos + 1
            }
            push(tokens, new_msil_token(String(text), start, pos, start_line, start_col))
            continue
        }

        if ch == "." {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = "."
            pos = pos + 1
            while pos < length {
                let cur: utf8 = source[pos]
                if is_msil_letter_or_digit(cur) || cur == "." || cur == "_" {
                    text = text + cur
                    pos = pos + 1
                } else {
                    break
                }
            }

            if is_msil_letter(text[1]) {
                let kind: MsilTokenKind = msil_directive_kind(text)
                push(tokens, new_msil_token(kind, start, pos, start_line, start_col))
            } else {
                push(tokens, new_msil_token(Opcode(text), start, pos, start_line, start_col))
            }
            continue
        }

        if ch == "{" || ch == "}" || ch == "(" || ch == ")" || ch == ";" || ch == ":"
            || ch == "," || ch == "[" || ch == "]" || ch == "=" {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            pos = pos + 1
            col = col + 1
            push(tokens, new_msil_token(Punctuation(ch), start, pos, start_line, start_col))
            continue
        }

        if ch == "I" && pos + 2 < length && (pos == 0 || source[pos - 1] == "\n" || source[pos - 1] == " ") {
            if source[pos + 1] == "L" && source[pos + 2] == "_" {
                let start: usize = pos
                let start_line: usize = line
                let start_col: usize = col
                let mut text: utf8 = ""
                pos = pos + 3
                text = text + "I" + "L" + "_"
                while pos < length && is_msil_digit(source[pos]) {
                    text = text + source[pos]
                    pos = pos + 1
                }
                if pos < length && source[pos] == ":" {
                    text = text + ":"
                    pos = pos + 1
                }
                push(tokens, new_msil_token(IllLabel(text), start, pos, start_line, start_col))
                continue
            }
        }

        if is_msil_digit(ch) || ch == "-" {
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
                if is_msil_digit(cur) || cur == "x" || is_msil_hex_digit(cur) {
                    text = text + cur
                    pos = pos + 1
                } else {
                    break
                }
            }
            push(tokens, new_msil_token(Number(text), start, pos, start_line, start_col))
            continue
        }

        if is_msil_identifier_start(ch) {
            let start: usize = pos
            let start_line: usize = line
            let start_col: usize = col
            let mut text: utf8 = ""
            while pos < length && is_msil_identifier_part(source[pos]) {
                text = text + source[pos]
                pos = pos + 1
            }

            if is_msil_type_ref(text) {
                push(tokens, new_msil_token(TypeReference(text), start, pos, start_line, start_col))
            } else if is_msil_modifier_text(text) {
                push(tokens, new_msil_token(Identifier(text), start, pos, start_line, start_col))
            } else if is_msil_opcode(text) {
                push(tokens, new_msil_token(Opcode(text), start, pos, start_line, start_col))
            } else {
                let kw_kind: MsilTokenKind = msil_keyword_kind(text)
                push(tokens, new_msil_token(kw_kind, start, pos, start_line, start_col))
            }
            continue
        }

        return Fail(new_msil_diagnostic("存在无法识别的 MSIL 字符", pos, pos + 1))
    }

    push(tokens, eof_msil_token(pos, line, col))
    return Fine(tokens)
}

micro is_msil_digit(ch: utf8) -> bool {
    return ch >= "0" && ch <= "9"
}

micro is_msil_letter(ch: utf8) -> bool {
    return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z")
}

micro is_msil_letter_or_digit(ch: utf8) -> bool {
    return is_msil_letter(ch) || is_msil_digit(ch)
}

micro is_msil_hex_digit(ch: utf8) -> bool {
    return is_msil_digit(ch)
        || (ch >= "a" && ch <= "f")
        || (ch >= "A" && ch <= "F")
}

micro is_msil_identifier_start(ch: utf8) -> bool {
    return is_msil_letter(ch) || ch == "_" || ch == "$" || ch == "<" || ch == ">"
}

micro is_msil_identifier_part(ch: utf8) -> bool {
    return is_msil_letter_or_digit(ch) || ch == "_" || ch == "$" || ch == "<"
        || ch == ">" || ch == "." || ch == "`"
}