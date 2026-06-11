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

/// 仅用于特定值比较（如 Punctuation("{"))，非数据变体比较也安全
micro msil_expect(tokens: [MsilToken], index: usize, expected: MsilTokenKind) -> MsilParseResult<usize> {
    let token: MsilToken = msil_peek(tokens, index)
    if token.kind == expected {
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

/// 判断指令类 kind（纯分派标记）
micro is_msil_directive(kind: MsilTokenKind) -> bool {
    match kind {
        case AssemblyDirective | ModuleDirective | ClassDirective | OverrideDirective
            | PermissionDirective | PermissionSetDirective | HashDirective | VerDirective
            | LocaleDirective | PublicKeyDirective | CustomDirective | PackDirective
            | SizeDirective | FieldDirective | MethodDirective | PropertyDirective
            | EventDirective | MaxStackDirective | LocalsDirective | TryDirective
            | LineDirective | LanguageDirective | EntryPointDirective | GetDirective
            | SetDirective | AddOnDirective | RemoveOnDirective | FireDirective
            | PInvokeImplDirective:
            return true
        else:
            return false
    }
}

/// 从 Identifier kind 中收集修饰符，跳过非修饰符
micro collect_msil_modifiers(tokens: [MsilToken], index: usize) -> MsilParsed<[utf8]> {
    let mut i: usize = index
    let mut modifiers: [utf8] = []
    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Identifier(id) if is_msil_modifier_text(id):
                push(modifiers, id)
                i = i + 1
            else:
                break
        }
    }
    return msil_parsed(modifiers, i)
}

/// 尝试从携带数据的 kind 变体中提取文本 —— 用于消除 mega OR-pattern
micro try_extract_msil_token_text(kind: MsilTokenKind) -> utf8? {
    match kind {
        case Identifier(text): return Some(text)
        case Opcode(text): return Some(text)
        case TypeReference(text): return Some(text)
        case Number(text): return Some(text)
        case String(text): return Some(text)
        case IllLabel(text): return Some(text)
        case Comment(text): return Some(text)
        case Punctuation(text): return Some(text)
        else: return None()
    }
}

