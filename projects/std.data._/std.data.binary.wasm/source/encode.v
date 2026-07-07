namespace std.data.binary.wasm;

# Encode helpers — WASM binary sections / LEB128 / typed leaf opcodes.
# Isomorphic direction to Rust `std-data::binary::wasm::{encode,opcode}`.
# Bytes are i32 0..255 (same convention as ClassFile encode).
# Opcode / section / valtype bytes: `opcode.v` + `opcodes.v`. Emitters call typed micros only.

micro wasm_push_u8(buf: [i32], value: i32) -> [i32] {
    let mut out: [i32] = buf
    let mut v: i32 = value
    if v < 0 {
        v = 0
    }
    if v > 255 {
        v = v % 256
    }
    out = push(out, v)
    return out
}

micro wasm_push_bytes(buf: [i32], bytes: [i32]) -> [i32] {
    let mut out: [i32] = buf
    let mut i: usize = 0
    while i < bytes.length() {
        out = push(out, bytes⁅i⁆)
        i = i + 1
    }
    return out
}

# Floor-div by 128 (arithmetic toward −∞) for SLEB128.
micro wasm_ashr7_i32(value: i32) -> i32 {
    if value >= 0 {
        return value / 128
    }
    let q: i32 = value / 128
    let r: i32 = value - q * 128
    if r == 0 {
        return q
    }
    return q - 1
}

# Low 7 bits in two's-complement sense (0..127).
micro wasm_low7_i32(value: i32) -> i32 {
    let q: i32 = value / 128
    let r: i32 = value - q * 128
    if r < 0 {
        return r + 128
    }
    return r
}

micro wasm_encode_uleb128(value: u32) -> [i32] {
    let mut out: [i32] = []
    let mut v: u32 = value
    let mut more: bool = true
    while more {
        let low: u32 = v % 128
        v = v / 128
        if v == 0 {
            out = push(out, low as i32)
            more = false
        }
        else {
            out = push(out, (low + 128) as i32)
        }
    }
    return out
}

micro wasm_encode_sleb128_i32(value: i32) -> [i32] {
    let mut out: [i32] = []
    let mut v: i32 = value
    let mut more: bool = true
    while more {
        let byte: i32 = wasm_low7_i32(v)
        v = wasm_ashr7_i32(v)
        let sign_set: bool = byte >= 64
        if (v == 0 && !sign_set) || (v == -1 && sign_set) {
            out = push(out, byte)
            more = false
        }
        else {
            out = push(out, byte + 128)
        }
    }
    return out
}

# ASCII subset → bytes (export / import names). Non-mapped scalars → '?'.
micro wasm_char_ascii_byte(ch: utf8) -> i32 {
    if ch == "a" { return 97 }
    if ch == "b" { return 98 }
    if ch == "c" { return 99 }
    if ch == "d" { return 100 }
    if ch == "e" { return 101 }
    if ch == "f" { return 102 }
    if ch == "g" { return 103 }
    if ch == "h" { return 104 }
    if ch == "i" { return 105 }
    if ch == "j" { return 106 }
    if ch == "k" { return 107 }
    if ch == "l" { return 108 }
    if ch == "m" { return 109 }
    if ch == "n" { return 110 }
    if ch == "o" { return 111 }
    if ch == "p" { return 112 }
    if ch == "q" { return 113 }
    if ch == "r" { return 114 }
    if ch == "s" { return 115 }
    if ch == "t" { return 116 }
    if ch == "u" { return 117 }
    if ch == "v" { return 118 }
    if ch == "w" { return 119 }
    if ch == "x" { return 120 }
    if ch == "y" { return 121 }
    if ch == "z" { return 122 }
    if ch == "A" { return 65 }
    if ch == "B" { return 66 }
    if ch == "C" { return 67 }
    if ch == "D" { return 68 }
    if ch == "E" { return 69 }
    if ch == "F" { return 70 }
    if ch == "G" { return 71 }
    if ch == "H" { return 72 }
    if ch == "I" { return 73 }
    if ch == "J" { return 74 }
    if ch == "K" { return 75 }
    if ch == "L" { return 76 }
    if ch == "M" { return 77 }
    if ch == "N" { return 78 }
    if ch == "O" { return 79 }
    if ch == "P" { return 80 }
    if ch == "Q" { return 81 }
    if ch == "R" { return 82 }
    if ch == "S" { return 83 }
    if ch == "T" { return 84 }
    if ch == "U" { return 85 }
    if ch == "V" { return 86 }
    if ch == "W" { return 87 }
    if ch == "X" { return 88 }
    if ch == "Y" { return 89 }
    if ch == "Z" { return 90 }
    if ch == "0" { return 48 }
    if ch == "1" { return 49 }
    if ch == "2" { return 50 }
    if ch == "3" { return 51 }
    if ch == "4" { return 52 }
    if ch == "5" { return 53 }
    if ch == "6" { return 54 }
    if ch == "7" { return 55 }
    if ch == "8" { return 56 }
    if ch == "9" { return 57 }
    if ch == "_" { return 95 }
    if ch == "-" { return 45 }
    if ch == "." { return 46 }
    if ch == ":" { return 58 }
    if ch == "/" { return 47 }
    if ch == "#" { return 35 }
    if ch == "@" { return 64 }
    return 63
}

