namespace std.data.binary.wasm;

# Named WASM binary constants — emitters must not hardcode 0x section/opcode magics.
# Shared by WASM JS-glue and WASI core-module encode paths.

# --- Module preamble ---

micro wasm_magic_byte0() -> i32 { return 0 }
micro wasm_magic_byte1() -> i32 { return 97 }
micro wasm_magic_byte2() -> i32 { return 115 }
micro wasm_magic_byte3() -> i32 { return 109 }

micro wasm_version_1_byte0() -> i32 { return 1 }
micro wasm_version_1_byte1() -> i32 { return 0 }
micro wasm_version_1_byte2() -> i32 { return 0 }
micro wasm_version_1_byte3() -> i32 { return 0 }

micro wasm_push_module_preamble(buf: [i32]) -> [i32] {
    let mut out: [i32] = buf
    out = wasm_push_u8(out, wasm_magic_byte0())
    out = wasm_push_u8(out, wasm_magic_byte1())
    out = wasm_push_u8(out, wasm_magic_byte2())
    out = wasm_push_u8(out, wasm_magic_byte3())
    out = wasm_push_u8(out, wasm_version_1_byte0())
    out = wasm_push_u8(out, wasm_version_1_byte1())
    out = wasm_push_u8(out, wasm_version_1_byte2())
    out = wasm_push_u8(out, wasm_version_1_byte3())
    return out
}

# --- Section ids ---

micro wasm_section_id_type() -> i32 { return 1 }
micro wasm_section_id_import() -> i32 { return 2 }
micro wasm_section_id_function() -> i32 { return 3 }
micro wasm_section_id_table() -> i32 { return 4 }
micro wasm_section_id_memory() -> i32 { return 5 }
micro wasm_section_id_global() -> i32 { return 6 }
micro wasm_section_id_export() -> i32 { return 7 }
micro wasm_section_id_start() -> i32 { return 8 }
micro wasm_section_id_element() -> i32 { return 9 }
micro wasm_section_id_code() -> i32 { return 10 }
micro wasm_section_id_data() -> i32 { return 11 }
micro wasm_section_id_datacount() -> i32 { return 12 }

# --- Export / import kinds ---

micro wasm_exportdesc_func() -> i32 { return 0 }
micro wasm_exportdesc_table() -> i32 { return 1 }
micro wasm_exportdesc_mem() -> i32 { return 2 }
micro wasm_exportdesc_global() -> i32 { return 3 }
micro wasm_importdesc_func() -> i32 { return 0 }

# --- Valtypes / functype form ---

micro wasm_valtype_i32() -> i32 { return 127 }
micro wasm_valtype_i64() -> i32 { return 126 }
micro wasm_valtype_f32() -> i32 { return 125 }
micro wasm_valtype_f64() -> i32 { return 124 }
micro wasm_valtype_funcref() -> i32 { return 112 }
micro wasm_valtype_externref() -> i32 { return 111 }
micro wasm_valtype_anyref() -> i32 { return 110 }
micro wasm_blocktype_empty() -> i32 { return 64 }

# --- Opcodes (leaf subset used by MIR → wasm / WASI core shells) ---

micro wasm_opcode_unreachable() -> i32 { return 0 }
micro wasm_opcode_nop() -> i32 { return 1 }
micro wasm_opcode_block() -> i32 { return 2 }
micro wasm_opcode_loop() -> i32 { return 3 }
micro wasm_opcode_if() -> i32 { return 4 }
micro wasm_opcode_else() -> i32 { return 5 }
micro wasm_opcode_end() -> i32 { return 11 }
micro wasm_opcode_br() -> i32 { return 12 }
micro wasm_opcode_br_if() -> i32 { return 13 }
micro wasm_opcode_return() -> i32 { return 15 }
micro wasm_opcode_call() -> i32 { return 16 }
micro wasm_opcode_drop() -> i32 { return 26 }
micro wasm_opcode_local_get() -> i32 { return 32 }
micro wasm_opcode_local_set() -> i32 { return 33 }
micro wasm_opcode_i32_const() -> i32 { return 65 }
micro wasm_opcode_i32_eqz() -> i32 { return 69 }
micro wasm_opcode_i32_eq() -> i32 { return 70 }
micro wasm_opcode_i32_lt_s() -> i32 { return 72 }
micro wasm_opcode_i32_gt_s() -> i32 { return 74 }
micro wasm_opcode_i32_add() -> i32 { return 106 }
micro wasm_opcode_i32_sub() -> i32 { return 107 }
micro wasm_opcode_i32_mul() -> i32 { return 108 }
micro wasm_opcode_i32_div_s() -> i32 { return 109 }
micro wasm_opcode_i32_rem_s() -> i32 { return 111 }