/// 尝试获取类型引用或标识符文本 —— 替代 TypeReference | Identifier OR-pattern
micro try_get_msil_type_or_id(kind: MsilTokenKind) -> utf8? {
    match kind {
        case TypeReference(text): return Some(text)
        case Identifier(text): return Some(text)
        else: return None()
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
        match msil_peek(tokens, i).kind {
            case EndOfFile:
                break
            case AssemblyDirective:
                match parse_msil_assembly(tokens, i) {
                    case Fine(result):
                        assembly_decl = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case ModuleDirective:
                match parse_msil_module(tokens, i) {
                    case Fine(result):
                        module_decl = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case ClassDirective:
                match parse_msil_type(tokens, i) {
                    case Fine(result):
                        push(types, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case OverrideDirective | MethodDirective:
                match parse_msil_method_impl(tokens, i) {
                    case Fine(result):
                        push(method_impls, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case PermissionDirective | PermissionSetDirective:
                match parse_msil_security(tokens, i) {
                    case Fine(result):
                        push(security_decls, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            else:
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
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut custom_attrs: [MsilCustomAttribute] = []
    let mut hash_algorithm: u32 = 0
    let mut version: utf8 = ""
    let mut locale: utf8 = ""
    let mut public_key: utf8 = ""

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("{"):
                i = i + 1
            case Punctuation("}"):
                i = i + 1
                break
            case Punctuation(text):
                i = i + 1
            case HashDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Number(text):
                        i = i + 1
                    ...
                }
            case VerDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case String(v):
                        version = v
                        i = i + 1
                    ...
                }
            case LocaleDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case String(l):
                        locale = l
                        i = i + 1
                    ...
                }
            case PublicKeyDirective:
                i = i + 1
                while i < tokens.length {
                    match try_extract_msil_token_text(msil_peek(tokens, i).kind) {
                        case Some(text):
                            public_key = public_key + text
                            i = i + 1
                        case None():
                            if is_msil_directive(msil_peek(tokens, i).kind) {
                                break
                            }
                            i = i + 1
                    }
                }
            case CustomDirective:
                match parse_msil_custom_attr(tokens, i) {
                    case Fine(result):
                        push(custom_attrs, result.value)
                        i = result.next_index
                    case Fail(error):
                        i = i + 1
                }
            else:
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
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut custom_attrs: [MsilCustomAttribute] = []

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("{"):
                i = i + 1
            case Punctuation("}"):
                i = i + 1
                break
            case CustomDirective:
                match parse_msil_custom_attr(tokens, i) {
                    case Fine(result):
                        push(custom_attrs, result.value)
                        i = result.next_index
                    case Fail(error):
                        i = i + 1
                }
            else:
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
        match msil_peek(tokens, i).kind {
            case Identifier(text):
                if ctor_ref == "" {
                    ctor_ref = text
                }
                i = i + 1
            case TypeReference(text):
                if ctor_ref == "" {
                    ctor_ref = text
                }
                i = i + 1
            case String(text):
                push(args, text)
                i = i + 1
            case Number(text):
                push(args, text)
                i = i + 1
            else:
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

    let mod_result: MsilParsed<[utf8]> = collect_msil_modifiers(tokens, i)
    let modifiers: [utf8] = mod_result.value
    i = mod_result.next_index

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut extends: utf8 = ""
    match msil_peek(tokens, i).kind {
        case ExtendsKeyword:
            i = i + 1
            match try_get_msil_type_or_id(msil_peek(tokens, i).kind) {
                case Some(text):
                    extends = text
                    i = i + 1
                case None():
                    ...
            }
        ...
    }

    let mut implements: [utf8] = []
    match msil_peek(tokens, i).kind {
        case ImplementsKeyword:
            i = i + 1
            while true {
                match try_get_msil_type_or_id(msil_peek(tokens, i).kind) {
                    case Some(text):
                        push(implements, text)
                        i = i + 1
                        match msil_peek(tokens, i).kind {
                            case Punctuation(","):
                                i = i + 1
                            ...
                        }
                    else:
                        break
                }
            }
        ...
    }

    let mut class_attrs: [MsilClassAttr] = []
    let mut fields: [MsilFieldDef] = []
    let mut methods: [MsilMethodDef] = []
    let mut properties: [MsilPropertyDef] = []
    let mut events: [MsilEventDef] = []

    match msil_expect(tokens, i, Punctuation("{")) {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("}"):
                i = i + 1
                break
            case PackDirective:
                i = i + 1
                let mut attr_value: utf8 = ""
                match msil_peek(tokens, i).kind {
                    case Number(text):
                        attr_value = text
                        i = i + 1
                    ...
                }
                push(class_attrs, MsilClassAttr {
                    name: ".pack",
                    value: attr_value
                })
            case SizeDirective:
                i = i + 1
                let mut attr_value: utf8 = ""
                match msil_peek(tokens, i).kind {
                    case Number(text):
                        attr_value = text
                        i = i + 1
                    ...
                }
                push(class_attrs, MsilClassAttr {
                    name: ".size",
                    value: attr_value
                })
            case FieldDirective:
                match parse_msil_field(tokens, i) {
                    case Fine(result):
                        push(fields, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case MethodDirective:
                match parse_msil_method(tokens, i) {
                    case Fine(result):
                        push(methods, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case PropertyDirective:
                match parse_msil_property(tokens, i) {
                    case Fine(result):
                        push(properties, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case EventDirective:
                match parse_msil_event(tokens, i) {
                    case Fine(result):
                        push(events, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case CustomDirective:
                i = skip_msil_to_newline(tokens, i)
            case Identifier(id) if is_msil_modifier_text(id):
                match parse_msil_inline_field(tokens, i) {
                    case Fine(result):
                        push(fields, result.value)
                        i = result.next_index
                    case Fail(error):
                        i = i + 1
                }
            case Identifier(id):
                match parse_msil_inline_field(tokens, i) {
                    case Fine(result):
                        push(fields, result.value)
                        i = result.next_index
                    case Fail(error):
                        i = i + 1
                }
            else:
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

    let mod_result: MsilParsed<[utf8]> = collect_msil_modifiers(tokens, i)
    let modifiers: [utf8] = mod_result.value
    i = mod_result.next_index

    let mut field_type: utf8 = ""
    match msil_peek(tokens, i).kind {
        case TypeReference(text) | Identifier(text):
            field_type = text
            i = i + 1
        ...
    }

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut data_offset: utf8 = ""
    match msil_peek(tokens, i).kind {
        case AtKeyword:
            i = i + 1
            match msil_peek(tokens, i).kind {
                case Number(text):
                    data_offset = text
                    i = i + 1
                ...
            }
        ...
    }

    let mut init_value: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Punctuation("="):
            i = i + 1
            while i < tokens.length {
                match msil_peek(tokens, i).kind {
                    case Identifier(text) | Opcode(text) | TypeReference(text) | Number(text)
                        | String(text) | IllLabel(text) | Comment(text):
                        init_value = init_value + text
                        i = i + 1
                    else:
                        if is_msil_directive(msil_peek(tokens, i).kind) {
                            break
                        }
                        i = i + 1
                }
            }
        ...
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

    let mod_result: MsilParsed<[utf8]> = collect_msil_modifiers(tokens, i)
    let modifiers: [utf8] = mod_result.value
    i = mod_result.next_index

    let mut field_type: utf8 = ""
    match msil_peek(tokens, i).kind {
        case TypeReference(text) | Identifier(text):
            field_type = text
            i = i + 1
        ...
    }

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        else:
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

    let mod_result: MsilParsed<[utf8]> = collect_msil_modifiers(tokens, i)
    let modifiers: [utf8] = mod_result.value
    i = mod_result.next_index

    let mut call_conv: utf8 = ""
    match msil_peek(tokens, i).kind {
        case DefaultKeyword:
            call_conv = "default"
            i = i + 1
        case VarArgKeyword:
            call_conv = "vararg"
            i = i + 1
        ...
    }

    let mut return_type: utf8 = ""
    match msil_peek(tokens, i).kind {
        case TypeReference(text) | Identifier(text):
            return_type = text
            i = i + 1
        ...
    }

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut parameters: [MsilMethodParam] = []
    match msil_expect(tokens, i, Punctuation("(")) {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation(")"):
                i = i + 1
                break
            case Punctuation(","):
                i = i + 1
            case TypeReference(param_type) | Identifier(param_type):
                let mut param_name: utf8 = ""
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        param_name = n
                        i = i + 1
                    ...
                }
                push(parameters, MsilMethodParam {
                    name: param_name,
                    param_type: param_type,
                    attrs: []
                })
            else:
                i = i + 1
        }
    }

    let mut impl_attrs: [utf8] = []
    match msil_peek(tokens, i).kind {
        case CilKeyword:
            push(impl_attrs, "cil")
            i = i + 1
        ...
    }
    match msil_peek(tokens, i).kind {
        case ManagedKeyword:
            push(impl_attrs, "managed")
            i = i + 1
        ...
    }

    let mut pinvoke_info: MsilPInvokeInfo = MsilPInvokeInfo {
        dll_name: "",
        entry_point: "",
        attrs: []
    }
    match msil_peek(tokens, i).kind {
        case PInvokeImplDirective:
            i = i + 1
            let mut dll_name: utf8 = ""
            let mut entry_point: utf8 = ""
            let mut attrs: [utf8] = []

            match msil_peek(tokens, i).kind {
                case String(text):
                    dll_name = text
                    i = i + 1
                ...
            }
            match msil_peek(tokens, i).kind {
                case AsKeyword:
                    i = i + 1
                    match msil_peek(tokens, i).kind {
                        case String(text):
                            entry_point = text
                            i = i + 1
                        ...
                    }
                ...
            }

            pinvoke_info = MsilPInvokeInfo {
                dll_name: dll_name,
                entry_point: entry_point,
                attrs: attrs
            }
        ...
    }

    let mut body: MsilMethodBody = MsilMethodBody {
        has_body: false,
        max_stack: 8,
        init_locals: false,
        locals: [],
        instructions: [],
        exception_clauses: []
    }

    match msil_expect(tokens, i, Punctuation("{")) {
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
        match msil_peek(tokens, i).kind {
            case Punctuation("}"):
                i = i + 1
                break
            case MaxStackDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Number(text):
                        i = i + 1
                    ...
                }
            case LocalsDirective:
                match parse_msil_locals(tokens, i) {
                    case Fine(result):
                        locals = result.value
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case TryDirective:
                match parse_msil_exception_clause(tokens, i) {
                    case Fine(result):
                        push(exception_clauses, result.value)
                        i = result.next_index
                    case Fail(error):
                        return Fail(error)
                }
            case LineDirective | LanguageDirective | EntryPointDirective:
                i = skip_msil_to_newline(tokens, i)
            case IllLabel(label_name):
                push(instructions, Label(MsilLabel {
                    name: label_name
                }))
                i = i + 1
            case Opcode(opcode):
                i = i + 1
                let mut operand: utf8 = ""

                if i < tokens.length {
                    match msil_peek(tokens, i).kind {
                        case Identifier(text) | TypeReference(text) | Number(text) | String(text):
                            operand = text
                            i = i + 1
                        ...
                    }
                }

                push(instructions, Instr(MsilInstr {
                    opcode: opcode,
                    operand: operand
                }))
            else:
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

    match msil_peek(tokens, i).kind {
        case InitKeyword:
            i = i + 1
        ...
    }

    let mut locals: [MsilLocalDecl] = []

    match msil_expect(tokens, i, Punctuation("(")) {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fine(msil_parsed(locals, i))
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation(")"):
                i = i + 1
                break
            case Punctuation(","):
                i = i + 1
            case TypeReference(local_type) | Identifier(local_type):
                let mut local_name: utf8 = ""
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        local_name = n
                        i = i + 1
                    ...
                }
                push(locals, MsilLocalDecl {
                    local_type: local_type,
                    name: local_name
                })
            else:
                i = i + 1
        }
    }

    return Fine(msil_parsed(locals, i))
}

micro parse_msil_exception_clause(tokens: [MsilToken], index: usize) -> MsilParseResult<MsilParsed<MsilExceptionClause>> {
    let mut i: usize = index + 1

    let mut try_start: utf8 = ""
    let mut try_end: utf8 = ""

    match msil_expect(tokens, i, Punctuation("{")) {
        case Fine(new_i):
            i = new_i
        case Fail(error):
            return Fail(error)
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("}"):
                i = i + 1
                break
            else:
                i = i + 1
        }
    }

    let mut exception_type: utf8 = ""
    let mut clause_type: utf8 = ""
    let mut handler_start: utf8 = ""
    let mut handler_end: utf8 = ""
    let mut filter_label: utf8 = ""

    match msil_peek(tokens, i).kind {
        case CatchKeyword:
            clause_type = "catch"
            i = i + 1
            match msil_peek(tokens, i).kind {
                case TypeReference(text) | Identifier(text):
                    exception_type = text
                    i = i + 1
                ...
            }
        case FilterKeyword:
            clause_type = "filter"
            i = i + 1
        case FinallyKeyword:
            clause_type = "finally"
            i = i + 1
        case FaultKeyword:
            clause_type = "fault"
            i = i + 1
        ...
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("{"):
                i = i + 1
                break
            else:
                i = i + 1
        }
    }

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("}"):
                i = i + 1
                break
            else:
                i = i + 1
        }
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

    let mod_result: MsilParsed<[utf8]> = collect_msil_modifiers(tokens, i)
    let modifiers: [utf8] = mod_result.value
    i = mod_result.next_index

    let mut property_type: utf8 = ""
    match msil_peek(tokens, i).kind {
        case TypeReference(text) | Identifier(text):
            property_type = text
            i = i + 1
        ...
    }

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut getter: utf8 = ""
    let mut setter: utf8 = ""

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("{"):
                i = i + 1
            case Punctuation("}"):
                i = i + 1
                break
            case Punctuation(text):
                i = i + 1
            case GetDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        getter = n
                        i = i + 1
                    ...
                }
            case SetDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        setter = n
                        i = i + 1
                    ...
                }
            else:
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
    match msil_peek(tokens, i).kind {
        case TypeReference(text) | Identifier(text):
            event_type = text
            i = i + 1
        ...
    }

    let mut name: utf8 = ""
    match msil_peek(tokens, i).kind {
        case Identifier(n):
            name = n
            i = i + 1
        ...
    }

    let mut add_on: utf8 = ""
    let mut remove_on: utf8 = ""
    let mut fire: utf8 = ""

    while i < tokens.length {
        match msil_peek(tokens, i).kind {
            case Punctuation("{"):
                i = i + 1
            case Punctuation("}"):
                i = i + 1
                break
            case Punctuation(text):
                i = i + 1
            case AddOnDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        add_on = n
                        i = i + 1
                    ...
                }
            case RemoveOnDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        remove_on = n
                        i = i + 1
                    ...
                }
            case FireDirective:
                i = i + 1
                match msil_peek(tokens, i).kind {
                    case Identifier(n):
                        fire = n
                        i = i + 1
                    ...
                }
            else:
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
        match msil_peek(tokens, i).kind {
            case Identifier(text) | TypeReference(text):
                if class_name == "" {
                    class_name = text
                } else if interface_method == "" {
                    interface_method = text
                } else if implementation_method == "" {
                    implementation_method = text
                }
            ...
        }
        i = i + 1
        match msil_peek(tokens, i).kind {
            case EndOfFile:
                break
            ...
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

    match msil_peek(tokens, i).kind {
        case Identifier(text):
            action = text
            i = i + 1
        ...
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