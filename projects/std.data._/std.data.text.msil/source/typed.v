namespace std.data.text.msil;

# Typed MSIL model — isomorphic to Rust `std-data::text::msil::model`
# (MsilType / MsilOpcode / MsilInstructionOperand / method bodies).
# Existing `ast.v` remains the ILASM parse surface; this is the emit/consume IR.

unite MsilType {
    Void
    Bool
    Char
    Int8 { signed: bool }
    Int16 { signed: bool }
    Int32 { signed: bool }
    Int64 { signed: bool }
    Float32
    Float64
    String
    Object
    IntPtr { signed: bool }
    # Array / named — keep flat (no recursive unite) for CLR bootstrap.
    SzArrayNamed { element_name: utf8 }
    Named { name: utf8 }
}

structure MsilMethodSignature {
    return_type: MsilType
    parameter_types: [MsilType]
    has_this: bool
}

structure MsilMethodRef {
    owner: utf8
    name: utf8
    signature: MsilMethodSignature
}

unite MsilOpcode {
    Nop
    Break
    Ldarg0
    Ldarg1
    Ldarg2
    Ldarg3
    Ldarg
    Ldloc0
    Ldloc1
    Ldloc2
    Ldloc3
    Stloc0
    Stloc1
    Stloc2
    Stloc3
    Ldnull
    LdcI4M1
    LdcI4_0
    LdcI4_1
    LdcI4_2
    LdcI4_3
    LdcI4_4
    LdcI4_5
    LdcI4_6
    LdcI4_7
    LdcI4_8
    LdcI4
    LdcI8
    Ldstr
    Ldloc
    Stloc
    Ldsfld
    Stsfld
    Ldfld
    Stfld
    Call
    Callvirt
    Newobj
    Initobj
    Castclass
    Isinst
    Box
    UnboxAny
    Ret
    Pop
    Dup
    Br
    Brfalse
    Brtrue
    Beq
    BneUn
    Add
    Sub
    Mul
    Div
    Rem
    Neg
    Not
    And
    Or
    Xor
    Ceq
    Clt
    Cgt
    ConvI4
    ConvI8
    Ldlen
    Newarr
    LdelemRef
    StelemRef
    LdelemI4
    StelemI4
}

unite MsilInstructionOperand {
    None
    Integer { value: i64 }
    FloatText { value: utf8 }
    # Language UTF-8 source text; CLR ldstr render transcodes to UTF-16.
    StringLiteral { utf8_source: utf8 }
    Symbol { value: utf8 }
    Method { value: MsilMethodRef }
    TypeName { value: utf8 }
    Field { owner: utf8, name: utf8 }
    Token { value: u32 }
    BranchTarget { label: utf8 }
    Raw { value: utf8 }
}

structure TypedMsilInstruction {
    label: utf8
    opcode: MsilOpcode
    operand: MsilInstructionOperand
}

structure TypedMsilMethodBody {
    method: MsilMethodRef
    locals: [MsilType]
    instructions: [TypedMsilInstruction]
    max_stack: u16
    is_entry_point: bool
    is_async: bool
}

structure TypedMsilField {
    name: utf8
    ty: MsilType
    is_static: bool
}

structure TypedMsilTypeDef {
    full_name: utf8
    namespace_name: utf8
    fields: [TypedMsilField]
    methods: [TypedMsilMethodBody]
    is_value_type: bool
}

structure TypedMsilAssembly {
    name: utf8
    externs: [utf8]
}

structure TypedMsilModule {
    assembly: TypedMsilAssembly
    types: [TypedMsilTypeDef]
    global_methods: [TypedMsilMethodBody]
}

micro empty_msil_signature() -> MsilMethodSignature {
    return MsilMethodSignature {
        return_type: Void,
        parameter_types: [],
        has_this: false
    }
}

micro empty_typed_msil_module() -> TypedMsilModule {
    return TypedMsilModule {
        assembly: TypedMsilAssembly {
            name: "",
            externs: []
        },
        types: [],
        global_methods: []
    }
}

micro msil_type_void() -> MsilType {
    return Void
}

micro msil_type_int32() -> MsilType {
    return Int32 { signed: true }
}

micro msil_type_string() -> MsilType {
    return String
}

micro msil_type_object() -> MsilType {
    return Object
}

micro msil_type_named(name: utf8) -> MsilType {
    return Named { name: name }
}

micro typed_instr(opcode: MsilOpcode) -> TypedMsilInstruction {
    return TypedMsilInstruction {
        label: "",
        opcode: opcode,
        operand: None
    }
}

micro typed_instr_labeled(label: utf8, opcode: MsilOpcode) -> TypedMsilInstruction {
    return TypedMsilInstruction {
        label: label,
        opcode: opcode,
        operand: None
    }
}
