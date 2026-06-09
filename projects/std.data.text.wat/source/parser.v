namespace std.data.text.wat;

micro parse_wat(source: utf8) -> WatParseResult<WatModule> {
    match lex_wat(source) {
        case Fine(tokens):
            return parse_wat_tokens(tokens)
        case Fail(error):
            return Fail(error)
    }
}

micro wat_peek(tokens: [WatToken], index: usize) -> WatToken {
    if index >= tokens.length {
        let length: usize = tokens.length
        return eof_wat_token(index, 0, 0)
    }
    return tokens[index]
}

micro wat_check_kind(tokens: [WatToken], index: usize, kind: WatTokenKind) -> bool {
    return wat_peek(tokens, index).kind == kind
}

micro wat_check_text(tokens: [WatToken], index: usize, kind: WatTokenKind, text: utf8) -> bool {
    let token: WatToken = wat_peek(tokens, index)
    return token.kind == kind && token.text == text
}

micro wat_expect(tokens: [WatToken], index: usize, kind: WatTokenKind, text: utf8) -> WatParseResult<usize> {
    let token: WatToken = wat_peek(tokens, index)
    if token.kind == kind && token.text == text {
        return Fine(index + 1)
    }
    return Fail(new_wat_diagnostic("期望 Token 类型不匹配", token.span.start, token.span.stop))
}

