namespace nyar.emitter.wasm;

using nyar.emitter.executable;
using nyar.emitter.wasi;
using nyar.emitter.wasm.host;
using std.data.binary.wasm;

# WASM lane — isomorphic to Rust `nyar-emitter/lowering/backends/wasm`.
# Boundary: ExecutableModule → typed opcode CFG → `std.data.binary.wasm` bytes.
# Host shells: JS glue (node) / WASI CM (wasip2|wasip3 via `wasi/` + wasi_cm).
#
# Encoding boundary (hard):
# - IR `utf8` / `LoadConstString.utf8_source` = language UTF-8 (Unicode scalars in std).
# - JS host string storage = UTF-16 code units; `env.utf8_*` must index via scalars
#   (`[...s]`), never bare `.length` / `.substring` / `.indexOf`.
# - WASI CM paths / WIT ids = UTF-8 **bytes** at the boundary (no Utf16 indexing).
# No body_source bypass.

unite WasmHostBoundary {
    WasmJsGlue
    WasiComponent
}

# Typed opcodes aligned with ExecutableInstructionKind + CFG terminators.
unite WasmExecutableOpcode {
    Nop
    Unreachable
    I32Const { value: i32 }
    # Language UTF-8 literal → host `env.const_utf8(index)` handle (JS glue).
    ConstUtf8 { literal_index: u32 }
    LocalGet { index: u32 }
    LocalSet { index: u32 }
    Drop
    I32Add
    I32Sub
    I32Mul
    I32DivS
    I32RemS
    I32Neg
    I32Eqz
    I32Eq
    I32LtS
    I32GtS
    CallHost { field: utf8 }
    CallLocal { function_index: u32 }
    Return
    Br { depth: u32 }
    BrIf { depth: u32 }
    BlockStart
    BlockEnd
    Label { name: utf8 }
}

structure WasmCodeInstruction {
    opcode: WasmExecutableOpcode
}

structure WasmFunctionCode {
    name: utf8
    export_name: utf8
    param_count: u16
    return_is_void: bool
    local_i32_count: u32
    instructions: [WasmCodeInstruction]
    block_count: u32
}

structure WasmModuleCode {
    name: utf8
    export_name: utf8
    functions: [WasmFunctionCode]
    utf8_literals: [utf8]
    host_kind: utf8
}

micro empty_wasm_module_code() -> WasmModuleCode {
    return WasmModuleCode {
        name: "",
        export_name: "main",
        functions: [],
        utf8_literals: [],
        host_kind: ""
    }
}

micro wasm_intern_utf8_literal(module: WasmModuleCode, text: utf8) -> WasmModuleCode {
    let mut out: WasmModuleCode = module
    let mut i: usize = 0
    while i < out.utf8_literals.length() {
        if out.utf8_literals⁅i⁆ == text {
            return out
        }
        i = i + 1
    }
    out.utf8_literals = push(out.utf8_literals, text)
    return out
}

micro wasm_utf8_literal_index(module: WasmModuleCode, text: utf8) -> u32 {
    let mut i: usize = 0
    while i < module.utf8_literals.length() {
        if module.utf8_literals⁅i⁆ == text {
            return i as u32
        }
        i = i + 1
    }
    return 0
}

micro lower_executable_instruction_kind_to_wasm(kind: ExecutableInstructionKind, module: WasmModuleCode, param_count: u16) -> WasmExecutableOpcode {
    match kind {
        case Nop: { return Nop }
        case LoadConstI32 { value }: { return I32Const { value: value } }
        case LoadConstNull: { return I32Const { value: 0 } }
        case LoadConstString { utf8_source }: {
            let idx: u32 = wasm_utf8_literal_index(module, utf8_source)
            return ConstUtf8 { literal_index: idx }
        }
        case LoadArg { index }: { return LocalGet { index: index as u32 } }
        case LoadLocal { index }: {
            return LocalGet { index: (param_count as u32) + (index as u32) }
        }
        case StoreLocal { index }: {
            return LocalSet { index: (param_count as u32) + (index as u32) }
        }
        case StoreNamed { name }: { return Drop }
        case LoadSymbol { path }: { return CallHost { field: path } }
        case Call { callee }: { return CallHost { field: callee } }
        case CallVirt { callee }: { return CallHost { field: callee } }
        case NewObj { ctor }: { return CallHost { field: ctor } }
        case NewArr { element }: { return CallHost { field: element } }
        case Ldfld { owner, field }: { return CallHost { field: field } }
        case Stfld { owner, field }: { return CallHost { field: field } }
        case Dup: { return Nop }
        case Pop: { return Drop }
        case Add: { return I32Add }
        case Sub: { return I32Sub }
        case Mul: { return I32Mul }
        case Div: { return I32DivS }
        case Rem: { return I32RemS }
        case Neg: { return I32Neg }
        case Not: { return I32Eqz }
        case Ceq: { return I32Eq }
        case Clt: { return I32LtS }
        case Cgt: { return I32GtS }
        case Ret: { return Return }
    }
}

