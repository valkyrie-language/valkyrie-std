namespace std.data.text.msil;

structure MsilAssembly {
    assembly_decl: MsilAssemblyDecl

    module_decl: MsilModuleDecl

    types: [MsilTypeDef]

    method_impls: [MsilMethodImpl]

    security_decls: [MsilSecurityDecl]
}

structure MsilAssemblyDecl {
    name: utf8

    custom_attrs: [MsilCustomAttribute]

    hash_algorithm: u32

    version: utf8

    locale: utf8

    public_key: utf8
}

structure MsilModuleDecl {
    name: utf8

    custom_attrs: [MsilCustomAttribute]
}

structure MsilCustomAttribute {
    ctor_ref: utf8

    args: [utf8]
}

structure MsilTypeDef {
    name: utf8

    modifiers: [utf8]

    extends: utf8

    implements: [utf8]

    class_attrs: [MsilClassAttr]

    fields: [MsilFieldDef]

    methods: [MsilMethodDef]

    properties: [MsilPropertyDef]

    events: [MsilEventDef]
}

structure MsilClassAttr {
    name: utf8

    value: utf8
}

structure MsilFieldDef {
    name: utf8

    modifiers: [utf8]

    field_type: utf8

    init_value: utf8

    custom_attrs: [MsilCustomAttribute]

    data_offset: utf8

    marshal_info: utf8
}

structure MsilMethodDef {
    name: utf8

    modifiers: [utf8]

    return_type: utf8

    parameters: [MsilMethodParam]

    call_conv: utf8

    impl_attrs: [utf8]

    body: MsilMethodBody

    custom_attrs: [MsilCustomAttribute]

    pinvoke_info: MsilPInvokeInfo

    overrides: [utf8]
}

structure MsilMethodParam {
    name: utf8

    param_type: utf8

    attrs: [utf8]
}

structure MsilPInvokeInfo {
    dll_name: utf8

    entry_point: utf8

    attrs: [utf8]
}

structure MsilMethodBody {
    has_body: bool

    max_stack: u32

    init_locals: bool

    locals: [MsilLocalDecl]

    instructions: [MsilInstruction]

    exception_clauses: [MsilExceptionClause]
}

structure MsilLocalDecl {
    local_type: utf8

    name: utf8
}

[tag(MsilInstructionKind)]
unite MsilInstruction {
    Instr(MsilInstr)

    Label(MsilLabel)

    ScopeStart

    ScopeEnd
}

structure MsilInstr {
    opcode: utf8

    operand: utf8
}

structure MsilLabel {
    name: utf8
}

structure MsilExceptionClause {
    clause_type: utf8

    exception_type: utf8

    try_start: utf8

    try_end: utf8

    handler_start: utf8

    handler_end: utf8

    filter_label: utf8
}

structure MsilPropertyDef {
    name: utf8

    property_type: utf8

    modifiers: [utf8]

    getter: utf8

    setter: utf8
}

structure MsilEventDef {
    name: utf8

    event_type: utf8

    add_on: utf8

    remove_on: utf8

    fire: utf8
}

structure MsilMethodImpl {
    class_name: utf8

    interface_method: utf8

    implementation_method: utf8
}

structure MsilSecurityDecl {
    action: utf8

    permission_set: utf8
}
