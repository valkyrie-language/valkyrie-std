namespace std.data.text.wit;

micro parse_wit(source: utf8) -> WitParseResult<WitDocument> {
    match lex_wit(source) {
        case Fine(tokens):
            return parse_wit_tokens(tokens)
        case Fail(error):
            return Fail(error)
    }
}

structure WitParsed<T> {
    value: T
    next_index: usize
}

micro wit_parsed<T>(value: T, next_index: usize) -> WitParsed<T> {
    return WitParsed {
        value: value,
        next_index: next_index
    }
}

micro wit_peek(tokens: [WitToken], index: usize) -> WitToken {
    if index >= tokens.length {
        return eof_wit_token(index, 0, 0)
    }
    return tokens[index]
}

micro wit_check_kind(tokens: [WitToken], index: usize, kind: WitTokenKind) -> bool {
    return wit_peek(tokens, index).kind == kind
}

micro wit_check_text(tokens: [WitToken], index: usize, kind: WitTokenKind, text: utf8) -> bool {
    let token: WitToken = wit_peek(tokens, index)
    return token.kind == kind && token.text == text
}

micro parse_wit_tokens(tokens: [WitToken]) -> WitParseResult<WitDocument> {
    let mut i: usize = 0
    let mut package: utf8 = ""

    if wit_check_text(tokens, i, Keyword, "package") {
        i = i + 1
        if wit_check_kind(tokens, i, Identifier) {
            package = wit_peek(tokens, i).text
            i = i + 1
        }
        if wit_check_text(tokens, i, Punctuation, ";") {
            i = i + 1
        }
    }

    let mut definitions: [WitDefinition] = []

    while wit_peek(tokens, i).kind != EndOfFile {
        let token: WitToken = wit_peek(tokens, i)

        if token.kind == Keyword {
            if token.text == "interface" {
                match parse_wit_interface(tokens, i) {
                    case Fine(result):
                        push(definitions, Interface(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == "world" {
                match parse_wit_world(tokens, i) {
                    case Fine(result):
                        push(definitions, World(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == "type" || token.text == "record" || token.text == "variant"
                || token.text == "enum" || token.text == "flags" || token.text == "resource" {
                match parse_wit_type_def(tokens, i) {
                    case Fine(result):
                        push(definitions, TypeDef(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == "use" {
                match parse_wit_use(tokens, i) {
                    case Fine(result):
                        push(definitions, Use(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == "include" {
                i = i + 1
                let mut path: utf8 = ""
                if wit_check_kind(tokens, i, Identifier) {
                    path = wit_peek(tokens, i).text
                    i = i + 1
                }
                push(definitions, Include(WitIncludeDef { path: path }))
            } else {
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(WitDocument {
        package: package,
        definitions: definitions
    })
}

micro parse_wit_interface(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitInterfaceDef>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    if wit_check_kind(tokens, i, Identifier) {
        name = wit_peek(tokens, i).text
        i = i + 1
    }

    if wit_check_text(tokens, i, Punctuation, "{") {
        i = i + 1
    }

    let mut types: [WitTypeDef] = []
    let mut functions: [WitFunctionDef] = []
    let mut resources: [WitResourceDef] = []

    while wit_peek(tokens, i).kind != EndOfFile && !wit_check_text(tokens, i, Punctuation, "}") {
        let token: WitToken = wit_peek(tokens, i)

        if token.kind == Keyword && (token.text == "type" || token.text == "record"
            || token.text == "variant" || token.text == "enum" || token.text == "flags") {
            match parse_wit_type_def(tokens, i) {
                case Fine(result):
                    push(types, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else if token.kind == Keyword && token.text == "resource" {
            i = i + 1
            let mut res_name: utf8 = ""
            if wit_check_kind(tokens, i, Identifier) {
                res_name = wit_peek(tokens, i).text
                i = i + 1
            }
            push(resources, WitResourceDef { name: res_name })
        } else if token.kind == Identifier {
            match parse_wit_function(tokens, i) {
                case Fine(result):
                    push(functions, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else {
            i = i + 1
        }
    }

    if wit_check_text(tokens, i, Punctuation, "}") {
        i = i + 1
    }

    return Fine(wit_parsed(WitInterfaceDef {
        name: name,
        types: types,
        functions: functions,
        resources: resources
    }, i))
}

micro parse_wit_world(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitWorldDef>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    if wit_check_kind(tokens, i, Identifier) {
        name = wit_peek(tokens, i).text
        i = i + 1
    }

    if wit_check_text(tokens, i, Punctuation, "{") {
        i = i + 1
    }

    let mut imports: [WitWorldItem] = []
    let mut exports: [WitWorldItem] = []

    while wit_peek(tokens, i).kind != EndOfFile && !wit_check_text(tokens, i, Punctuation, "}") {
        let token: WitToken = wit_peek(tokens, i)

        if token.kind == Keyword && (token.text == "import" || token.text == "export") {
            let is_import: bool = token.text == "import"
            i = i + 1

            let mut item_name: utf8 = ""
            if wit_check_kind(tokens, i, Identifier) {
                item_name = wit_peek(tokens, i).text
                i = i + 1
            }

            let mut target: utf8 = ""
            if wit_check_kind(tokens, i, PackageRef) || wit_check_kind(tokens, i, Identifier) {
                target = wit_peek(tokens, i).text
                i = i + 1
            }

            let item: WitWorldItem = WitWorldItem { name: item_name, target: target }
            if is_import {
                push(imports, item)
            } else {
                push(exports, item)
            }

            if wit_check_text(tokens, i, Punctuation, ";") {
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    if wit_check_text(tokens, i, Punctuation, "}") {
        i = i + 1
    }

    return Fine(wit_parsed(WitWorldDef {
        name: name,
        imports: imports,
        exports: exports
    }, i))
}

micro parse_wit_type_def(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitTypeDef>> {
    let mut i: usize = index
    let token: WitToken = wit_peek(tokens, i)

    if token.kind == Keyword && token.text == "type" {
        i = i + 1
        let mut type_name: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) {
            type_name = wit_peek(tokens, i).text
            i = i + 1
        }
        if wit_check_text(tokens, i, Punctuation, "=") {
            i = i + 1
        }
        let mut target: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) || wit_check_kind(tokens, i, TypeName) {
            target = wit_peek(tokens, i).text
            i = i + 1
        }
        if wit_check_text(tokens, i, Punctuation, ";") {
            i = i + 1
        }
        return Fine(wit_parsed(TypeAlias(type_name, target), i))
    }

    if token.kind == Keyword && token.text == "record" {
        i = i + 1
        let mut name: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) {
            name = wit_peek(tokens, i).text
            i = i + 1
        }

        if wit_check_text(tokens, i, Punctuation, "{") {
            i = i + 1
        }

        let mut fields: [WitField] = []
        while !wit_check_text(tokens, i, Punctuation, "}") && wit_peek(tokens, i).kind != EndOfFile {
            let field_name: utf8 = wit_peek(tokens, i).text
            let mut field_type: utf8 = ""
            i = i + 1
            if wit_check_text(tokens, i, Punctuation, ":") {
                i = i + 1
            }
            if wit_check_kind(tokens, i, Identifier) || wit_check_kind(tokens, i, TypeName) || wit_check_kind(tokens, i, Punctuation) {
                field_type = wit_peek(tokens, i).text
                i = i + 1
            }
            push(fields, WitField { name: field_name, type_ref: field_type })
            if wit_check_text(tokens, i, Punctuation, ",") {
                i = i + 1
            }
        }

        if wit_check_text(tokens, i, Punctuation, "}") {
            i = i + 1
        }
        return Fine(wit_parsed(Record(name, fields), i))
    }

    if token.kind == Keyword && token.text == "variant" {
        i = i + 1
        let mut name: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) {
            name = wit_peek(tokens, i).text
            i = i + 1
        }

        if wit_check_text(tokens, i, Punctuation, "{") {
            i = i + 1
        }

        let mut cases: [WitCase] = []
        while !wit_check_text(tokens, i, Punctuation, "}") && wit_peek(tokens, i).kind != EndOfFile {
            let case_name: utf8 = wit_peek(tokens, i).text
            let mut case_type: utf8 = ""
            i = i + 1
            if wit_check_text(tokens, i, Punctuation, "(") {
                i = i + 1
                if wit_check_kind(tokens, i, Identifier) || wit_check_kind(tokens, i, TypeName) {
                    case_type = wit_peek(tokens, i).text
                    i = i + 1
                }
                if wit_check_text(tokens, i, Punctuation, ")") {
                    i = i + 1
                }
            }
            push(cases, WitCase { name: case_name, type_ref: case_type })
            if wit_check_text(tokens, i, Punctuation, ",") {
                i = i + 1
            }
        }

        if wit_check_text(tokens, i, Punctuation, "}") {
            i = i + 1
        }
        return Fine(wit_parsed(Variant(name, cases), i))
    }

    if token.kind == Keyword && (token.text == "enum" || token.text == "flags") {
        let is_enum: bool = token.text == "enum"
        i = i + 1
        let mut name: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) {
            name = wit_peek(tokens, i).text
            i = i + 1
        }

        if wit_check_text(tokens, i, Punctuation, "{") {
            i = i + 1
        }

        let mut case_names: [utf8] = []
        while !wit_check_text(tokens, i, Punctuation, "}") && wit_peek(tokens, i).kind != EndOfFile {
            if wit_check_kind(tokens, i, Identifier) {
                push(case_names, wit_peek(tokens, i).text)
            }
            i = i + 1
            if wit_check_text(tokens, i, Punctuation, ",") {
                i = i + 1
            }
        }

        if wit_check_text(tokens, i, Punctuation, "}") {
            i = i + 1
        }

        if is_enum {
            return Fine(wit_parsed(Enum(name, case_names), i))
        } else {
            return Fine(wit_parsed(Flags(name, case_names), i))
        }
    }

    if token.kind == Keyword && token.text == "resource" {
        i = i + 1
        let mut name: utf8 = ""
        if wit_check_kind(tokens, i, Identifier) {
            name = wit_peek(tokens, i).text
            i = i + 1
        }
        return Fine(wit_parsed(Resource(name), i))
    }

    return Fine(wit_parsed(TypeAlias("unknown", "u32"), i))
}

micro parse_wit_function(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitFunctionDef>> {
    let mut i: usize = index

    let mut name: utf8 = ""
    let mut is_static: bool = false
    let mut is_constructor: bool = false

    if wit_check_text(tokens, i, Keyword, "constructor") {
        is_constructor = true
        i = i + 1
    }

    if wit_check_text(tokens, i, Keyword, "static") {
        is_static = true
        i = i + 1
    }

    if wit_check_kind(tokens, i, Identifier) {
        name = wit_peek(tokens, i).text
        i = i + 1
    }

    let mut parameters: [WitParam] = []
    let mut results: [WitResult] = []

    if wit_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        while !wit_check_text(tokens, i, Punctuation, ")") && wit_peek(tokens, i).kind != EndOfFile {
            let param_name: utf8 = wit_peek(tokens, i).text
            let mut param_type: utf8 = ""
            i = i + 1
            if wit_check_text(tokens, i, Punctuation, ":") {
                i = i + 1
            }
            if wit_check_kind(tokens, i, Identifier) || wit_check_kind(tokens, i, TypeName) || wit_check_kind(tokens, i, PackageRef) {
                param_type = wit_peek(tokens, i).text
                i = i + 1
            }
            push(parameters, WitParam { name: param_name, type_ref: param_type })
            if wit_check_text(tokens, i, Punctuation, ",") {
                i = i + 1
            }
        }
        if wit_check_text(tokens, i, Punctuation, ")") {
            i = i + 1
        }
    }

    if wit_check_text(tokens, i, Punctuation, "->") {
        i = i + 1
        if wit_check_kind(tokens, i, Identifier) || wit_check_kind(tokens, i, TypeName) || wit_check_kind(tokens, i, PackageRef) {
            let result_type: utf8 = wit_peek(tokens, i).text
            i = i + 1
            push(results, WitResult { name: "", type_ref: result_type })
        }
    }

    if wit_check_text(tokens, i, Punctuation, ";") {
        i = i + 1
    }

    return Fine(wit_parsed(WitFunctionDef {
        name: name,
        is_static: is_static,
        is_constructor: is_constructor,
        parameters: parameters,
        results: results
    }, i))
}

micro parse_wit_use(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitUseDef>> {
    let mut i: usize = index + 1

    let mut path: utf8 = ""
    let mut alias: utf8 = ""

    if wit_check_kind(tokens, i, PackageRef) || wit_check_kind(tokens, i, Identifier) {
        path = wit_peek(tokens, i).text
        i = i + 1
    }

    if wit_check_text(tokens, i, Keyword, "as") {
        i = i + 1
        if wit_check_kind(tokens, i, Identifier) {
            alias = wit_peek(tokens, i).text
            i = i + 1
        }
    }

    if wit_check_text(tokens, i, Punctuation, ";") {
        i = i + 1
    }

    return Fine(wit_parsed(WitUseDef {
        path: path,
        alias: alias
    }, i))
}