micro lower_executable_function_to_wasm_code(func: ExecutableFunction, export_name: utf8, module: WasmModuleCode) -> WasmFunctionCode {
    let mut instructions: [WasmCodeInstruction] = []
    let mut bi: usize = 0
    while bi < func.blocks.length() {
        let block: ExecutableBlock = func.blocks⁅bi⁆
        let lab: utf8 = block.label
        if lab.length() == 0 {
            if block.id.id == 0 { instructions = push(instructions, WasmCodeInstruction { opcode: Label { name: "B0" } }) }
            else if block.id.id == 1 { instructions = push(instructions, WasmCodeInstruction { opcode: Label { name: "B1" } }) }
            else if block.id.id == 2 { instructions = push(instructions, WasmCodeInstruction { opcode: Label { name: "B2" } }) }
            else { instructions = push(instructions, WasmCodeInstruction { opcode: Label { name: "B" } }) }
        }
        else {
            instructions = push(instructions, WasmCodeInstruction { opcode: Label { name: lab } })
        }
        let mut ii: usize = 0
        while ii < block.instructions.length() {
            instructions = push(instructions, WasmCodeInstruction {
                opcode: lower_executable_instruction_kind_to_wasm(block.instructions⁅ii⁆.kind, module, func.param_count)
            })
            ii = ii + 1
        }
        match block.terminator {
            case ReturnVoid: {
                instructions = push(instructions, WasmCodeInstruction { opcode: Return })
            }
            case ReturnValue: {
                instructions = push(instructions, WasmCodeInstruction { opcode: Return })
            }
            case Branch { target }: {
                instructions = push(instructions, WasmCodeInstruction { opcode: Br { depth: 0 } })
            }
            case CondBranch { then_target, else_target }: {
                instructions = push(instructions, WasmCodeInstruction { opcode: BrIf { depth: 0 } })
                instructions = push(instructions, WasmCodeInstruction { opcode: Br { depth: 0 } })
            }
            case Unreachable: {
                instructions = push(instructions, WasmCodeInstruction { opcode: Unreachable })
            }
        }
        bi = bi + 1
    }
    let mut locals: u32 = 4
    return WasmFunctionCode {
        name: func.symbol,
        export_name: export_name,
        param_count: func.param_count,
        return_is_void: func.return_is_void,
        local_i32_count: locals,
        instructions: instructions,
        block_count: func.blocks.length() as u32
    }
}

micro lower_executable_module_to_wasm_code(module: ExecutableModule, export_name: utf8, host_kind: utf8) -> WasmModuleCode {
    let mut out: WasmModuleCode = empty_wasm_module_code()
    out.name = module.name
    out.export_name = export_name
    out.host_kind = host_kind
    # First pass: intern UTF-8 string literals (language encoding).
    let mut fi: usize = 0
    while fi < module.functions.length() {
        let func: ExecutableFunction = module.functions⁅fi⁆
        let mut bi: usize = 0
        while bi < func.blocks.length() {
            let block: ExecutableBlock = func.blocks⁅bi⁆
            let mut ii: usize = 0
            while ii < block.instructions.length() {
                match block.instructions⁅ii⁆.kind {
                    case LoadConstString { utf8_source }: {
                        out = wasm_intern_utf8_literal(out, utf8_source)
                    }
                    else: { }
                }
                ii = ii + 1
            }
            bi = bi + 1
        }
        fi = fi + 1
    }
    fi = 0
    while fi < module.functions.length() {
        let f: ExecutableFunction = module.functions⁅fi⁆
        let mut export_for: utf8 = export_name
        if fi > 0 {
            export_for = f.symbol
        }
        out.functions = push(out.functions, lower_executable_function_to_wasm_code(f, export_for, out))
        fi = fi + 1
    }
    return out
}

micro count_wasm_code_opcodes(code: WasmModuleCode) -> u32 {
    let mut n: u32 = 0
    let mut fi: usize = 0
    while fi < code.functions.length() {
        n = n + (code.functions⁅fi⁆.instructions.length() as u32)
        fi = fi + 1
    }
    return n
}

# Leaf opcodes live in `std.data.binary.wasm` (`wasm_encode_*`).
# This match only selects typed encode helpers / MIR expansions.

