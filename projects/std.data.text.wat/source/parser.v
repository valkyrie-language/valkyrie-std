namespace std.data.text.wat;

micro parse_wat(source: utf8) -> WatParseResult<WatModule> {
    let tokens = lex_wat(source)?
    return parse_wat_tokens(tokens)
}

micro wat_peek(tokens: [WatToken], index: usize) -> WatToken {
    if index >= tokens.length {
        return eof_wat_token(index, 0, 0)
    }
    return tokens[index]
}

# 仅用于特定值比较（如 Punctuation("(")），非数据变体比较也安全
micro wat_expect(tokens: [WatToken], index: usize, expected: WatTokenKind) -> WatParseResult<usize> {
    let token: WatToken = wat_peek(tokens, index)
    if token.kind == expected {
        return Fine(index + 1)
    }
    return Fail(new_wat_diagnostic("期望 Token 类型不匹配", token.span.start, token.span.stop))
}

micro parse_wat_tokens(tokens: [WatToken]) -> WatParseResult<WatModule> {
    let idx1 = wat_expect(tokens, 0, Punctuation("("))?
    let idx2 = wat_expect(tokens, idx1, ModuleKeyword)?
    let mut i: usize = idx2

                    let mut module_name: utf8 = ""
                    match wat_peek(tokens, i).kind {
                        case Identifier(name):
                            module_name = name
                            i = i + 1
                        case String(name):
                            module_name = name
                            i = i + 1
                        ...
                    }

                    let mut imports: [WatImport] = []
                    let mut exports: [WatExport] = []
                    let mut functions: [WatFunction] = []
                    let mut memories: [WatMemory] = []
                    let mut tables: [WatTable] = []
                    let mut globals: [WatGlobal] = []
                    let mut data_segments: [WatDataSegment] = []
                    let mut type_definitions: [WatTypeDefinition] = []
                    let mut elem_segments: [WatElemSegment] = []
                    let mut start_function: utf8 = ""

                    while i < tokens.length {
                        match wat_peek(tokens, i).kind {
                            case EndOfFile:
                                return Fail(new_wat_diagnostic("模块缺少结束括号", wat_peek(tokens, i).span.start, wat_peek(tokens, i).span.stop))
                            case Punctuation(")"):
                                i = i + 1
                                break
                            case Punctuation("("):
                                i = i + 1
                                match wat_peek(tokens, i).kind {
                                    case FuncKeyword:
                                        let result = parse_wat_func(tokens, i)?
                                                push(functions, result.value)
                                                i = result.next_index
                                    case TypeKeyword:
                                        let result = parse_wat_type_def(tokens, i)?
                                                push(type_definitions, result.value)
                                                i = result.next_index
                                    case ImportKeyword:
                                        let result = parse_wat_import(tokens, i)?
                                                push(imports, result.value)
                                                i = result.next_index
                                    case ExportKeyword:
                                        let result = parse_wat_export(tokens, i)?
                                                push(exports, result.value)
                                                i = result.next_index
                                    case MemoryKeyword:
                                        let result = parse_wat_memory(tokens, i)?
                                                push(memories, result.value)
                                                i = result.next_index
                                    case TableKeyword:
                                        let result = parse_wat_table(tokens, i)?
                                                push(tables, result.value)
                                                i = result.next_index
                                    case GlobalKeyword:
                                        let result = parse_wat_global(tokens, i)?
                                                push(globals, result.value)
                                                i = result.next_index
                                    case DataKeyword:
                                        let result = parse_wat_data(tokens, i)?
                                                push(data_segments, result.value)
                                                i = result.next_index
                                    case ElemKeyword:
                                        let result = parse_wat_elem(tokens, i)?
                                                push(elem_segments, result.value)
                                                i = result.next_index
                                    case StartKeyword:
                                        i = i + 1
                                        match wat_peek(tokens, i).kind {
                                            case Identifier(text):
                                                start_function = text
                                                i = i + 1
                                            case Number(text):
                                                start_function = text
                                                i = i + 1
                                            ...
                                        }
                                    ...
                                }
                                i = wat_expect(tokens, i, Punctuation(")"))?
                            else:
                                i = i + 1
                        }
                    }

                    return Fine(WatModule {
                        name: module_name,
                        imports: imports,
                        exports: exports,
                        functions: functions,
                        memories: memories,
                        tables: tables,
                        globals: globals,
                        data_segments: data_segments,
                        type_definitions: type_definitions,
                        elem_segments: elem_segments,
                        start_function: start_function
                    })
}