micro wasm_utf8_ascii_bytes(text: utf8) -> [i32] {
    let mut out: [i32] = []
    let mut i: i32 = 0
    let n: i32 = text.length()
    while i < n {
        out = push(out, wasm_char_ascii_byte(text.slice(i, 1)))
        i = i + 1
    }
    return out
}

micro wasm_encode_name(text: utf8) -> [i32] {
    let raw: [i32] = wasm_utf8_ascii_bytes(text)
    let mut out: [i32] = wasm_encode_uleb128(raw.length() as u32)
    out = wasm_push_bytes(out, raw)
    return out
}

micro wasm_encode_section(section_id: WasmSectionId, payload: [i32]) -> [i32] {
    let mut out: [i32] = []
    out = wasm_push_u8(out, wasm_section_id_byte(section_id))
    out = wasm_push_bytes(out, wasm_encode_uleb128(payload.length() as u32))
    out = wasm_push_bytes(out, payload)
    return out
}

# Typed functype: form · params · results.
micro wasm_encode_functype(parameters: [WasmValueType], results: [WasmValueType]) -> [i32] {
    let mut out: [i32] = []
    out = wasm_push_u8(out, wasm_type_form_func_byte())
    out = wasm_push_bytes(out, wasm_encode_uleb128(parameters.length() as u32))
    let mut pi: usize = 0
    while pi < parameters.length() {
        out = wasm_push_u8(out, wasm_value_type_byte(parameters⁅pi⁆))
        pi = pi + 1
    }
    out = wasm_push_bytes(out, wasm_encode_uleb128(results.length() as u32))
    let mut ri: usize = 0
    while ri < results.length() {
        out = wasm_push_u8(out, wasm_value_type_byte(results⁅ri⁆))
        ri = ri + 1
    }
    return out
}

# --- Typed instruction encode (emitters call these; no raw opcode bytes upstream) ---

micro wasm_encode_opcode(op: WasmOpcode) -> [i32] {
    let mut out: [i32] = []
    out = wasm_push_u8(out, wasm_opcode_byte(op))
    return out
}

micro wasm_encode_i32_const(value: i32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(I32Const)
    out = wasm_push_bytes(out, wasm_encode_sleb128_i32(value))
    return out
}

micro wasm_encode_local_get(index: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(LocalGet)
    out = wasm_push_bytes(out, wasm_encode_uleb128(index))
    return out
}

micro wasm_encode_local_set(index: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(LocalSet)
    out = wasm_push_bytes(out, wasm_encode_uleb128(index))
    return out
}

micro wasm_encode_call(func_index: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(Call)
    out = wasm_push_bytes(out, wasm_encode_uleb128(func_index))
    return out
}

micro wasm_encode_br(depth: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(Br)
    out = wasm_push_bytes(out, wasm_encode_uleb128(depth))
    return out
}