micro encode_wasm_opcode_bytes(op: WasmExecutableOpcode, host_import_base: u32, host_field_index: u32) -> [i32] {
    match op {
        case Nop: {
            return wasm_encode_nop()
        }
        case Unreachable: {
            return wasm_encode_unreachable()
        }
        case I32Const { value }: {
            return wasm_encode_i32_const(value)
        }
        case ConstUtf8 { literal_index }: {
            return wasm_encode_const_utf8_call(literal_index, host_import_base)
        }
        case LocalGet { index }: {
            return wasm_encode_local_get(index)
        }
        case LocalSet { index }: {
            return wasm_encode_local_set(index)
        }
        case Drop: {
            return wasm_encode_drop()
        }
        case I32Add: {
            return wasm_encode_i32_add()
        }
        case I32Sub: {
            return wasm_encode_i32_sub()
        }
        case I32Mul: {
            return wasm_encode_i32_mul()
        }
        case I32DivS: {
            return wasm_encode_i32_div_s()
        }
        case I32RemS: {
            return wasm_encode_i32_rem_s()
        }
        case I32Neg: {
            return wasm_encode_i32_neg()
        }
        case I32Eqz: {
            return wasm_encode_i32_eqz()
        }
        case I32Eq: {
            return wasm_encode_i32_eq()
        }
        case I32LtS: {
            return wasm_encode_i32_lt_s()
        }
        case I32GtS: {
            return wasm_encode_i32_gt_s()
        }
        case CallHost { field }: {
            return wasm_encode_call(host_import_base + host_field_index)
        }
        case CallLocal { function_index }: {
            return wasm_encode_call(function_index)
        }
        case Return: {
            return wasm_encode_return()
        }
        case Br { depth }: {
            return wasm_encode_br(depth)
        }
        case BrIf { depth }: {
            return wasm_encode_br_if(depth)
        }
        case BlockStart: {
            return wasm_encode_block_empty()
        }
        case BlockEnd: {
            return wasm_encode_end()
        }
        case Label { name }: {
            let empty: [i32] = []
            return empty
        }
    }
}

micro encode_wasm_function_body_opcodes(func: WasmFunctionCode, host_import_base: u32) -> [i32] {
    let mut out: [i32] = []
    let mut i: usize = 0
    while i < func.instructions.length() {
        out = wasm_push_bytes(out, encode_wasm_opcode_bytes(func.instructions⁅i⁆.opcode, host_import_base, 0))
        i = i + 1
    }
    return out
}

micro wasm_i32_params(count: u16) -> [utf8] {
    let mut out: [utf8] = []
    let mut i: u16 = 0
    while i < count {
        out = push(out, "i32")
        i = i + 1
    }
    return out
}

micro wasm_i32_results(is_void: bool) -> [utf8] {
    let mut out: [utf8] = []
    if !is_void {
        out = push(out, "i32")
    }
    return out
}

# Build import list for JS glue: const_utf8 (if literals) + utf8_* method imports.
micro wasm_js_glue_import_funcs(code: WasmModuleCode, handle_type_index: u32) -> [WasmEncodedImportFunc] {
    let mut out: [WasmEncodedImportFunc] = []
    if code.utf8_literals.length() > 0 {
        out = push(out, WasmEncodedImportFunc {
            module: "env",
            field: "const_utf8",
            type_index: handle_type_index
        })
    }
    let fields: [utf8] = js_glue_utf8_host_import_fields()
    let mut i: usize = 0
    while i < fields.length() {
        out = push(out, WasmEncodedImportFunc {
            module: "env",
            field: fields⁅i⁆,
            type_index: handle_type_index
        })
        i = i + 1
    }
    return out
}

micro encode_wasm_module_bytes_from_code(code: WasmModuleCode, boundary: WasmHostBoundary) -> [i32] {
    if code.functions.length() == 0 {
        return []
    }
    let mut functypes: [WasmEncodedFuncType] = []
    # type 0: (param i32) -> i32 — host handle helpers / const_utf8
    let mut host_params: [utf8] = []
    host_params = push(host_params, "i32")
    let mut host_results: [utf8] = []
    host_results = push(host_results, "i32")
    functypes = push(functypes, WasmEncodedFuncType {
        parameters: host_params,
        results: host_results
    })
    # type 1+: defined functions
    let mut fi: usize = 0
    while fi < code.functions.length() {
        let f: WasmFunctionCode = code.functions⁅fi⁆
        functypes = push(functypes, WasmEncodedFuncType {
            parameters: wasm_i32_params(f.param_count),
            results: wasm_i32_results(f.return_is_void)
        })
        fi = fi + 1
    }

    let mut imports: [WasmEncodedImportFunc] = []
    match boundary {
        case WasmJsGlue: {
            imports = wasm_js_glue_import_funcs(code, 0)
        }
        case WasiComponent: {
            # WASI imports declared by source only — empty here (host wasi_cm fills later).
        }
    }

    let import_count: u32 = imports.length() as u32
    let mut function_type_indices: [u32] = []
    fi = 0
    while fi < code.functions.length() {
        function_type_indices = push(function_type_indices, (1 + fi) as u32)
        fi = fi + 1
    }

    let mut exports: [WasmEncodedExport] = []
    if code.functions.length() > 0 {
        exports = push(exports, WasmEncodedExport {
            name: code.export_name,
            kind: 0,
            index: import_count
        })
    }

    let mut bodies: [WasmEncodedFunctionBody] = []
    fi = 0
    while fi < code.functions.length() {
        let f2: WasmFunctionCode = code.functions⁅fi⁆
        let opcodes: [i32] = encode_wasm_function_body_opcodes(f2, 0)
        bodies = push(bodies, WasmEncodedFunctionBody {
            local_i32_count: f2.local_i32_count,
            body_opcodes: opcodes
        })
        fi = fi + 1
    }

    return wasm_encode_module_bytes(functypes, imports, function_type_indices, exports, bodies)
}

