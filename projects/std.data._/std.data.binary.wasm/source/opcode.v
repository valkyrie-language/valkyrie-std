namespace std.data.binary.wasm;

# Leaf opcodes + value / external kinds — isomorphic to Rust
# `std-data::binary::wasm::{opcode, section}`.
# Binary literals for opcodes / valtypes live **only** here (and encode helpers
# that call these). Emitters must use typed encode APIs, never raw bytes.

unite WasmOpcode {
    Unreachable
    Nop
    Block
    Loop
    If
    Else
    End
    Br
    BrIf
    Return
    Call
    CallIndirect
    Drop
    LocalGet
    LocalSet
    LocalTee
    GlobalGet
    GlobalSet
    I32Const
    I64Const
    I32Eqz
    I32Eq
    I32Ne
    I32LtS
    I32LtU
    I32GtS
    I32GtU
    I32LeS
    I32GeS
    I32Add
    I32Sub
    I32Mul
    I32DivS
    I32RemS
    I32And
    I32Or
    I32Xor
    I32Shl
    I32ShrS
}

unite WasmValueType {
    I32
    I64
    F32
    F64
    Funcref
    Externref
    Anyref
}

unite WasmExternalKind {
    Function
    Table
    Memory
    Global
}

unite WasmSectionId {
    CustomSection
    TypeSection
    ImportSection
    FunctionSection
    TableSection
    MemorySection
    GlobalSection
    ExportSection
    StartSection
    ElementSection
    CodeSection
    DataSection
}

# Opcode byte — format table only; do not call from emitters.
micro wasm_opcode_byte(op: WasmOpcode) -> i32 {
    match op {
        case Unreachable: { return 0 }
        case Nop: { return 1 }
        case Block: { return 2 }
        case Loop: { return 3 }
        case If: { return 4 }
        case Else: { return 5 }
        case End: { return 11 }
        case Br: { return 12 }
        case BrIf: { return 13 }
        case Return: { return 15 }
        case Call: { return 16 }
        case CallIndirect: { return 17 }
        case Drop: { return 26 }
        case LocalGet: { return 32 }
        case LocalSet: { return 33 }
        case LocalTee: { return 34 }
        case GlobalGet: { return 35 }
        case GlobalSet: { return 36 }
        case I32Const: { return 65 }
        case I64Const: { return 66 }
        case I32Eqz: { return 69 }
        case I32Eq: { return 70 }
        case I32Ne: { return 71 }
        case I32LtS: { return 72 }
        case I32LtU: { return 73 }
        case I32GtS: { return 74 }
        case I32GtU: { return 75 }
        case I32LeS: { return 76 }
        case I32GeS: { return 78 }
        case I32Add: { return 106 }
        case I32Sub: { return 107 }
        case I32Mul: { return 108 }
        case I32DivS: { return 109 }
        case I32RemS: { return 111 }
        case I32And: { return 113 }
        case I32Or: { return 114 }
        case I32Xor: { return 115 }
        case I32Shl: { return 116 }
        case I32ShrS: { return 117 }
    }
}

micro wasm_value_type_byte(ty: WasmValueType) -> i32 {
    match ty {
        case I32: { return 127 }
        case I64: { return 126 }
        case F32: { return 125 }
        case F64: { return 124 }
        case Funcref: { return 112 }
        case Externref: { return 111 }
        case Anyref: { return 110 }
    }
}

micro wasm_external_kind_byte(kind: WasmExternalKind) -> i32 {
    match kind {
        case Function: { return 0 }
        case Table: { return 1 }
        case Memory: { return 2 }
        case Global: { return 3 }
    }
}

micro wasm_section_id_byte(id: WasmSectionId) -> i32 {
    match id {
        case CustomSection: { return 0 }
        case TypeSection: { return 1 }
        case ImportSection: { return 2 }
        case FunctionSection: { return 3 }
        case TableSection: { return 4 }
        case MemorySection: { return 5 }
        case GlobalSection: { return 6 }
        case ExportSection: { return 7 }
        case StartSection: { return 8 }
        case ElementSection: { return 9 }
        case CodeSection: { return 10 }
        case DataSection: { return 11 }
    }
}

# Empty blocktype immediate (`block` / `loop` / `if` without result).
micro wasm_blocktype_empty_byte() -> i32 {
    return 64
}

# functype form byte.
micro wasm_type_form_func_byte() -> i32 {
    return 96
}