structure WatParsed<T> {
    value: T
    next_index: usize
}

micro wat_parsed<T>(value: T, next_index: usize) -> WatParsed<T> {
    return WatParsed {
        value: value,
        next_index: next_index
    }
}

micro parse_wat_func(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatFunction>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            name = text
            i = i + 1
        case String(text):
            name = text
            i = i + 1
        ...
    }

    let mut export_name: utf8 = ""
    let mut import_module: utf8 = ""
    let mut import_name: utf8 = ""
    let mut parameters: [WatParameter] = []
    let mut results: [utf8] = []
    let mut locals: [WatLocal] = []
    let mut instructions: [WatInstruction] = []

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ExportKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                export_name = text
                                i = i + 1
                            ...
                        }
                        i = wat_expect(tokens, i, Punctuation(")"))?
                    case ImportKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                import_module = text
                                i = i + 1
                            ...
                        }
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                import_name = text
                                i = i + 1
                            ...
                        }
                        i = wat_expect(tokens, i, Punctuation(")"))?
                    case ParamKeyword:
                        match parse_wat_param(tokens, i) {
                            case Fine(result):
                                push(parameters, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                    case ResultKeyword:
                        match parse_wat_result(tokens, i) {
                            case Fine(result):
                                push(results, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                    case LocalKeyword:
                        match parse_wat_local(tokens, i) {
                            case Fine(result):
                                push(locals, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                    case TypeKeyword:
                        i = i + 1
                        i = wat_expect(tokens, i, Punctuation(")"))?
                    else:
                        match parse_wat_instruction_folded(tokens, i) {
                            case Fine(result):
                                push(instructions, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                }
            else:
                break
        }
    }

    return Fine(wat_parsed(WatFunction {
        name: name,
        parameters: parameters,
        results: results,
        locals: locals,
        instructions: instructions,
        export_name: export_name,
        import_module: import_module,
        import_name: import_name
    }, i))
}

micro parse_wat_param(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatParameter>> {
    let mut i: usize = index + 1
    let mut name: utf8 = ""
    let mut value_type: utf8 = "i32"

    match wat_peek(tokens, i).kind {
        case Identifier(text):
            name = text
            i = i + 1
        ...
    }

    match wat_peek(tokens, i).kind {
        case Identifier(id) if is_wat_value_type(id):
            value_type = id
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(WatParameter {
        name: name,
        value_type: value_type
    }, i))
}

micro parse_wat_result(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<utf8>> {
    let mut i: usize = index + 1
    let mut result_type: utf8 = "i32"

    match wat_peek(tokens, i).kind {
        case Identifier(id) if is_wat_value_type(id):
            result_type = id
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(result_type, i))
}

micro parse_wat_local(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatLocal>> {
    let mut i: usize = index + 1
    let mut name: utf8 = ""
    let mut value_type: utf8 = "i32"

    match wat_peek(tokens, i).kind {
        case Identifier(text):
            name = text
            i = i + 1
        ...
    }

    match wat_peek(tokens, i).kind {
        case Identifier(id) if is_wat_value_type(id):
            value_type = id
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(WatLocal {
        name: name,
        value_type: value_type
    }, i))
}

micro parse_wat_type_def(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatTypeDefinition>> {
    let mut i: usize = index + 1

    match wat_peek(tokens, i).kind {
        case Identifier(text):
            i = i + 1
        ...
    }

    let mut parameters: [utf8] = []
    let mut results: [utf8] = []

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ParamKeyword:
                        i = i + 1
                        while true {
                            match wat_peek(tokens, i).kind {
                                case Identifier(id) if is_wat_value_type(id):
                                    push(parameters, id)
                                    i = i + 1
                                else:
                                    break
                            }
                        }
                    case ResultKeyword:
                        i = i + 1
                        while true {
                            match wat_peek(tokens, i).kind {
                                case Identifier(id) if is_wat_value_type(id):
                                    push(results, id)
                                    i = i + 1
                                else:
                                    break
                            }
                        }
                    ...
                }
                i = wat_expect(tokens, i, Punctuation(")"))?
            else:
                break
        }
    }

    return Fine(wat_parsed(WatTypeDefinition {
        parameters: parameters,
        results: results
    }, i))
}

micro parse_wat_import(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImport>> {
    let mut i: usize = index + 1

    let mut module: utf8 = ""
    let mut field: utf8 = ""

    match wat_peek(tokens, i).kind {
        case String(text):
            module = text
            i = i + 1
        ...
    }
    match wat_peek(tokens, i).kind {
        case String(text):
            field = text
            i = i + 1
        ...
    }

    let mut descriptor: WatImportDescriptor = Func(WatFuncImportDescriptor {
        id: "",
        type_ref: "",
        parameters: [],
        results: []
    })

    match wat_expect(tokens, i, Punctuation("(")) {
        case Fine(idx2):
            i = idx2
            match parse_wat_import_descriptor(tokens, i) {
                case Fine(result):
                    descriptor = result.value
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(WatImport {
        module: module,
        field: field,
        descriptor: descriptor
    }, i))
}

micro parse_wat_import_descriptor(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    match wat_peek(tokens, index).kind {
        case FuncKeyword:
            return parse_wat_func_import_desc(tokens, index)
        case MemoryKeyword:
            return parse_wat_memory_import_desc(tokens, index)
        case TableKeyword:
            return parse_wat_table_import_desc(tokens, index)
        case GlobalKeyword:
            return parse_wat_global_import_desc(tokens, index)
        ...
    }
    return Fail(new_wat_diagnostic("未知的导入描述符类型", wat_peek(tokens, index).span.start, wat_peek(tokens, index).span.stop))
}

micro parse_wat_func_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            id = text
            i = i + 1
        ...
    }

    let mut type_ref: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            type_ref = text
            i = i + 1
        ...
    }

    let mut parameters: [WatParameter] = []
    let mut results: [utf8] = []

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ParamKeyword:
                        match parse_wat_param(tokens, i) {
                            case Fine(result):
                                push(parameters, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                    case ResultKeyword:
                        match parse_wat_result(tokens, i) {
                            case Fine(result):
                                push(results, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                    else:
                        i = wat_expect(tokens, i, Punctuation(")"))?
                }
            else:
                break
        }
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(Func(WatFuncImportDescriptor {
        id: id,
        type_ref: type_ref,
        parameters: parameters,
        results: results
    }), i))
}

micro parse_wat_memory_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            id = text
            i = i + 1
        ...
    }

    let mut min_pages: u32 = 0
    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
        ...
    }

    let mut max_pages: u32 = 0
    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(Memory(WatMemoryImportDescriptor {
        id: id,
        min_pages: min_pages,
        max_pages: max_pages
    }), i))
}

micro parse_wat_table_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            id = text
            i = i + 1
        ...
    }

    let mut element_type: utf8 = "funcref"
    match wat_peek(tokens, i).kind {
        case Identifier(id) if is_wat_value_type(id):
            element_type = id
            i = i + 1
        ...
    }

    let mut min_size: u32 = 0
    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
        ...
    }

    let mut max_size: u32 = 0
    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(Table(WatTableImportDescriptor {
        id: id,
        element_type: element_type,
        min_size: min_size,
        max_size: max_size
    }), i))
}