# Primary MIR path (fail-closed on empty).
micro emit_wasm_from_mir(module: ExecutableModule, boundary: WasmHostBoundary, preview: WasiPreview) -> utf8 {
    if module.functions.length() == 0 {
        return "FAIL: nyar.emitter.wasm: empty ExecutableModule (need Executable MIR; body_source bypass rejected)"
    }
    let mut export_name: utf8 = "main"
    let mut host_kind: utf8 = "wasm-js-glue"
    match boundary {
        case WasmJsGlue: {
            export_name = "main"
            host_kind = "wasm-js-glue"
        }
        case WasiComponent: {
            export_name = wasi_cli_run_export_name_for(preview)
            host_kind = "wasi-component"
        }
    }
    let code: WasmModuleCode = lower_executable_module_to_wasm_code(module, export_name, host_kind)
    let bytes: [i32] = encode_wasm_module_bytes_from_code(code, boundary)
    let opcodes: u32 = count_wasm_code_opcodes(code)

    match boundary {
        case WasmJsGlue: {
            let host: WasmHostArtifact = lower_executable_to_js_glue(module)
            if !host.ok {
                return host.error
            }
        }
        case WasiComponent: {
            let host2: WasmHostArtifact = lower_executable_to_wasi_cm(module, preview)
            if !host2.ok {
                return host2.error
            }
        }
    }

    let mut msg: utf8 = "OK-WASM: nyar.emitter.wasm name="
    msg = msg + code.name
    msg = msg + " export="
    msg = msg + code.export_name
    msg = msg + " host="
    msg = msg + host_kind
    match boundary {
        case WasiComponent: {
            msg = msg + " preview="
            msg = msg + wasi_preview_name(preview)
        }
        case WasmJsGlue: { }
    }
    msg = msg + " opcodes="
    if opcodes == 0 {
        msg = msg + "0"
    }
    else if opcodes < 10 {
        msg = msg + "few"
    }
    else {
        msg = msg + "n"
    }
    msg = msg + " literals="
    if code.utf8_literals.length() == 0 {
        msg = msg + "0"
    }
    else {
        msg = msg + "n"
    }
    msg = msg + " bytes="
    if bytes.length() == 0 {
        msg = msg + "0"
    }
    else if bytes.length() < 64 {
        msg = msg + "small"
    }
    else {
        msg = msg + "n"
    }
    msg = msg + " (ExecutableModule→opcodes→std.data.binary.wasm; utf8_* scalars / WASI utf8-bytes)"
    return msg
}

micro emit_wasm_js_glue_from_mir(module: ExecutableModule) -> utf8 {
    return emit_wasm_from_mir(module, WasmJsGlue, Preview2)
}

micro emit_wasi_from_mir(module: ExecutableModule, preview: WasiPreview) -> utf8 {
    return emit_wasm_from_mir(module, WasiComponent, preview)
}

micro emit_wasip2_from_mir(module: ExecutableModule) -> utf8 {
    return emit_wasi_from_mir(module, Preview2)
}

micro emit_wasip3_from_mir(module: ExecutableModule) -> utf8 {
    return emit_wasi_from_mir(module, Preview3)
}

# Retained stub shape for callers that only need metadata (no bytes).
structure WasmModuleStub {
    name: utf8
    export_name: utf8
    function_count: u32
    uses_gc: bool
    host_kind: utf8
    wasi_preview: utf8
}

micro empty_wasm_module_stub() -> WasmModuleStub {
    return WasmModuleStub {
        name: "",
        export_name: "",
        function_count: 0,
        uses_gc: true,
        host_kind: "",
        wasi_preview: ""
    }
}

micro lower_executable_module_to_wasm_gc_stub(module: ExecutableModule, export_name: utf8) -> WasmModuleStub {
    return WasmModuleStub {
        name: module.name,
        export_name: export_name,
        function_count: module.functions.length() as u32,
        uses_gc: true,
        host_kind: "mir-gc",
        wasi_preview: ""
    }
}
