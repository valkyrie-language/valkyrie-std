namespace std.data.text.msil;

micro parse_msil(source: utf8) -> MsilParseResult<MsilAssembly> {
    match lex_msil(source) {
        case Fine(tokens):
            return parse_msil_tokens(tokens)
        case Fail(error):
            return Fail(error)
    }
}

micro msil_peek(tokens: [MsilToken], index: usize) -> MsilToken {
    if index >= tokens.length {
        return eof_msil_token(index, 0, 0)
    }
    return tokens[index]
}

micro msil_check_kind(tokens: [MsilToken], index: usize, kind: MsilTokenKind) -> bool {
    return msil_peek(tokens, index).kind == kind
}

micro msil_check_text(tokens: [MsilToken], index: usize, kind: MsilTokenKind, text: utf8) -> bool {
    let token: MsilToken = msil_peek(tokens, index)
    return token.kind == kind && token.text == text
}

micro msil_expect(tokens: [MsilToken], index: usize, kind: MsilTokenKind, text: utf8) -> MsilParseResult<usize> {
    let token: MsilToken = msil_peek(tokens, index)
    if token.kind == kind && token.text == text {
        return Fine(index + 1)
    }
    return Fail(new_msil_diagnostic("期望 Token 类型不匹配", token.span.start, token.span.stop))
}

structure MsilParsed<T> {
    value: T
    next_index: usize
}

micro msil_parsed<T>(value: T, next_index: usize) -> MsilParsed<T> {
    return MsilParsed {
        value: value,
        next_index: next_index
    }
}