micro wasm_encode_br_if(depth: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(BrIf)
    out = wasm_push_bytes(out, wasm_encode_uleb128(depth))
    return out
}

micro wasm_encode_block_empty() -> [i32] {
    let mut out: [i32] = wasm_encode_opcode(Block)
    out = wasm_push_u8(out, wasm_blocktype_empty_byte())
    return out
}

micro wasm_encode_end() -> [i32] {
    return wasm_encode_opcode(End)
}

micro wasm_encode_return() -> [i32] {
    return wasm_encode_opcode(Return)
}

micro wasm_encode_drop() -> [i32] {
    return wasm_encode_opcode(Drop)
}

micro wasm_encode_unreachable() -> [i32] {
    return wasm_encode_opcode(Unreachable)
}

micro wasm_encode_nop() -> [i32] {
    return wasm_encode_opcode(Nop)
}

micro wasm_encode_i32_add() -> [i32] {
    return wasm_encode_opcode(I32Add)
}

micro wasm_encode_i32_sub() -> [i32] {
    return wasm_encode_opcode(I32Sub)
}

micro wasm_encode_i32_mul() -> [i32] {
    return wasm_encode_opcode(I32Mul)
}

micro wasm_encode_i32_div_s() -> [i32] {
    return wasm_encode_opcode(I32DivS)
}

micro wasm_encode_i32_rem_s() -> [i32] {
    return wasm_encode_opcode(I32RemS)
}

micro wasm_encode_i32_eqz() -> [i32] {
    return wasm_encode_opcode(I32Eqz)
}

micro wasm_encode_i32_eq() -> [i32] {
    return wasm_encode_opcode(I32Eq)
}

micro wasm_encode_i32_lt_s() -> [i32] {
    return wasm_encode_opcode(I32LtS)
}

micro wasm_encode_i32_gt_s() -> [i32] {
    return wasm_encode_opcode(I32GtS)
}

# Synthetic: `i32.const -1; i32.mul` (stack top = -x).
micro wasm_encode_i32_neg() -> [i32] {
    let mut out: [i32] = wasm_encode_i32_const(-1)
    out = wasm_push_bytes(out, wasm_encode_i32_mul())
    return out
}

# `i32.const literal_index; call host_fn` (JS glue const_utf8 pattern).
micro wasm_encode_const_utf8_call(literal_index: u32, host_func_index: u32) -> [i32] {
    let mut out: [i32] = wasm_encode_i32_const(literal_index as i32)
    out = wasm_push_bytes(out, wasm_encode_call(host_func_index))
    return out
}

structure WasmEncodedFuncType {
    parameters: [WasmValueType]
    results: [WasmValueType]
}

structure WasmEncodedImportFunc {
    module: utf8
    field: utf8
    type_index: u32
}

structure WasmEncodedExport {
    name: utf8
    kind: WasmExternalKind
    index: u32
}

structure WasmEncodedFunctionBody {
    local_i32_count: u32
    body_opcodes: [i32]
}

# Module header magic `\0asm` + version 1 — via named constants in opcodes.v.
micro wasm_encode_module_header() -> [i32] {
    return wasm_push_module_preamble([])
}

# Hex dump (Node validate / legion spy handoff); lowercase.
micro wasm_nibble_hex(n: i32) -> utf8 {
    if n == 0 { return "0" }
    if n == 1 { return "1" }
    if n == 2 { return "2" }
    if n == 3 { return "3" }
    if n == 4 { return "4" }
    if n == 5 { return "5" }
    if n == 6 { return "6" }
    if n == 7 { return "7" }
    if n == 8 { return "8" }
    if n == 9 { return "9" }
    if n == 10 { return "a" }
    if n == 11 { return "b" }
    if n == 12 { return "c" }
    if n == 13 { return "d" }
    if n == 14 { return "e" }
    return "f"
}

micro wasm_byte_hex(value: i32) -> utf8 {
    let mut v: i32 = value
    if v < 0 { v = 0 }
    if v > 255 { v = v % 256 }
    let hi: i32 = v / 16
    let lo: i32 = v - hi * 16
    return wasm_nibble_hex(hi) + wasm_nibble_hex(lo)
}