micro parse_wat_tokens(tokens: [WatToken]) -> WatParseResult<WatModule> {
    match wat_expect(tokens, 0, Punctuation, "(") {
        case Fine(idx1):
            match wat_expect(tokens, idx1, Keyword, "module") {
                case Fine(idx2):
                    let mut i: usize = idx2

                    let mut module_name: utf8 = ""
                    if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, String) {
                        module_name = wat_peek(tokens, i).text
                        i = i + 1
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
                        let tk: WatToken = wat_peek(tokens, i)
                        if tk.kind == EndOfFile {
                            return Fail(new_wat_diagnostic("模块缺少结束括号", tk.span.start, tk.span.stop))
                        }

                        if tk.kind == Punctuation && tk.text == ")" {
                            i = i + 1
                            break
                        }

                        if tk.kind == Punctuation && tk.text == "(" {
                            i = i + 1
                            let inner: WatToken = wat_peek(tokens, i)

                            if inner.kind == Keyword && inner.text == "func" {
                            match parse_wat_func(tokens, i) {
                                case Fine(result):
                                    push(functions, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "type" {
                            match parse_wat_type_def(tokens, i) {
                                case Fine(result):
                                    push(type_definitions, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "import" {
                            match parse_wat_import(tokens, i) {
                                case Fine(result):
                                    push(imports, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "export" {
                            match parse_wat_export(tokens, i) {
                                case Fine(result):
                                    push(exports, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "memory" {
                            match parse_wat_memory(tokens, i) {
                                case Fine(result):
                                    push(memories, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "table" {
                            match parse_wat_table(tokens, i) {
                                case Fine(result):
                                    push(tables, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "global" {
                            match parse_wat_global(tokens, i) {
                                case Fine(result):
                                    push(globals, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "data" {
                            match parse_wat_data(tokens, i) {
                                case Fine(result):
                                    push(data_segments, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "elem" {
                            match parse_wat_elem(tokens, i) {
                                case Fine(result):
                                    push(elem_segments, result.value)
                                    i = result.next_index
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if inner.kind == Keyword && inner.text == "start" {
                            i = i + 1
                            if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, Number) {
                                start_function = wat_peek(tokens, i).text
                                i = i + 1
                            }
                        }

                            match wat_expect(tokens, i, Punctuation, ")") {
                                case Fine(new_i):
                                    i = new_i
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else {
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
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
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
    if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, String) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut export_name: utf8 = ""
    let mut import_module: utf8 = ""
    let mut import_name: utf8 = ""
    let mut parameters: [WatParameter] = []
    let mut results: [utf8] = []
    let mut locals: [WatLocal] = []
    let mut instructions: [WatInstruction] = []

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)

        if inner.kind == Keyword && inner.text == "export" {
            i = i + 1
            if wat_check_kind(tokens, i, String) {
                export_name = wat_peek(tokens, i).text
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "import" {
            i = i + 1
            if wat_check_kind(tokens, i, String) {
                import_module = wat_peek(tokens, i).text
                i = i + 1
            }
            if wat_check_kind(tokens, i, String) {
                import_name = wat_peek(tokens, i).text
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "param" {
            match parse_wat_param(tokens, i) {
                case Fine(result):
                    push(parameters, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "result" {
            match parse_wat_result(tokens, i) {
                case Fine(result):
                    push(results, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "local" {
            match parse_wat_local(tokens, i) {
                case Fine(result):
                    push(locals, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "type" {
            i = i + 1
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        } else {
            match parse_wat_instruction_folded(tokens, i) {
                case Fine(result):
                    push(instructions, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
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

    if wat_check_kind(tokens, i, Identifier) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    if wat_check_kind(tokens, i, ValueType) {
        value_type = wat_peek(tokens, i).text
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(WatParameter {
        name: name,
        value_type: value_type
    }, i))
}

micro parse_wat_result(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<utf8>> {
    let mut i: usize = index + 1
    let mut result_type: utf8 = "i32"

    if wat_check_kind(tokens, i, ValueType) {
        result_type = wat_peek(tokens, i).text
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(result_type, i))
}

micro parse_wat_local(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatLocal>> {
    let mut i: usize = index + 1
    let mut name: utf8 = ""
    let mut value_type: utf8 = "i32"

    if wat_check_kind(tokens, i, Identifier) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    if wat_check_kind(tokens, i, ValueType) {
        value_type = wat_peek(tokens, i).text
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(WatLocal {
        name: name,
        value_type: value_type
    }, i))
}

micro parse_wat_type_def(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatTypeDefinition>> {
    let mut i: usize = index + 1

    if wat_check_kind(tokens, i, Identifier) {
        i = i + 1
    }

    let mut parameters: [utf8] = []
    let mut results: [utf8] = []

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)
        if inner.kind == Keyword && inner.text == "param" {
            i = i + 1
            while wat_check_kind(tokens, i, ValueType) {
                push(parameters, wat_peek(tokens, i).text)
                i = i + 1
            }
        } else if inner.kind == Keyword && inner.text == "result" {
            i = i + 1
            while wat_check_kind(tokens, i, ValueType) {
                push(results, wat_peek(tokens, i).text)
                i = i + 1
            }
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
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

    if wat_check_kind(tokens, i, String) {
        module = wat_peek(tokens, i).text
        i = i + 1
    }
    if wat_check_kind(tokens, i, String) {
        field = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut descriptor: WatImportDescriptor = Func(WatFuncImportDescriptor {
        id: "",
        type_ref: "",
        parameters: [],
        results: []
    })

    match wat_expect(tokens, i, Punctuation, "(") {
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

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(WatImport {
        module: module,
        field: field,
        descriptor: descriptor
    }, i))
}

micro parse_wat_import_descriptor(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let token: WatToken = wat_peek(tokens, index)
    if token.kind == Keyword && token.text == "func" {
        return parse_wat_func_import_desc(tokens, index)
    }
    if token.kind == Keyword && token.text == "memory" {
        return parse_wat_memory_import_desc(tokens, index)
    }
    if token.kind == Keyword && token.text == "table" {
        return parse_wat_table_import_desc(tokens, index)
    }
    if token.kind == Keyword && token.text == "global" {
        return parse_wat_global_import_desc(tokens, index)
    }
    return Fail(new_wat_diagnostic("未知的导入描述符类型", token.span.start, token.span.stop))
}

micro parse_wat_func_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    if wat_check_kind(tokens, i, Identifier) {
        id = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut type_ref: utf8 = ""
    if wat_check_kind(tokens, i, Identifier) {
        type_ref = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut parameters: [WatParameter] = []
    let mut results: [utf8] = []

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)

        if inner.kind == Keyword && inner.text == "param" {
            match parse_wat_param(tokens, i) {
                case Fine(result):
                    push(parameters, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "result" {
            match parse_wat_result(tokens, i) {
                case Fine(result):
                    push(results, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
        } else {
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        }
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

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
    if wat_check_kind(tokens, i, Identifier) {
        id = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut min_pages: u32 = 0
    if wat_check_kind(tokens, i, Number) {
        min_pages = 0
        i = i + 1
    }

    let mut max_pages: u32 = 0
    if wat_check_kind(tokens, i, Number) {
        max_pages = 0
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(Memory(WatMemoryImportDescriptor {
        id: id,
        min_pages: min_pages,
        max_pages: max_pages
    }), i))
}

micro parse_wat_table_import_desc(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatImportDescriptor>> {
    let mut i: usize = index + 1

    let mut id: utf8 = ""
    if wat_check_kind(tokens, i, Identifier) {
        id = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut element_type: utf8 = "funcref"
    if wat_check_kind(tokens, i, ValueType) {
        element_type = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut min_size: u32 = 0
    if wat_check_kind(tokens, i, Number) {
        i = i + 1
    }

    let mut max_size: u32 = 0
    if wat_check_kind(tokens, i, Number) {
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

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
    if wat_check_kind(tokens, i, Identifier) {
        id = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut is_mutable: bool = false
    let mut value_type: utf8 = "i32"

    if wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        if wat_check_text(tokens, i, Keyword, "mut") {
            i = i + 1
            is_mutable = true
        }
        if wat_check_kind(tokens, i, ValueType) {
            value_type = wat_peek(tokens, i).text
            i = i + 1
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
    } else if wat_check_kind(tokens, i, ValueType) {
        value_type = wat_peek(tokens, i).text
        i = i + 1
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }

    return Fine(wat_parsed(Global(WatGlobalImportDescriptor {
        id: id,
        is_mutable: is_mutable,
        value_type: value_type
    }), i))
}

micro parse_wat_export(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatExport>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    if wat_check_kind(tokens, i, String) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut kind: utf8 = "func"
    let mut export_index: u32 = 0

    if wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)
        if inner.kind == Keyword {
            kind = inner.text
            i = i + 1
            if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, Number) {
                i = i + 1
            }
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
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
    if wat_check_kind(tokens, i, Identifier) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)
        if inner.kind == Keyword {
            i = i + 1
            if wat_check_kind(tokens, i, String) {
                i = i + 1
            }
            if wat_check_kind(tokens, i, String) {
                i = i + 1
            }
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
    }

    let mut initial_pages: u32 = 0
    let mut max_pages: u32 = 0

    if wat_check_kind(tokens, i, Number) {
        i = i + 1
        if wat_check_kind(tokens, i, Number) {
            i = i + 1
        }
    }

    return Fine(wat_parsed(WatMemory {
        name: name,
        initial_pages: initial_pages,
        max_pages: max_pages
    }, i))
}

micro parse_wat_table(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatTable>> {
    let mut i: usize = index + 1

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)
        if inner.kind == Keyword {
            i = i + 1
            if wat_check_kind(tokens, i, String) {
                i = i + 1
            }
            if wat_check_kind(tokens, i, String) {
                i = i + 1
            }
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
    }

    let mut element_type: utf8 = "funcref"
    if wat_check_kind(tokens, i, ValueType) {
        element_type = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut initial_size: u32 = 0
    let mut max_size: u32 = 0

    if wat_check_kind(tokens, i, Number) {
        i = i + 1
        if wat_check_kind(tokens, i, Number) {
            i = i + 1
        }
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
    if wat_check_kind(tokens, i, Identifier) {
        name = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut value_type: utf8 = "i32"
    let mut is_mutable: bool = false
    let mut init_instructions: [WatInstruction] = []

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)

        if inner.kind == Keyword && inner.text == "export" {
            i = i + 1
            if wat_check_kind(tokens, i, String) {
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        } else if inner.kind == Keyword && inner.text == "mut" {
            i = i + 1
            is_mutable = true
            if wat_check_kind(tokens, i, ValueType) {
                value_type = wat_peek(tokens, i).text
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
        } else {
            match parse_wat_instruction_folded(tokens, i) {
                case Fine(result):
                    push(init_instructions, result.value)
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
            }
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

    if wat_check_kind(tokens, i, Identifier) {
        i = i + 1
    }

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        while !wat_check_text(tokens, i, Punctuation, ")") && wat_peek(tokens, i).kind != EndOfFile {
            i = i + 1
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
    }

    let mut data: utf8 = ""
    if wat_check_kind(tokens, i, String) {
        data = wat_peek(tokens, i).text
        i = i + 1
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
    if wat_check_kind(tokens, i, Identifier) {
        table = wat_peek(tokens, i).text
        i = i + 1
    }

    let mut offset: utf8 = ""
    let mut elements: [utf8] = []

    while wat_check_text(tokens, i, Punctuation, "(") {
        i = i + 1
        let inner: WatToken = wat_peek(tokens, i)
        if inner.kind == Keyword && inner.text == "item" {
            i = i + 1
            while !wat_check_text(tokens, i, Punctuation, ")") && wat_peek(tokens, i).kind != EndOfFile {
                if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, Number) {
                    push(elements, wat_peek(tokens, i).text)
                }
                i = i + 1
            }
        } else if inner.kind == Keyword && inner.text == "offset" {
            i = i + 1
            if wat_check_kind(tokens, i, Opcode) {
                offset = wat_peek(tokens, i).text
            }
            i = i + 1
            while !wat_check_text(tokens, i, Punctuation, ")") && wat_peek(tokens, i).kind != EndOfFile {
                i = i + 1
            }
        }
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
    }

    return Fine(wat_parsed(WatElemSegment {
        table: table,
        offset: offset,
        elements: elements
    }, i))
}

micro parse_wat_instruction_folded(tokens: [WatToken], index: usize) -> WatParseResult<WatParsed<WatInstruction>> {
    let token: WatToken = wat_peek(tokens, index)
    let mut i: usize = index

    if token.kind == Opcode {
        i = i + 1
        let opcode: utf8 = token.text

        if is_wat_const_opcode(opcode) {
            let mut value: utf8 = ""
            if wat_check_kind(tokens, i, Number) {
                value = wat_peek(tokens, i).text
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Const(WatConstInstruction {
                opcode: opcode,
                value_type: wat_get_const_type(opcode),
                value: value
            }), i))
        }

        if is_wat_variable_opcode(opcode) {
            let mut variable: utf8 = ""
            if wat_check_kind(tokens, i, Identifier) || wat_check_kind(tokens, i, Number) {
                variable = wat_peek(tokens, i).text
                i = i + 1
            }
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Variable(WatVariableInstruction {
                opcode: opcode,
                variable: variable
            }), i))
        }

        if is_wat_simple_opcode(opcode) {
            match wat_expect(tokens, i, Punctuation, ")") {
                case Fine(new_i): i = new_i
                case Fail(error): return Fail(error)
            }
            return Fine(wat_parsed(Simple(WatSimpleInstruction {
                opcode: opcode
            }), i))
        }

        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
        return Fine(wat_parsed(Generic(WatGenericInstruction {
            opcode: opcode,
            operands: []
        }), i))
    }

    if token.kind == Keyword && (token.text == "block" || token.text == "loop" || token.text == "if") {
        i = i + 1
        match wat_expect(tokens, i, Punctuation, ")") {
            case Fine(new_i): i = new_i
            case Fail(error): return Fail(error)
        }
        return Fine(wat_parsed(Control(WatControlInstruction {
            opcode: token.text,
            label: "",
            results: [],
            body: [],
            else_body: [],
            targets: []
        }), i))
    }

    match wat_expect(tokens, i, Punctuation, ")") {
        case Fine(new_i): i = new_i
        case Fail(error): return Fail(error)
    }
    return Fine(wat_parsed(Simple(WatSimpleInstruction {
        opcode: "nop"
    }), i))
}

micro is_wat_const_opcode(opcode: utf8) -> bool {
    return opcode == "i32.const" || opcode == "i64.const" || opcode == "f32.const" || opcode == "f64.const"
}

micro is_wat_variable_opcode(opcode: utf8) -> bool {
    return opcode == "local.get" || opcode == "local.set" || opcode == "local.tee"
        || opcode == "global.get" || opcode == "global.set"
}

micro is_wat_simple_opcode(opcode: utf8) -> bool {
    return opcode == "drop" || opcode == "select" || opcode == "return"
        || opcode == "nop" || opcode == "unreachable"
}

micro wat_get_const_type(opcode: utf8) -> utf8 {
    if opcode == "i32.const" {
        return "i32"
    }
    if opcode == "i64.const" {
        return "i64"
    }
    if opcode == "f32.const" {
        return "f32"
    }
    if opcode == "f64.const" {
        return "f64"
    }
    return "i32"
}