micro parse_msil_tokens(tokens: [MsilToken]) -> MsilParseResult<MsilAssembly> {
    let mut i: usize = 0
    let mut assembly_decl: MsilAssemblyDecl = MsilAssemblyDecl {
        name: "",
        custom_attrs: [],
        hash_algorithm: 0,
        version: "",
        locale: "",
        public_key: ""
    }
    let mut module_decl: MsilModuleDecl = MsilModuleDecl {
        name: "",
        custom_attrs: []
    }
    let mut types: [MsilTypeDef] = []
    let mut method_impls: [MsilMethodImpl] = []
    let mut security_decls: [MsilSecurityDecl] = []

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == EndOfFile {
            break
        }

        if token.kind == Directive {
            if token.text == ".assembly" {
                match parse_msil_assembly(tokens, i) {
                    case Fine(result):
                        assembly_decl = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".module" {
                match parse_msil_module(tokens, i) {
                    case Fine(result):
                        module_decl = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".class" {
                match parse_msil_type(tokens, i) {
                    case Fine(result):
                        push(types, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".override" || token.text == ".method" {
                match parse_msil_method_impl(tokens, i) {
                    case Fine(result):
                        push(method_impls, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".permission" || token.text == ".permissionset" {
                match parse_msil_security(tokens, i) {
                    case Fine(result):
                        push(security_decls, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else {
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(MsilAssembly {
        assembly_decl: assembly_decl,
        module_decl: module_decl,
        types: types,
        method_impls: method_impls,
        security_decls: security_decls
    })
}

micro parse_msil_assembly(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilAssemblyDecl>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut custom_attrs: [MsilCustomAttribute] = []
    let mut hash_algorithm: u32 = 0
    let mut version: utf8 = ""
    let mut locale: utf8 = ""
    let mut public_key: utf8 = ""

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == "{" {
            i = i + 1
        } else if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        } else if token.kind == Directive && token.text == ".hash" {
            i = i + 1
            if msil_check_kind(tokens, i, Number) {
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".ver" {
            i = i + 1
            if msil_check_kind(tokens, i, String) {
                version = msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".locale" {
            i = i + 1
            if msil_check_kind(tokens, i, String) {
                locale = msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".publickey" {
            i = i + 1
            while i < tokens.length && msil_peek(tokens, i).kind != Punctuation && msil_peek(tokens, i).kind != Directive {
                public_key = public_key + msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".custom" {
            match parse_msil_custom_attr(tokens, i) {
                case Fine(result):
                    push(custom_attrs, result.value)
                    i = result.next_index
                case Fail(error):
                    i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilAssemblyDecl {
        name: name,
        custom_attrs: custom_attrs,
        hash_algorithm: hash_algorithm,
        version: version,
        locale: locale,
        public_key: public_key
    }, i))
}

micro parse_msil_module(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilModuleDecl>> {
    let mut i: usize = index + 1

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut custom_attrs: [MsilCustomAttribute] = []

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == "{" {
            i = i + 1
            continue
        }
        if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        }
        if token.kind == Directive && token.text == ".custom" {
            match parse_msil_custom_attr(tokens, i) {
                case Fine(result):
                    push(custom_attrs, result.value)
                    i = result.next_index
                case Fail(error):
                    i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilModuleDecl {
        name: name,
        custom_attrs: custom_attrs
    }, i))
}

micro parse_msil_custom_attr(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilCustomAttribute>> {
    let mut i: usize = index + 1

    let mut ctor_ref: utf8 = ""
    let mut args: [utf8] = []

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Identifier || token.kind == TypeReference {
            if ctor_ref == "" {
                ctor_ref = token.text
            }
            i = i + 1
        } else if token.kind == String {
            push(args, token.text)
            i = i + 1
        } else if token.kind == Number {
            push(args, token.text)
            i = i + 1
        } else {
            i = i + 1
            break
        }
    }

    return Fine(msil_parsed(MsilCustomAttribute {
        ctor_ref: ctor_ref,
        args: args
    }, i))
}

micro parse_msil_type(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilTypeDef>> {
    let mut i: usize = index + 1

    let mut modifiers: [utf8] = []
    while msil_peek(tokens, i).kind == Modifier {
        push(modifiers, msil_peek(tokens, i).text)
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut extends: utf8 = ""
    if msil_check_text(tokens, i, Keyword, "extends") {
        i = i + 1
        if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
            extends = msil_peek(tokens, i).text
            i = i + 1
        }
    }

    let mut implements: [utf8] = []
    if msil_check_text(tokens, i, Keyword, "implements") {
        i = i + 1
        while msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
            push(implements, msil_peek(tokens, i).text)
            i = i + 1
            if msil_check_text(tokens, i, Punctuation, ",") {
                i = i + 1
            }
        }
    }

    let mut class_attrs: [MsilClassAttr] = []
    let mut fields: [MsilFieldDef] = []
    let mut methods: [MsilMethodDef] = []
    let mut properties: [MsilPropertyDef] = []
    let mut events: [MsilEventDef] = []

    match msil_expect(tokens, i, Punctuation, "{") {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        }

        if token.kind == Directive {
            if token.text == ".pack" || token.text == ".size" {
                let attr_name: utf8 = token.text
                i = i + 1
                let mut attr_value: utf8 = ""
                if msil_check_kind(tokens, i, Number) {
                    attr_value = msil_peek(tokens, i).text
                    i = i + 1
                }
                push(class_attrs, MsilClassAttr {
                    name: attr_name,
                    value: attr_value
                })
            } else if token.text == ".field" {
                match parse_msil_field(tokens, i) {
                    case Fine(result):
                        push(fields, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".method" {
                match parse_msil_method(tokens, i) {
                    case Fine(result):
                        push(methods, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".property" {
                match parse_msil_property(tokens, i) {
                    case Fine(result):
                        push(properties, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".event" {
                match parse_msil_event(tokens, i) {
                    case Fine(result):
                        push(events, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".custom" {
                i = skip_msil_to_newline(tokens, i)
            } else {
                i = i + 1
            }
        } else if token.kind == Identifier || token.kind == Modifier {
            match parse_msil_inline_field(tokens, i) {
                case Fine(result):
                    push(fields, result.value)
                    i = result.next_index
                case Fail(error):
                    i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilTypeDef {
        name: name,
        modifiers: modifiers,
        extends: extends,
        implements: implements,
        class_attrs: class_attrs,
        fields: fields,
        methods: methods,
        properties: properties,
        events: events
    }, i))
}

micro parse_msil_field(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilFieldDef>> {
    let mut i: usize = index + 1

    let mut modifiers: [utf8] = []
    while msil_peek(tokens, i).kind == Modifier {
        push(modifiers, msil_peek(tokens, i).text)
        i = i + 1
    }

    let mut field_type: utf8 = ""
    if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
        field_type = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut data_offset: utf8 = ""
    if msil_check_text(tokens, i, Keyword, "at") {
        i = i + 1
        if msil_check_kind(tokens, i, Number) {
            data_offset = msil_peek(tokens, i).text
            i = i + 1
        }
    }

    let mut init_value: utf8 = ""
    if msil_check_text(tokens, i, Punctuation, "=") {
        i = i + 1
        while i < tokens.length && msil_peek(tokens, i).kind != Punctuation && msil_peek(tokens, i).kind != Directive {
            init_value = init_value + msil_peek(tokens, i).text
            i = i + 1
        }
    }

    let mut marshal_info: utf8 = ""

    let mut custom_attrs: [MsilCustomAttribute] = []

    return Fine(msil_parsed(MsilFieldDef {
        name: name,
        modifiers: modifiers,
        field_type: field_type,
        init_value: init_value,
        custom_attrs: custom_attrs,
        data_offset: data_offset,
        marshal_info: marshal_info
    }, i))
}

micro parse_msil_inline_field(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilFieldDef>> {
    let mut i: usize = index

    let mut modifiers: [utf8] = []
    while msil_peek(tokens, i).kind == Modifier {
        push(modifiers, msil_peek(tokens, i).text)
        i = i + 1
    }

    let mut field_type: utf8 = ""
    if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
        field_type = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    } else {
        return Fail(new_msil_diagnostic("期望字段名称", 0, 0))
    }

    return Fine(msil_parsed(MsilFieldDef {
        name: name,
        modifiers: modifiers,
        field_type: field_type,
        init_value: "",
        custom_attrs: [],
        data_offset: "",
        marshal_info: ""
    }, i))
}

micro parse_msil_method(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilMethodDef>> {
    let mut i: usize = index + 1

    let mut modifiers: [utf8] = []
    while msil_peek(tokens, i).kind == Modifier {
        push(modifiers, msil_peek(tokens, i).text)
        i = i + 1
    }

    let mut call_conv: utf8 = ""
    if msil_check_text(tokens, i, Keyword, "default") {
        call_conv = "default"
        i = i + 1
    } else if msil_check_text(tokens, i, Keyword, "vararg") {
        call_conv = "vararg"
        i = i + 1
    }

    let mut return_type: utf8 = ""
    if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
        return_type = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut parameters: [MsilMethodParam] = []
    match msil_expect(tokens, i, Punctuation, "(") {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        let tk: MsilToken = msil_peek(tokens, i)
        if tk.kind == Punctuation && tk.text == ")" {
            i = i + 1
            break
        }
        if tk.kind == Punctuation && tk.text == "," {
            i = i + 1
            continue
        }

        let mut param_type: utf8 = ""
        let mut param_name: utf8 = ""

        if tk.kind == TypeReference || tk.kind == Identifier {
            param_type = tk.text
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                param_name = msil_peek(tokens, i).text
                i = i + 1
            }
        } else {
            i = i + 1
            continue
        }

        push(parameters, MsilMethodParam {
            name: param_name,
            param_type: param_type,
            attrs: []
        })
    }

    let mut impl_attrs: [utf8] = []
    if msil_check_text(tokens, i, Keyword, "cil") {
        push(impl_attrs, "cil")
        i = i + 1
    }
    if msil_check_text(tokens, i, Keyword, "managed") {
        push(impl_attrs, "managed")
        i = i + 1
    }

    let mut pinvoke_info: MsilPInvokeInfo = MsilPInvokeInfo {
        dll_name: "",
        entry_point: "",
        attrs: []
    }
    if msil_check_text(tokens, i, Directive, ".pinvokeimpl") {
        i = i + 1
        let mut dll_name: utf8 = ""
        let mut entry_point: utf8 = ""
        let mut attrs: [utf8] = []

        if msil_check_kind(tokens, i, String) {
            dll_name = msil_peek(tokens, i).text
            i = i + 1
        }
        if msil_check_text(tokens, i, Keyword, "as") {
            i = i + 1
            if msil_check_kind(tokens, i, String) {
                entry_point = msil_peek(tokens, i).text
                i = i + 1
            }
        }

        pinvoke_info = MsilPInvokeInfo {
            dll_name: dll_name,
            entry_point: entry_point,
            attrs: attrs
        }
    }

    let mut body: MsilMethodBody = MsilMethodBody {
        has_body: false,
        max_stack: 8,
        init_locals: false,
        locals: [],
        instructions: [],
        exception_clauses: []
    }

    match msil_expect(tokens, i, Punctuation, "{") {
        case Fine(new_i):
            i = new_i
            match parse_msil_method_body(tokens, i) {
                case Fine(result):
                    body = result.value
                    i = result.next_index
                case Fail(error):
                    return Fail(error)
                }
        case Fail(error):
            body = MsilMethodBody {
                has_body: false,
                max_stack: 0,
                init_locals: false,
                locals: [],
                instructions: [],
                exception_clauses: []
            }
    }

    let mut custom_attrs: [MsilCustomAttribute] = []
    let mut overrides: [utf8] = []

    return Fine(msil_parsed(MsilMethodDef {
        name: name,
        modifiers: modifiers,
        return_type: return_type,
        parameters: parameters,
        call_conv: call_conv,
        impl_attrs: impl_attrs,
        body: body,
        custom_attrs: custom_attrs,
        pinvoke_info: pinvoke_info,
        overrides: overrides
    }, i))
}

micro parse_msil_method_body(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilMethodBody>> {
    let mut i: usize = index
    let mut max_stack: u32 = 8
    let mut init_locals: bool = false
    let mut locals: [MsilLocalDecl] = []
    let mut instructions: [MsilInstruction] = []
    let mut exception_clauses: [MsilExceptionClause] = []

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)

        if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        }

        if token.kind == Directive {
            if token.text == ".maxstack" {
                i = i + 1
                if msil_check_kind(tokens, i, Number) {
                    i = i + 1
                }
            } else if token.text == ".locals" {
                match parse_msil_locals(tokens, i) {
                    case Fine(result):
                        locals = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".try" {
                match parse_msil_exception_clause(tokens, i) {
                    case Fine(result):
                        push(exception_clauses, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            } else if token.text == ".line" || token.text == ".language" || token.text == ".entrypoint" {
                i = skip_msil_to_newline(tokens, i)
            } else {
                i = i + 1
            }
        } else if token.kind == IllLabel {
            push(instructions, Label(MsilLabel {
                name: token.text
            }))
            i = i + 1
        } else if token.kind == Opcode {
            let opcode: utf8 = token.text
            i = i + 1
            let mut operand: utf8 = ""

            if i < tokens.length {
                let next: MsilToken = msil_peek(tokens, i)
                if next.kind == Identifier || next.kind == TypeReference
                    || next.kind == Number || next.kind == String {
                    operand = next.text
                    i = i + 1
                }
            }

            push(instructions, Instr(MsilInstr {
                opcode: opcode,
                operand: operand
            }))
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilMethodBody {
        has_body: true,
        max_stack: max_stack,
        init_locals: init_locals,
        locals: locals,
        instructions: instructions,
        exception_clauses: exception_clauses
    }, i))
}

micro parse_msil_locals(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<[MsilLocalDecl]>> {
    let mut i: usize = index + 1

    if msil_check_text(tokens, i, Keyword, "init") {
        i = i + 1
    }

    let mut locals: [MsilLocalDecl] = []

    match msil_expect(tokens, i, Punctuation, "(") {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fine(msil_parsed(locals, i))
    }

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == ")" {
            i = i + 1
            break
        }
        if token.kind == Punctuation && token.text == "," {
            i = i + 1
            continue
        }

        let mut local_type: utf8 = ""
        let mut local_name: utf8 = ""

        if token.kind == TypeReference || token.kind == Identifier {
            local_type = token.text
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                local_name = msil_peek(tokens, i).text
                i = i + 1
            }
        } else {
            i = i + 1
            continue
        }

        push(locals, MsilLocalDecl {
            local_type: local_type,
            name: local_name
        })
    }

    return Fine(msil_parsed(locals, i))
}

micro parse_msil_exception_clause(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilExceptionClause>> {
    let mut i: usize = index + 1

    let mut try_start: utf8 = ""
    let mut try_end: utf8 = ""

    match msil_expect(tokens, i, Punctuation, "{") {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        if msil_check_text(tokens, i, Punctuation, "}") {
            i = i + 1
            break
        }
        i = i + 1
    }

    let mut exception_type: utf8 = ""
    let mut clause_type: utf8 = ""
    let mut handler_start: utf8 = ""
    let mut handler_end: utf8 = ""
    let mut filter_label: utf8 = ""

    let token: MsilToken = msil_peek(tokens, i)
    if token.kind == Keyword && token.text == "catch" {
        clause_type = "catch"
        i = i + 1
        if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
            exception_type = msil_peek(tokens, i).text
            i = i + 1
        }
    } else if token.kind == Keyword && token.text == "filter" {
        clause_type = "filter"
        i = i + 1
    } else if token.kind == Keyword && token.text == "finally" {
        clause_type = "finally"
        i = i + 1
    } else if token.kind == Keyword && token.text == "fault" {
        clause_type = "fault"
        i = i + 1
    }

    while i < tokens.length {
        if msil_check_text(tokens, i, Punctuation, "{") {
            i = i + 1
            break
        }
        i = i + 1
    }

    while i < tokens.length {
        if msil_check_text(tokens, i, Punctuation, "}") {
            i = i + 1
            break
        }
        i = i + 1
    }

    return Fine(msil_parsed(MsilExceptionClause {
        clause_type: clause_type,
        exception_type: exception_type,
        try_start: try_start,
        try_end: try_end,
        handler_start: handler_start,
        handler_end: handler_end,
        filter_label: filter_label
    }, i))
}

micro parse_msil_property(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilPropertyDef>> {
    let mut i: usize = index + 1

    let mut modifiers: [utf8] = []
    while msil_peek(tokens, i).kind == Modifier {
        push(modifiers, msil_peek(tokens, i).text)
        i = i + 1
    }

    let mut property_type: utf8 = ""
    if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
        property_type = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut getter: utf8 = ""
    let mut setter: utf8 = ""

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == "{" {
            i = i + 1
        } else if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        } else if token.kind == Directive && token.text == ".get" {
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                getter = msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".set" {
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                setter = msil_peek(tokens, i).text
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilPropertyDef {
        name: name,
        property_type: property_type,
        modifiers: modifiers,
        getter: getter,
        setter: setter
    }, i))
}

micro parse_msil_event(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilEventDef>> {
    let mut i: usize = index + 1

    let mut event_type: utf8 = ""
    if msil_check_kind(tokens, i, TypeReference) || msil_check_kind(tokens, i, Identifier) {
        event_type = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut name: utf8 = ""
    if msil_check_kind(tokens, i, Identifier) {
        name = msil_peek(tokens, i).text
        i = i + 1
    }

    let mut add_on: utf8 = ""
    let mut remove_on: utf8 = ""
    let mut fire: utf8 = ""

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Punctuation && token.text == "{" {
            i = i + 1
        } else if token.kind == Punctuation && token.text == "}" {
            i = i + 1
            break
        } else if token.kind == Directive && token.text == ".addon" {
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                add_on = msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".removeon" {
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                remove_on = msil_peek(tokens, i).text
                i = i + 1
            }
        } else if token.kind == Directive && token.text == ".fire" {
            i = i + 1
            if msil_check_kind(tokens, i, Identifier) {
                fire = msil_peek(tokens, i).text
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }

    return Fine(msil_parsed(MsilEventDef {
        name: name,
        event_type: event_type,
        add_on: add_on,
        remove_on: remove_on,
        fire: fire
    }, i))
}

micro parse_msil_method_impl(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilMethodImpl>> {
    let mut i: usize = index + 1

    let mut class_name: utf8 = ""
    let mut interface_method: utf8 = ""
    let mut implementation_method: utf8 = ""

    while i < tokens.length {
        let token: MsilToken = msil_peek(tokens, i)
        if token.kind == Identifier || token.kind == TypeReference {
            if class_name == "" {
                class_name = token.text
            } else if interface_method == "" {
                interface_method = token.text
            } else if implementation_method == "" {
                implementation_method = token.text
            }
        }
        i = i + 1
        if msil_check_kind(tokens, i, EndOfFile) {
            break
        }
    }

    return Fine(msil_parsed(MsilMethodImpl {
        class_name: class_name,
        interface_method: interface_method,
        implementation_method: implementation_method
    }, i))
}

micro parse_msil_security(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilSecurityDecl>> {
    let mut i: usize = index + 1

    let mut action: utf8 = ""
    let mut permission_set: utf8 = ""

    if msil_check_kind(tokens, i, Identifier) {
        action = msil_peek(tokens, i).text
        i = i + 1
    }

    return Fine(msil_parsed(MsilSecurityDecl {
        action: action,
        permission_set: permission_set
    }, i))
}

micro skip_msil_to_newline(tokens: [MsilToken], index: usize) -> usize {
    let mut i: usize = index
    while i < tokens.length {
        let token: MsilToken = tokens[i]
        if token.line != tokens[index].line {
            break
        }
        i = i + 1
    }
    return i
}