micro parse_wat_global_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            id = text
            i = i + 1
        ...
    }

    let mut is_mutable: bool = false
    let mut value_type: utf8 = "i32"

    match wat_peek(tokens, i).kind {
        case Punctuation("("):
            i = i + 1
            match wat_peek(tokens, i).kind {
                case MutKeyword:
                    i = i + 1
                    is_mutable = true
                ...
            }
            match wat_peek(tokens, i).kind {
                case Identifier(id) if is_wat_value_type(id):
                    value_type = id
                    i = i + 1
                ...
            }
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        case Identifier(id) if is_wat_value_type(id):
            value_type = id
            i = i + 1
        ...
    }

    i = wat_expect(tokens, i, Punctuation(")"))?

    return Fine(wat_parsed(Global(WatGlobalImportDescriptor {
        id: id,
        is_mutable: is_mutable,
        value_type: value_type
    }), i))
}

micro parse_wat_export(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatExport>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    match wat_peek(tokens, i).kind {
        case String(text):
            name = text
            i = i + 1
        ...
    }

    let mut kind: utf8 = "func"
    let mut export_index: u32 = 0

    match wat_peek(tokens, i).kind {
        case Punctuation("("):
            i = i + 1
            match wat_peek(tokens, i).kind {
                case FuncKeyword:
                    kind = "func"
                    i = i + 1
                case MemoryKeyword:
                    kind = "memory"
                    i = i + 1
                case TableKeyword:
                    kind = "table"
                    i = i + 1
                case GlobalKeyword:
                    kind = "global"
                    i = i + 1
                ...
            }
            match wat_peek(tokens, i).kind {
                case Identifier(text):
                    i = i + 1
                case Number(text):
                    i = i + 1
                ...
            }
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        ...
    }

    return Fine(wat_parsed(WatExport {
        name: name,
        kind: kind,
        index: export_index
    }, i))
}