micro wasm_bytes_to_hex(bytes: [i32]) -> utf8 {
    let mut out: utf8 = ""
    let mut i: usize = 0
    while i < bytes.length() {
        out = out + wasm_byte_hex(bytes⁅i⁆)
        i = i + 1
    }
    return out
}

# Minimal module: types + optional imports + functions + exports + code.
micro wasm_encode_module_bytes(functypes: [WasmEncodedFuncType], imports: [WasmEncodedImportFunc], function_type_indices: [u32], exports: [WasmEncodedExport], bodies: [WasmEncodedFunctionBody]) -> [i32] {
    let mut out: [i32] = wasm_encode_module_header()

    let mut type_payload: [i32] = wasm_encode_uleb128(functypes.length() as u32)
    let mut ti: usize = 0
    while ti < functypes.length() {
        let ft: WasmEncodedFuncType = functypes⁅ti⁆
        type_payload = wasm_push_bytes(type_payload, wasm_encode_functype(ft.parameters, ft.results))
        ti = ti + 1
    }
    out = wasm_push_bytes(out, wasm_encode_section(TypeSection, type_payload))

    if imports.length() > 0 {
        let mut import_payload: [i32] = wasm_encode_uleb128(imports.length() as u32)
        let mut ii: usize = 0
        while ii < imports.length() {
            let imp: WasmEncodedImportFunc = imports⁅ii⁆
            import_payload = wasm_push_bytes(import_payload, wasm_encode_name(imp.module))
            import_payload = wasm_push_bytes(import_payload, wasm_encode_name(imp.field))
            import_payload = wasm_push_u8(import_payload, wasm_external_kind_byte(Function))
            import_payload = wasm_push_bytes(import_payload, wasm_encode_uleb128(imp.type_index))
            ii = ii + 1
        }
        out = wasm_push_bytes(out, wasm_encode_section(ImportSection, import_payload))
    }

    let mut func_payload: [i32] = wasm_encode_uleb128(function_type_indices.length() as u32)
    let mut fi: usize = 0
    while fi < function_type_indices.length() {
        func_payload = wasm_push_bytes(func_payload, wasm_encode_uleb128(function_type_indices⁅fi⁆))
        fi = fi + 1
    }
    out = wasm_push_bytes(out, wasm_encode_section(FunctionSection, func_payload))

    if exports.length() > 0 {
        let mut export_payload: [i32] = wasm_encode_uleb128(exports.length() as u32)
        let mut ei: usize = 0
        while ei < exports.length() {
            let ex: WasmEncodedExport = exports⁅ei⁆
            export_payload = wasm_push_bytes(export_payload, wasm_encode_name(ex.name))
            export_payload = wasm_push_u8(export_payload, wasm_external_kind_byte(ex.kind))
            export_payload = wasm_push_bytes(export_payload, wasm_encode_uleb128(ex.index))
            ei = ei + 1
        }
        out = wasm_push_bytes(out, wasm_encode_section(ExportSection, export_payload))
    }

    let mut code_payload: [i32] = wasm_encode_uleb128(bodies.length() as u32)
    let mut bi: usize = 0
    while bi < bodies.length() {
        let body: WasmEncodedFunctionBody = bodies⁅bi⁆
        let mut entry: [i32] = []
        if body.local_i32_count == 0 {
            entry = wasm_push_bytes(entry, wasm_encode_uleb128(0))
        }
        else {
            entry = wasm_push_bytes(entry, wasm_encode_uleb128(1))
            entry = wasm_push_bytes(entry, wasm_encode_uleb128(body.local_i32_count))
            entry = wasm_push_u8(entry, wasm_value_type_byte(I32))
        }
        entry = wasm_push_bytes(entry, body.body_opcodes)
        entry = wasm_push_bytes(entry, wasm_encode_end())
        code_payload = wasm_push_bytes(code_payload, wasm_encode_uleb128(entry.length() as u32))
        code_payload = wasm_push_bytes(code_payload, entry)
        bi = bi + 1
    }
    out = wasm_push_bytes(out, wasm_encode_section(CodeSection, code_payload))
    return out
}
