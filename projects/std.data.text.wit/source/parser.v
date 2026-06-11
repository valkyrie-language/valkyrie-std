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

micro parse_wit_tokens(tokens: [WitToken]) -> WitParseResult<WitDocument> {
    let mut i: usize = 0
    let mut package: utf8 = ""

    match wit_peek(tokens, i).kind {
        case Keyword("package"):
            i = i + 1
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    package = id
                    i = i + 1
                ...
            }
            match wit_peek(tokens, i).kind {
                case Punctuation(";"):
                    i = i + 1
                ...
            }
        ...
    }

    let mut definitions: [WitDefinition] = []

    while wit_peek(tokens, i).kind != EndOfFile {
        match wit_peek(tokens, i).kind {
            case Keyword("interface"):
                match parse_wit_interface(tokens, i) {
                    case Fine(result):
                        push(definitions, Interface(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case Keyword("world"):
                match parse_wit_world(tokens, i) {
                    case Fine(result):
                        push(definitions, World(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case Keyword("type") | Keyword("record") | Keyword("variant") | Keyword("enum") | Keyword("flags") | Keyword("resource"):
                match parse_wit_type_def(tokens, i) {
                    case Fine(result):
                        push(definitions, TypeDef(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case Keyword("use"):
                match parse_wit_use(tokens, i) {
                    case Fine(result):
                        push(definitions, Use(result.value))
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case Keyword("include"):
                i = i + 1
                let mut path: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case Identifier(id):
                        path = id
                        i = i + 1
                    ...
                }
                push(definitions, Include(WitIncludeDef { path: path }))
            else:
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
    match wit_peek(tokens, i).kind {
        case Identifier(id):
            name = id
            i = i + 1
        ...
    }

    match wit_peek(tokens, i).kind {
        case Punctuation("{"):
            i = i + 1
        ...
    }

    let mut types: [WitTypeDef] = []
    let mut functions: [WitFunctionDef] = []
    let mut resources: [WitResourceDef] = []

    while wit_peek(tokens, i).kind != EndOfFile {
        match wit_peek(tokens, i).kind {
            case Punctuation("}"):
                break
            case Keyword("type") | Keyword("record") | Keyword("variant") | Keyword("enum") | Keyword("flags"):
                match parse_wit_type_def(tokens, i) {
                    case Fine(result):
                        push(types, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case Keyword("resource"):
                i = i + 1
                let mut res_name: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case Identifier(id):
                        res_name = id
                        i = i + 1
                    ...
                }
                push(resources, WitResourceDef { name: res_name })
            case Identifier(id):
                match parse_wit_function(tokens, i) {
                    case Fine(result):
                        push(functions, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            else:
                i = i + 1
        }
    }

    match wit_peek(tokens, i).kind {
        case Punctuation("}"):
            i = i + 1
        ...
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
    match wit_peek(tokens, i).kind {
        case Identifier(id):
            name = id
            i = i + 1
        ...
    }

    match wit_peek(tokens, i).kind {
        case Punctuation("{"):
            i = i + 1
        ...
    }

    let mut imports: [WitWorldItem] = []
    let mut exports: [WitWorldItem] = []

    while wit_peek(tokens, i).kind != EndOfFile {
        match wit_peek(tokens, i).kind {
            case Punctuation("}"):
                break
            case Keyword("import"):
                i = i + 1

                let mut item_name: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case Identifier(id):
                        item_name = id
                        i = i + 1
                    ...
                }

                let mut target: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case PackageRef(id):
                        target = id
                        i = i + 1
                    case Identifier(id):
                        target = id
                        i = i + 1
                    ...
                }

                push(imports, WitWorldItem { name: item_name, target: target })

                match wit_peek(tokens, i).kind {
                    case Punctuation(";"):
                        i = i + 1
                    ...
                }
            case Keyword("export"):
                i = i + 1

                let mut item_name: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case Identifier(id):
                        item_name = id
                        i = i + 1
                    ...
                }

                let mut target: utf8 = ""
                match wit_peek(tokens, i).kind {
                    case PackageRef(id):
                        target = id
                        i = i + 1
                    case Identifier(id):
                        target = id
                        i = i + 1
                    ...
                }

                push(exports, WitWorldItem { name: item_name, target: target })

                match wit_peek(tokens, i).kind {
                    case Punctuation(";"):
                        i = i + 1
                    ...
                }
            else:
                i = i + 1
        }
    }

    match wit_peek(tokens, i).kind {
        case Punctuation("}"):
            i = i + 1
        ...
    }

    return Fine(wit_parsed(WitWorldDef {
        name: name,
        imports: imports,
        exports: exports
    }, i))
}

micro parse_wit_type_def(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitTypeDef>> {
    let mut i: usize = index

    match wit_peek(tokens, i).kind {
        case Keyword("type"):
            i = i + 1
            let mut type_name: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    type_name = id
                    i = i + 1
                ...
            }
            match wit_peek(tokens, i).kind {
                case Punctuation("="):
                    i = i + 1
                ...
            }
            let mut target: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    target = id
                    i = i + 1
                case TypeName(id):
                    target = id
                    i = i + 1
                ...
            }
            match wit_peek(tokens, i).kind {
                case Punctuation(";"):
                    i = i + 1
                ...
            }
            return Fine(wit_parsed(TypeAlias(type_name, target), i))

        case Keyword("record"):
            i = i + 1
            let mut name: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    name = id
                    i = i + 1
                ...
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("{"):
                    i = i + 1
                ...
            }

            let mut fields: [WitField] = []
            while wit_peek(tokens, i).kind != EndOfFile {
                match wit_peek(tokens, i).kind {
                    case Punctuation("}"):
                        break
                    case Identifier(field_name):
                        let mut field_type: utf8 = ""
                        i = i + 1
                        match wit_peek(tokens, i).kind {
                            case Punctuation(":"):
                                i = i + 1
                            ...
                        }
                        match wit_peek(tokens, i).kind {
                            case Identifier(id):
                                field_type = id
                                i = i + 1
                            case TypeName(id):
                                field_type = id
                                i = i + 1
                            case Punctuation(id):
                                field_type = id
                                i = i + 1
                            ...
                        }
                        push(fields, WitField { name: field_name, type_ref: field_type })
                        match wit_peek(tokens, i).kind {
                            case Punctuation(","):
                                i = i + 1
                            ...
                        }
                    else:
                        i = i + 1
                }
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("}"):
                    i = i + 1
                ...
            }
            return Fine(wit_parsed(Record(name, fields), i))

        case Keyword("variant"):
            i = i + 1
            let mut name: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    name = id
                    i = i + 1
                ...
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("{"):
                    i = i + 1
                ...
            }

            let mut cases: [WitCase] = []
            while wit_peek(tokens, i).kind != EndOfFile {
                match wit_peek(tokens, i).kind {
                    case Punctuation("}"):
                        break
                    case Identifier(case_name):
                        let mut case_type: utf8 = ""
                        i = i + 1
                        match wit_peek(tokens, i).kind {
                            case Punctuation("("):
                                i = i + 1
                                match wit_peek(tokens, i).kind {
                                    case Identifier(id):
                                        case_type = id
                                        i = i + 1
                                    case TypeName(id):
                                        case_type = id
                                        i = i + 1
                                    ...
                                }
                                match wit_peek(tokens, i).kind {
                                    case Punctuation(")"):
                                        i = i + 1
                                    ...
                                }
                            ...
                        }
                        push(cases, WitCase { name: case_name, type_ref: case_type })
                        match wit_peek(tokens, i).kind {
                            case Punctuation(","):
                                i = i + 1
                            ...
                        }
                    else:
                        i = i + 1
                }
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("}"):
                    i = i + 1
                ...
            }
            return Fine(wit_parsed(Variant(name, cases), i))

        case Keyword("enum") | Keyword("flags"):
            let is_enum: bool = match wit_peek(tokens, i).kind {
                case Keyword("enum"):
                    true
                else:
                    false
            }
            i = i + 1
            let mut name: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    name = id
                    i = i + 1
                ...
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("{"):
                    i = i + 1
                ...
            }

            let mut case_names: [utf8] = []
            while wit_peek(tokens, i).kind != EndOfFile {
                match wit_peek(tokens, i).kind {
                    case Punctuation("}"):
                        break
                    case Identifier(id):
                        push(case_names, id)
                        i = i + 1
                        match wit_peek(tokens, i).kind {
                            case Punctuation(","):
                                i = i + 1
                            ...
                        }
                    else:
                        i = i + 1
                }
            }

            match wit_peek(tokens, i).kind {
                case Punctuation("}"):
                    i = i + 1
                ...
            }

            if is_enum {
                return Fine(wit_parsed(Enum(name, case_names), i))
            } else {
                return Fine(wit_parsed(Flags(name, case_names), i))
            }

        case Keyword("resource"):
            i = i + 1
            let mut name: utf8 = ""
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    name = id
                    i = i + 1
                ...
            }
            return Fine(wit_parsed(Resource(name), i))

        else:
            return Fine(wit_parsed(TypeAlias("unknown", "u32"), i))
    }
}

micro parse_wit_function(tokens: [WitToken], index: usize) -> WitParseResult<WitParsed<WitFunctionDef>> {
    let mut i: usize = index

    let mut name: utf8 = ""
    let mut is_static: bool = false
    let mut is_constructor: bool = false

    match wit_peek(tokens, i).kind {
        case Keyword("constructor"):
            is_constructor = true
            i = i + 1
        ...
    }

    match wit_peek(tokens, i).kind {
        case Keyword("static"):
            is_static = true
            i = i + 1
        ...
    }

    match wit_peek(tokens, i).kind {
        case Identifier(id):
            name = id
            i = i + 1
        ...
    }

    let mut parameters: [WitParam] = []
    let mut results: [WitResult] = []

    match wit_peek(tokens, i).kind {
        case Punctuation("("):
            i = i + 1
            while wit_peek(tokens, i).kind != EndOfFile {
                match wit_peek(tokens, i).kind {
                    case Punctuation(")"):
                        break
                    case Identifier(param_name):
                        let mut param_type: utf8 = ""
                        i = i + 1
                        match wit_peek(tokens, i).kind {
                            case Punctuation(":"):
                                i = i + 1
                            ...
                        }
                        match wit_peek(tokens, i).kind {
                            case Identifier(id):
                                param_type = id
                                i = i + 1
                            case TypeName(id):
                                param_type = id
                                i = i + 1
                            case PackageRef(id):
                                param_type = id
                                i = i + 1
                            ...
                        }
                        push(parameters, WitParam { name: param_name, type_ref: param_type })
                        match wit_peek(tokens, i).kind {
                            case Punctuation(","):
                                i = i + 1
                            ...
                        }
                    else:
                        i = i + 1
                }
            }
            match wit_peek(tokens, i).kind {
                case Punctuation(")"):
                    i = i + 1
                ...
            }
        ...
    }

    match wit_peek(tokens, i).kind {
        case Punctuation("->"):
            i = i + 1
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    i = i + 1
                    push(results, WitResult { name: "", type_ref: id })
                case TypeName(id):
                    i = i + 1
                    push(results, WitResult { name: "", type_ref: id })
                case PackageRef(id):
                    i = i + 1
                    push(results, WitResult { name: "", type_ref: id })
                ...
            }
        ...
    }

    match wit_peek(tokens, i).kind {
        case Punctuation(";"):
            i = i + 1
        ...
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

    match wit_peek(tokens, i).kind {
        case PackageRef(id):
            path = id
            i = i + 1
        case Identifier(id):
            path = id
            i = i + 1
        ...
    }

    match wit_peek(tokens, i).kind {
        case Keyword("as"):
            i = i + 1
            match wit_peek(tokens, i).kind {
                case Identifier(id):
                    alias = id
                    i = i + 1
                ...
            }
        ...
    }

    match wit_peek(tokens, i).kind {
        case Punctuation(";"):
            i = i + 1
        ...
    }

    return Fine(wit_parsed(WitUseDef {
        path: path,
        alias: alias
    }, i))
}