micro parse_wat_memory(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatMemory>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            name = text
            i = i + 1
        ...
    }

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ExportKeyword | ImportKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                i = i + 1
                            ...
                        }
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                i = i + 1
                            ...
                        }
                    ...
                }
                i = wat_expect(tokens, i, Punctuation(")"))?
            else:
                break
        }
    }

    let mut initial_pages: u32 = 0
    let mut max_pages: u32 = 0

    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
            match wat_peek(tokens, i).kind {
                case Number(text):
                    i = i + 1
                ...
            }
        ...
    }

    return Fine(wat_parsed(WatMemory {
        name: name,
        initial_pages: initial_pages,
        max_pages: max_pages
    }, i))
}

micro parse_wat_table(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatTable>> {
    let mut i: usize = index + 1

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ExportKeyword | ImportKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                i = i + 1
                            ...
                        }
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                i = i + 1
                            ...
                        }
                    ...
                }
                i = wat_expect(tokens, i, Punctuation(")"))?
            else:
                break
        }
    }

    let mut element_type: utf8 = "funcref"
    match wat_peek(tokens, i).kind {
        case Identifier(id) if is_wat_value_type(id):
            element_type = id
            i = i + 1
        ...
    }

    let mut initial_size: u32 = 0
    let mut max_size: u32 = 0

    match wat_peek(tokens, i).kind {
        case Number(text):
            i = i + 1
            match wat_peek(tokens, i).kind {
                case Number(text):
                    i = i + 1
                ...
            }
        ...
    }

    return Fine(wat_parsed(WatTable {
        element_type: element_type,
        initial_size: initial_size,
        max_size: max_size
    }, i))
}

micro parse_wat_global(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatGlobal>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            name = text
            i = i + 1
        ...
    }

    let mut value_type: utf8 = "i32"
    let mut is_mutable: bool = false
    let mut init_instructions: [WatInstruction] = []

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ExportKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case String(text):
                                i = i + 1
                            ...
                        }
                        i = wat_expect(tokens, i, Punctuation(")"))?
                    case MutKeyword:
                        i = i + 1
                        is_mutable = true
                        match wat_peek(tokens, i).kind {
                            case Identifier(id) if is_wat_value_type(id):
                                value_type = id
                                i = i + 1
                            ...
                        }
                        i = wat_expect(tokens, i, Punctuation(")"))?
                    else:
                        match parse_wat_instruction_folded(tokens, i) {
                            case Fine(result):
                                push(init_instructions, result.value)
                                i = result.next_index
                            case Fail(error):
                                return Fail(error)
                        }
                }
            else:
                break
        }
    }

    return Fine(wat_parsed(WatGlobal {
        name: name,
        value_type: value_type,
        is_mutable: is_mutable,
        init_instructions: init_instructions
    }, i))
}

micro parse_wat_data(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatDataSegment>> {
    let mut i: usize = index + 1

    match wat_peek(tokens, i).kind {
        case Identifier(text):
            i = i + 1
        ...
    }

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                while true {
                    match wat_peek(tokens, i).kind {
                        case Punctuation(")"):
                            break
                        case EndOfFile:
                            break
                        else:
                            i = i + 1
                    }
                }
                i = wat_expect(tokens, i, Punctuation(")"))?
            else:
                break
        }
    }

    let mut data: utf8 = ""
    match wat_peek(tokens, i).kind {
        case String(text):
            data = text
            i = i + 1
        ...
    }

    return Fine(wat_parsed(WatDataSegment {
        memory_index: 0,
        offset_instructions: [],
        data: data
    }, i))
}

micro parse_wat_elem(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatElemSegment>> {
    let mut i: usize = index + 1

    let mut table: utf8 = ""
    match wat_peek(tokens, i).kind {
        case Identifier(text):
            table = text
            i = i + 1
        ...
    }

    let mut offset: utf8 = ""
    let mut elements: [utf8] = []

    while true {
        match wat_peek(tokens, i).kind {
            case Punctuation("("):
                i = i + 1
                match wat_peek(tokens, i).kind {
                    case ItemKeyword:
                        i = i + 1
                        while true {
                            match wat_peek(tokens, i).kind {
                                case Punctuation(")"):
                                    break
                                case EndOfFile:
                                    break
                                case Identifier(text):
                                    push(elements, text)
                                    i = i + 1
                                case Number(text):
                                    push(elements, text)
                                    i = i + 1
                                else:
                                    i = i + 1
                            }
                        }
                    case OffsetKeyword:
                        i = i + 1
                        match wat_peek(tokens, i).kind {
                            case Opcode(text):
                                offset = text
                            ...
                        }
                        i = i + 1
                        while true {
                            match wat_peek(tokens, i).kind {
                                case Punctuation(")"):
                                    break
                                case EndOfFile:
                                    break
                                else:
                                    i = i + 1
                            }
                        }
                    ...
                }
                i = wat_expect(tokens, i, Punctuation(")"))?
            else:
                break
        }
    }

    return Fine(wat_parsed(WatElemSegment {
        table: table,
        offset: offset,
        elements: elements
    }, i))
}

micro parse_wat_instruction_folded(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatInstruction>> {
    let mut i: usize = index

    match wat_peek(tokens, i).kind {
        case Opcode("i32.const") | Opcode("i64.const") | Opcode("f32.const") | Opcode("f64.const"):
            let opcode: utf8 = match wat_peek(tokens, i).kind {
                case Opcode(text):
                    text
                else:
                    ""
            }
            i = i + 1
            let mut value: utf8 = ""
            match wat_peek(tokens, i).kind {
                case Number(text):
                    value = text
                    i = i + 1
                ...
            }
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            let mut vt: utf8 = opcode[0 .. opcode.length - 6]
            return Fine(wat_parsed(Const(WatConstInstruction {
                opcode: opcode,
                value_type: vt,
                value: value
            }), i))
        case Opcode("local.get") | Opcode("local.set") | Opcode("local.tee") | Opcode("global.get") | Opcode("global.set"):
            let opcode: utf8 = match wat_peek(tokens, i).kind {
                case Opcode(text):
                    text
                else:
                    ""
            }
            i = i + 1
            let mut variable: utf8 = ""
            match wat_peek(tokens, i).kind {
                case Identifier(text):
                    variable = text
                    i = i + 1
                case Number(text):
                    variable = text
                    i = i + 1
                ...
            }
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Variable(WatVariableInstruction {
                opcode: opcode,
                variable: variable
            }), i))
        case Opcode("drop") | Opcode("select") | Opcode("return") | Opcode("nop") | Opcode("unreachable"):
            let opcode: utf8 = match wat_peek(tokens, i).kind {
                case Opcode(text):
                    text
                else:
                    ""
            }
            i = i + 1
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Simple(WatSimpleInstruction {
                opcode: opcode
            }), i))
        case Opcode(opcode):
            i = i + 1
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Generic(WatGenericInstruction {
                opcode: opcode,
                operands: []
            }), i))

        case BlockKeyword | LoopKeyword | IfKeyword:
            let opcode: utf8 = match wat_peek(tokens, i).kind {
                case BlockKeyword:
                    "block"
                case LoopKeyword:
                    "loop"
                case IfKeyword:
                    "if"
                else:
                    ""
            }
            i = i + 1
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Control(WatControlInstruction {
                opcode: opcode,
                label: "",
                results: [],
                body: [],
                else_body: [],
                targets: []
            }), i))

        else:
            match wat_expect(tokens, i, Punctuation(")")) {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Simple(WatSimpleInstruction {
                opcode: "nop"
            }), i))
    }
}