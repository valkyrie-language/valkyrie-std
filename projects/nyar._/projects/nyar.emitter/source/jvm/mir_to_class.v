namespace nyar.emitter.jvm;

using nyar.emitter.executable;
using std.data.binary.class;

# JVM lane — isomorphic to Rust `nyar-emitter/lowering/backends/jvm`.
# Boundary: ExecutableModule → typed opcode CFG → constant pool + Code bytes
# (`std.data.binary.class` encode). No body_source bypass.
#
# String encoding (mirror CLR lane):
# - `LoadConstString.utf8_source` is language UTF-8; JVM `java.lang.String` is UTF-16.
# - `Utf16Text` → `String.length` / `substring` (code units).
# - `Utf8Text.length` / `slice` → scalar via `codePointCount` / `offsetByCodePoints`
#   (`std.adaptor.jvm.text.Utf8Text`) — never bare `String.length` / `substring`.

# Typed opcodes aligned with ExecutableInstructionKind + CFG terminators.
unite JvmExecutableOpcode {
    Nop
    IConst { value: i32 }
    AConstNull
    LdcString { utf8_source: utf8 }
    ALoadNamed { name: utf8 }
    AStoreNamed { name: utf8 }
    InvokeStatic { callee: utf8 }
    New { type_name: utf8 }
    NewArray { element: utf8 }
    GetField { owner: utf8, field: utf8 }
    PutField { owner: utf8, field: utf8 }
    Dup
    Pop
    IAdd
    ISub
    IMul
    IDiv
    IRem
    INeg
    INot
    ICmpEq
    ICmpLt
    ICmpGt
    IReturn
    Return
    Goto { label: utf8 }
    IfEq { label: utf8 }
    Label { name: utf8 }
}

structure JvmCodeInstruction {
    opcode: JvmExecutableOpcode
}

structure JvmMethodCode {
    name: utf8
    descriptor: utf8
    max_stack: u16
    max_locals: u16
    instructions: [JvmCodeInstruction]
    block_count: u32
}

structure JvmClassCode {
    binary_name: utf8
    methods: [JvmMethodCode]
}

micro empty_jvm_class_code() -> JvmClassCode {
    return JvmClassCode {
        binary_name: "",
        methods: []
    }
}

micro jvm_block_label(id: u32) -> utf8 {
    if id == 0 { return "B0" }
    if id == 1 { return "B1" }
    if id == 2 { return "B2" }
    if id == 3 { return "B3" }
    if id == 4 { return "B4" }
    if id == 5 { return "B5" }
    if id == 6 { return "B6" }
    if id == 7 { return "B7" }
    return "B"
}

micro jvm_resolve_block_label(block: ExecutableBlock) -> utf8 {
    if block.label.length() > 0 {
        return block.label
    }
    return jvm_block_label(block.id.id)
}

micro lower_executable_instruction_kind_to_jvm(kind: ExecutableInstructionKind) -> JvmExecutableOpcode {
    match kind {
        case Nop: { return Nop }
        case LoadConstI32 { value }: { return IConst { value: value } }
        case LoadConstNull: { return AConstNull }
        case LoadConstString { utf8_source }: { return LdcString { utf8_source: utf8_source } }
        case LoadArg { index }: {
            # Real local slot = argument index (static methods: slot 0 = first arg).
            if index == 0 { return ALoadNamed { name: "$arg0" } }
            if index == 1 { return ALoadNamed { name: "$arg1" } }
            if index == 2 { return ALoadNamed { name: "$arg2" } }
            if index == 3 { return ALoadNamed { name: "$arg3" } }
            return ALoadNamed { name: "$arg" }
        }
        case LoadLocal { index }: {
            if index == 0 { return ALoadNamed { name: "$loc0" } }
            if index == 1 { return ALoadNamed { name: "$loc1" } }
            return ALoadNamed { name: "$loc" }
        }
        case StoreLocal { index }: {
            if index == 0 { return AStoreNamed { name: "$loc0" } }
            if index == 1 { return AStoreNamed { name: "$loc1" } }
            return AStoreNamed { name: "$loc" }
        }
        case StoreNamed { name }: { return AStoreNamed { name: name } }
        case LoadSymbol { path }: { return ALoadNamed { name: path } }
        case Call { callee }: { return InvokeStatic { callee: callee } }
        case CallVirt { callee }: { return InvokeStatic { callee: callee } }
        case NewObj { ctor }: { return New { type_name: ctor } }
        case NewArr { element }: { return NewArray { element: element } }
        case Ldfld { owner, field }: { return GetField { owner: owner, field: field } }
        case Stfld { owner, field }: { return PutField { owner: owner, field: field } }
        case Dup: { return Dup }
        case Pop: { return Pop }
        case Add: { return IAdd }
        case Sub: { return ISub }
        case Mul: { return IMul }
        case Div: { return IDiv }
        case Rem: { return IRem }
        case Neg: { return INeg }
        case Not: { return INot }
        case Ceq: { return ICmpEq }
        case Clt: { return ICmpLt }
        case Cgt: { return ICmpGt }
        case Ret: { return IReturn }
    }
}

micro jvm_find_block_by_id(func: ExecutableFunction, id: u32) -> ExecutableBlock {
    let mut i: usize = 0
    while i < func.blocks.length() {
        let block: ExecutableBlock = func.blocks⁅i⁆
        if block.id.id == id {
            return block
        }
        i = i + 1
    }
    return ExecutableBlock {
        id: ExecutableBlockRef { id: id },
        label: jvm_block_label(id),
        instructions: [],
        terminator: Unreachable
    }
}

micro jvm_label_for_block_ref(func: ExecutableFunction, target: ExecutableBlockRef) -> utf8 {
    return jvm_resolve_block_label(jvm_find_block_by_id(func, target.id))
}

micro lower_executable_function_to_jvm_code(func: ExecutableFunction) -> JvmMethodCode {
    let mut instructions: [JvmCodeInstruction] = []
    let mut bi: usize = 0
    while bi < func.blocks.length() {
        let block: ExecutableBlock = func.blocks⁅bi⁆
        let lab: utf8 = jvm_resolve_block_label(block)
        instructions = push(instructions, JvmCodeInstruction { opcode: Label { name: lab } })
        let mut ii: usize = 0
        while ii < block.instructions.length() {
            instructions = push(instructions, JvmCodeInstruction {
                opcode: lower_executable_instruction_kind_to_jvm(block.instructions⁅ii⁆.kind)
            })
            ii = ii + 1
        }
        match block.terminator {
            case ReturnVoid: {
                instructions = push(instructions, JvmCodeInstruction { opcode: Return })
            }
            case ReturnValue: {
                instructions = push(instructions, JvmCodeInstruction { opcode: IReturn })
            }
            case Branch { target }: {
                instructions = push(instructions, JvmCodeInstruction {
                    opcode: Goto { label: jvm_label_for_block_ref(func, target) }
                })
            }
            case CondBranch { then_target, else_target }: {
                # ifeq → else; goto → then (mirror CLR brfalse/br)
                instructions = push(instructions, JvmCodeInstruction {
                    opcode: IfEq { label: jvm_label_for_block_ref(func, else_target) }
                })
                instructions = push(instructions, JvmCodeInstruction {
                    opcode: Goto { label: jvm_label_for_block_ref(func, then_target) }
                })
            }
            case Unreachable: {
                instructions = push(instructions, JvmCodeInstruction { opcode: Nop })
            }
        }
        bi = bi + 1
    }
    let mut desc: utf8 = "()I"
    if func.return_is_void {
        desc = "()V"
    }
    return JvmMethodCode {
        name: func.symbol,
        descriptor: desc,
        max_stack: 8,
        max_locals: func.param_count,
        instructions: instructions,
        block_count: func.blocks.length() as u32
    }
}

micro lower_executable_module_to_jvm_class(module: ExecutableModule) -> JvmClassCode {
    let mut out: JvmClassCode = empty_jvm_class_code()
    out.binary_name = module.name
    let mut fi: usize = 0
    while fi < module.functions.length() {
        out.methods = push(out.methods, lower_executable_function_to_jvm_code(module.functions⁅fi⁆))
        fi = fi + 1
    }
    return out
}

micro jvm_opcode_preview_name(op: JvmExecutableOpcode) -> utf8 {
    match op {
        case Nop: { return "nop" }
        case IConst { value }: { return "iconst" }
        case AConstNull: { return "aconst_null" }
        case LdcString { utf8_source }: { return "ldc" }
        case ALoadNamed { name }: { return "aload" }
        case AStoreNamed { name }: { return "astore" }
        case InvokeStatic { callee }: { return "invokestatic" }
        case New { type_name }: { return "new" }
        case NewArray { element }: { return "newarray" }
        case GetField { owner, field }: { return "getfield" }
        case PutField { owner, field }: { return "putfield" }
        case Dup: { return "dup" }
        case Pop: { return "pop" }
        case IAdd: { return "iadd" }
        case ISub: { return "isub" }
        case IMul: { return "imul" }
        case IDiv: { return "idiv" }
        case IRem: { return "irem" }
        case INeg: { return "ineg" }
        case INot: { return "inot" }
        case ICmpEq: { return "icmpeq" }
        case ICmpLt: { return "icmplt" }
        case ICmpGt: { return "icmpgt" }
        case IReturn: { return "ireturn" }
        case Return: { return "return" }
        case Goto { label }: { return "goto" }
        case IfEq { label }: { return "ifeq" }
        case Label { name }: { return "label" }
    }
}

micro count_jvm_code_opcodes(code: JvmClassCode) -> u32 {
    let mut n: u32 = 0
    let mut mi: usize = 0
    while mi < code.methods.length() {
        n = n + (code.methods⁅mi⁆.instructions.length() as u32)
        mi = mi + 1
    }
    return n
}

micro jvm_synth_label(prefix: utf8, id: u32) -> utf8 {
    if id == 0 { return prefix + "0" }
    if id == 1 { return prefix + "1" }
    if id == 2 { return prefix + "2" }
    if id == 3 { return prefix + "3" }
    if id == 4 { return prefix + "4" }
    if id == 5 { return prefix + "5" }
    if id == 6 { return prefix + "6" }
    if id == 7 { return prefix + "7" }
    return prefix
}

micro jvm_push_flat_raw(flats: [JvmFlatOp], bytes: [i32]) -> [JvmFlatOp] {
    return push(flats, Raw { bytes: bytes })
}

micro jvm_append_compare_to_bool(flats: [JvmFlatOp], kind: utf8, synth: u32) -> [JvmFlatOp] {
    let mut out: [JvmFlatOp] = flats
    let tlab: utf8 = jvm_synth_label("$t", synth)
    let elab: utf8 = jvm_synth_label("$e", synth)
    if kind == "eq" {
        out = push(out, IfICmpEq { label: tlab })
    }
    else if kind == "lt" {
        out = push(out, IfICmpLt { label: tlab })
    }
    else {
        out = push(out, IfICmpGt { label: tlab })
    }
    out = jvm_push_flat_raw(out, jvm_iconst_bytes(0))
    out = push(out, Goto { label: elab })
    out = push(out, Label { name: tlab })
    out = jvm_push_flat_raw(out, jvm_iconst_bytes(1))
    out = push(out, Label { name: elab })
    return out
}

structure JvmLocalTable {
    names: [utf8]
    is_ref: [bool]
    base: u16
}

micro empty_jvm_local_table(param_count: u16) -> JvmLocalTable {
    return JvmLocalTable {
        names: [],
        is_ref: [],
        base: param_count
    }
}

micro jvm_local_find(table: JvmLocalTable, name: utf8) -> i32 {
    let mut i: usize = 0
    while i < table.names.length() {
        if table.names⁅i⁆ == name {
            return i as i32
        }
        i = i + 1
    }
    return -1
}

micro jvm_local_ensure(table: JvmLocalTable, name: utf8, as_ref: bool) -> JvmLocalTable {
    let found: i32 = jvm_local_find(table, name)
    if found >= 0 {
        let mut out: JvmLocalTable = table
        if as_ref {
            let mut refs: [bool] = []
            let mut i: usize = 0
            while i < out.is_ref.length() {
                if (i as i32) == found {
                    refs = push(refs, true)
                }
                else {
                    refs = push(refs, out.is_ref⁅i⁆)
                }
                i = i + 1
            }
            out.is_ref = refs
        }
        return out
    }
    let mut out2: JvmLocalTable = table
    out2.names = push(out2.names, name)
    out2.is_ref = push(out2.is_ref, as_ref)
    return out2
}

micro jvm_local_slot(table: JvmLocalTable, name: utf8) -> u16 {
    let found: i32 = jvm_local_find(table, name)
    if found < 0 {
        return table.base
    }
    return table.base + (found as u16)
}

micro jvm_local_is_ref(table: JvmLocalTable, name: utf8) -> bool {
    let found: i32 = jvm_local_find(table, name)
    if found < 0 {
        return false
    }
    return table.is_ref⁅found as usize⁆
}

micro jvm_local_max(table: JvmLocalTable) -> u16 {
    return table.base + (table.names.length() as u16)
}

micro jvm_build_local_table(method: JvmMethodCode) -> JvmLocalTable {
    let mut table: JvmLocalTable = empty_jvm_local_table(0)
    # Reserve parameter slots 0..param_count-1 as $argN (matches LoadArg lowering).
    let mut p: u16 = 0
    while p < method.max_locals {
        if p == 0 {
            table = jvm_local_ensure(table, "$arg0", false)
        }
        else if p == 1 {
            table = jvm_local_ensure(table, "$arg1", false)
        }
        else if p == 2 {
            table = jvm_local_ensure(table, "$arg2", false)
        }
        else if p == 3 {
            table = jvm_local_ensure(table, "$arg3", false)
        }
        p = p + 1
    }
    let mut prev_ldc: bool = false
    let mut i: usize = 0
    while i < method.instructions.length() {
        let op: JvmExecutableOpcode = method.instructions⁅i⁆.opcode
        match op {
            case LdcString { utf8_source }: {
                prev_ldc = true
            }
            case AStoreNamed { name }: {
                table = jvm_local_ensure(table, name, prev_ldc)
                prev_ldc = false
            }
            case ALoadNamed { name }: {
                table = jvm_local_ensure(table, name, false)
                prev_ldc = false
            }
            case Label { name }: { }
            else: {
                prev_ldc = false
            }
        }
        i = i + 1
    }
    return table
}

micro jvm_string_list_index(texts: [utf8], text: utf8) -> i32 {
    let mut i: usize = 0
    while i < texts.length() {
        if texts⁅i⁆ == text {
            return i as i32
        }
        i = i + 1
    }
    return -1
}

structure JvmCpPlan {
    string_texts: [utf8]
    class_names: [utf8]
    invoke_owners: [utf8]
    invoke_names: [utf8]
    invoke_descs: [utf8]
    invoke_owner_ords: [u16]
}

micro empty_jvm_cp_plan() -> JvmCpPlan {
    return JvmCpPlan {
        string_texts: [],
        class_names: [],
        invoke_owners: [],
        invoke_names: [],
        invoke_descs: [],
        invoke_owner_ords: []
    }
}

# `.` → `/` for JVM binary names (ASCII subset).
micro jvm_dot_to_slash(name: utf8) -> utf8 {
    let mut out: utf8 = ""
    let mut i: i32 = 0
    let n: i32 = name.length()
    while i < n {
        let ch: utf8 = name.slice(i, 1)
        if ch == "." {
            out = out + "/"
        }
        else {
            out = out + ch
        }
        i = i + 1
    }
    return out
}

# Owner before `::`, else whole; normalize dots.
micro jvm_owner_binary_name(raw: utf8) -> utf8 {
    let sep: i32 = raw.index_of("::")
    let mut owner: utf8 = raw
    if sep >= 0 {
        owner = raw.slice(0, sep).trim()
    }
    return jvm_dot_to_slash(owner)
}

# `Owner::name` or `Owner::name(II)I` → name + descriptor (default `()I`).
micro jvm_invoke_method_name(callee: utf8) -> utf8 {
    let sep: i32 = callee.index_of("::")
    let mut rest: utf8 = callee
    if sep >= 0 {
        rest = callee.slice(sep + 2, callee.length() - sep - 2).trim()
    }
    let paren: i32 = rest.index_of("(")
    if paren >= 0 {
        return rest.slice(0, paren).trim()
    }
    return rest
}

micro jvm_invoke_method_desc(callee: utf8) -> utf8 {
    let sep: i32 = callee.index_of("::")
    let mut rest: utf8 = callee
    if sep >= 0 {
        rest = callee.slice(sep + 2, callee.length() - sep - 2).trim()
    }
    let paren: i32 = rest.index_of("(")
    if paren >= 0 {
        return rest.slice(paren, rest.length() - paren).trim()
    }
    return "()I"
}

micro jvm_cp_ensure_class(plan: JvmCpPlan, binary: utf8) -> JvmCpPlan {
    if binary.length() == 0 {
        return plan
    }
    let found: i32 = jvm_string_list_index(plan.class_names, binary)
    if found >= 0 {
        return plan
    }
    let mut out: JvmCpPlan = plan
    out.class_names = push(out.class_names, binary)
    return out
}

micro jvm_cp_class_ord(plan: JvmCpPlan, binary: utf8) -> i32 {
    return jvm_string_list_index(plan.class_names, binary)
}

micro jvm_cp_ensure_invoke(plan: JvmCpPlan, callee: utf8) -> JvmCpPlan {
    let owner: utf8 = jvm_owner_binary_name(callee)
    let name: utf8 = jvm_invoke_method_name(callee)
    let desc: utf8 = jvm_invoke_method_desc(callee)
    if owner.length() == 0 || name.length() == 0 {
        return plan
    }
    let mut out: JvmCpPlan = jvm_cp_ensure_class(plan, owner)
    let mut i: usize = 0
    while i < out.invoke_names.length() {
        if out.invoke_owners⁅i⁆ == owner && out.invoke_names⁅i⁆ == name && out.invoke_descs⁅i⁆ == desc {
            return out
        }
        i = i + 1
    }
    let ord: i32 = jvm_cp_class_ord(out, owner)
    if ord < 0 {
        return out
    }
    out.invoke_owners = push(out.invoke_owners, owner)
    out.invoke_names = push(out.invoke_names, name)
    out.invoke_descs = push(out.invoke_descs, desc)
    out.invoke_owner_ords = push(out.invoke_owner_ords, ord as u16)
    return out
}

micro jvm_cp_invoke_ord(plan: JvmCpPlan, callee: utf8) -> i32 {
    let owner: utf8 = jvm_owner_binary_name(callee)
    let name: utf8 = jvm_invoke_method_name(callee)
    let desc: utf8 = jvm_invoke_method_desc(callee)
    let mut i: usize = 0
    while i < plan.invoke_names.length() {
        if plan.invoke_owners⁅i⁆ == owner && plan.invoke_names⁅i⁆ == name && plan.invoke_descs⁅i⁆ == desc {
            return i as i32
        }
        i = i + 1
    }
    return -1
}

micro jvm_collect_cp_plan(code: JvmClassCode) -> JvmCpPlan {
    let mut plan: JvmCpPlan = empty_jvm_cp_plan()
    let mut mi: usize = 0
    while mi < code.methods.length() {
        let method: JvmMethodCode = code.methods⁅mi⁆
        let mut ii: usize = 0
        while ii < method.instructions.length() {
            match method.instructions⁅ii⁆.opcode {
                case LdcString { utf8_source }: {
                    if jvm_string_list_index(plan.string_texts, utf8_source) < 0 {
                        plan.string_texts = push(plan.string_texts, utf8_source)
                    }
                }
                case New { type_name }: {
                    plan = jvm_cp_ensure_class(plan, jvm_owner_binary_name(type_name))
                }
                case InvokeStatic { callee }: {
                    plan = jvm_cp_ensure_invoke(plan, callee)
                }
                else: { }
            }
            ii = ii + 1
        }
        mi = mi + 1
    }
    return plan
}

# Pool layout: [1]thisName [2]Object [3]thisClass [4]superClass [5]Code
# then S utf8 + S String, C class-utf8 + C Class, then M×(name,desc,NAT,Methodref).
micro jvm_plan_string_cp(plan: JvmCpPlan, literal_ord: u16) -> u16 {
    let s: u16 = plan.string_texts.length() as u16
    return 6 + s + literal_ord
}

micro jvm_plan_string_utf8_cp(literal_ord: u16) -> u16 {
    return 6 + literal_ord
}

# Class entries are (utf8, Class) pairs after 6+2S; Class index = 6+2S+2*ord+1.
micro jvm_plan_class_cp(plan: JvmCpPlan, class_ord: u16) -> u16 {
    let s: u16 = plan.string_texts.length() as u16
    return 6 + s + s + class_ord + class_ord + 1
}

micro jvm_plan_methodref_cp(plan: JvmCpPlan, invoke_ord: u16) -> u16 {
    let s: u16 = plan.string_texts.length() as u16
    let c: u16 = plan.class_names.length() as u16
    # after classes: base = 6+2S+2C; each invoke uses 4 slots; Methodref is last
    let base: u16 = 6 + s + s + c + c
    return base + invoke_ord + invoke_ord + invoke_ord + invoke_ord + 3
}

micro lower_jvm_opcode_to_flat(flats: [JvmFlatOp], op: JvmExecutableOpcode, synth: u32, locals: JvmLocalTable, plan: JvmCpPlan) -> [JvmFlatOp] {
    let mut out: [JvmFlatOp] = flats
    match op {
        case Nop: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 0)
            out = jvm_push_flat_raw(out, b)
        }
        case IConst { value }: {
            out = jvm_push_flat_raw(out, jvm_iconst_bytes(value))
        }
        case AConstNull: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 1)
            out = jvm_push_flat_raw(out, b)
        }
        case LdcString { utf8_source }: {
            let ord: i32 = jvm_string_list_index(plan.string_texts, utf8_source)
            if ord < 0 {
                let mut b: [i32] = []
                b = jvm_push_u8(b, 1)
                out = jvm_push_flat_raw(out, b)
            }
            else {
                let cp: u16 = jvm_plan_string_cp(plan, ord as u16)
                out = push(out, Ldc { index: cp })
            }
        }
        case ALoadNamed { name }: {
            let slot: u16 = jvm_local_slot(locals, name)
            if jvm_local_is_ref(locals, name) {
                out = jvm_push_flat_raw(out, jvm_aload_bytes(slot))
            }
            else {
                out = jvm_push_flat_raw(out, jvm_iload_bytes(slot))
            }
        }
        case AStoreNamed { name }: {
            let slot: u16 = jvm_local_slot(locals, name)
            if jvm_local_is_ref(locals, name) {
                out = jvm_push_flat_raw(out, jvm_astore_bytes(slot))
            }
            else {
                out = jvm_push_flat_raw(out, jvm_istore_bytes(slot))
            }
        }
        case InvokeStatic { callee }: {
            let ord: i32 = jvm_cp_invoke_ord(plan, callee)
            if ord < 0 {
                let mut b: [i32] = []
                b = jvm_push_u8(b, 0)
                out = jvm_push_flat_raw(out, b)
            }
            else {
                let cp: u16 = jvm_plan_methodref_cp(plan, ord as u16)
                out = push(out, InvokeStaticRef { index: cp })
            }
        }
        case New { type_name }: {
            let owner: utf8 = jvm_owner_binary_name(type_name)
            let ord: i32 = jvm_cp_class_ord(plan, owner)
            if ord < 0 {
                let mut b: [i32] = []
                b = jvm_push_u8(b, 0)
                out = jvm_push_flat_raw(out, b)
            }
            else {
                let cp: u16 = jvm_plan_class_cp(plan, ord as u16)
                out = push(out, NewRef { index: cp })
            }
        }
        case NewArray { element }: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 0)
            out = jvm_push_flat_raw(out, b)
        }
        case GetField { owner, field }: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 0)
            out = jvm_push_flat_raw(out, b)
        }
        case PutField { owner, field }: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 0)
            out = jvm_push_flat_raw(out, b)
        }
        case Dup: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 89)
            out = jvm_push_flat_raw(out, b)
        }
        case Pop: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 87)
            out = jvm_push_flat_raw(out, b)
        }
        case IAdd: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 96)
            out = jvm_push_flat_raw(out, b)
        }
        case ISub: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 100)
            out = jvm_push_flat_raw(out, b)
        }
        case IMul: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 104)
            out = jvm_push_flat_raw(out, b)
        }
        case IDiv: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 108)
            out = jvm_push_flat_raw(out, b)
        }
        case IRem: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 112)
            out = jvm_push_flat_raw(out, b)
        }
        case INeg: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 116)
            out = jvm_push_flat_raw(out, b)
        }
        case INot: {
            out = jvm_push_flat_raw(out, jvm_iconst_bytes(1))
            let mut b: [i32] = []
            b = jvm_push_u8(b, 130)
            out = jvm_push_flat_raw(out, b)
        }
        case ICmpEq: {
            out = jvm_append_compare_to_bool(out, "eq", synth)
        }
        case ICmpLt: {
            out = jvm_append_compare_to_bool(out, "lt", synth)
        }
        case ICmpGt: {
            out = jvm_append_compare_to_bool(out, "gt", synth)
        }
        case IReturn: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 172)
            out = jvm_push_flat_raw(out, b)
        }
        case Return: {
            let mut b: [i32] = []
            b = jvm_push_u8(b, 177)
            out = jvm_push_flat_raw(out, b)
        }
        case Goto { label }: {
            out = push(out, Goto { label: label })
        }
        case IfEq { label }: {
            out = push(out, IfEq { label: label })
        }
        case Label { name }: {
            out = push(out, Label { name: name })
        }
    }
    return out
}

micro encode_jvm_method_code_bytes(method: JvmMethodCode, plan: JvmCpPlan) -> JvmEncodedMethod {
    let locals: JvmLocalTable = jvm_build_local_table(method)
    let mut flats: [JvmFlatOp] = []
    let mut synth: u32 = 0
    let mut i: usize = 0
    while i < method.instructions.length() {
        let op: JvmExecutableOpcode = method.instructions⁅i⁆.opcode
        flats = lower_jvm_opcode_to_flat(flats, op, synth, locals, plan)
        match op {
            case ICmpEq: { synth = synth + 1 }
            case ICmpLt: { synth = synth + 1 }
            case ICmpGt: { synth = synth + 1 }
            else: { }
        }
        i = i + 1
    }
    let code_bytes: [i32] = jvm_encode_flat_ops(flats)
    let mut max_locals: u16 = jvm_local_max(locals)
    if max_locals < method.max_locals {
        max_locals = method.max_locals
    }
    if max_locals == 0 {
        max_locals = 1
    }
    return JvmEncodedMethod {
        name: method.name,
        descriptor: method.descriptor,
        max_stack: method.max_stack,
        max_locals: max_locals,
        code_bytes: code_bytes
    }
}

micro encode_jvm_classfile_bytes(module: ExecutableModule) -> [i32] {
    let code: JvmClassCode = lower_executable_module_to_jvm_class(module)
    if code.methods.length() == 0 {
        return []
    }
    let plan: JvmCpPlan = jvm_collect_cp_plan(code)
    let mut encoded_methods: [JvmEncodedMethod] = []
    let mut mi: usize = 0
    while mi < code.methods.length() {
        encoded_methods = push(encoded_methods, encode_jvm_method_code_bytes(code.methods⁅mi⁆, plan))
        mi = mi + 1
    }
    let mut string_utf8_indices: [u16] = []
    let mut si: usize = 0
    while si < plan.string_texts.length() {
        string_utf8_indices = push(string_utf8_indices, jvm_plan_string_utf8_cp(si as u16))
        si = si + 1
    }
    let mut binary_name: utf8 = jvm_dot_to_slash(code.binary_name)
    if binary_name.length() == 0 {
        binary_name = "App"
    }
    return jvm_encode_classfile_with_methods(
        binary_name,
        encoded_methods,
        plan.string_texts,
        string_utf8_indices,
        plan.class_names,
        plan.invoke_owners,
        plan.invoke_names,
        plan.invoke_descs,
        plan.invoke_owner_ords
    )
}

# Lane entry: requires Executable MIR; rejects empty / language body bypass.
micro emit_jvm_from_mir(module: ExecutableModule) -> utf8 {
    if module.functions.length() == 0 {
        return "FAIL: nyar.emitter.jvm: empty ExecutableModule (need Executable MIR; body_source bypass rejected)"
    }
    let code: JvmClassCode = lower_executable_module_to_jvm_class(module)
    let class_bytes: [i32] = encode_jvm_classfile_bytes(module)
    let opcodes: u32 = count_jvm_code_opcodes(code)
    let mut msg: utf8 = "OK-CLASS: nyar.emitter.jvm class="
    msg = msg + code.binary_name
    msg = msg + " methods="
    if code.methods.length() == 0 {
        msg = msg + "0"
    }
    else if code.methods.length() == 1 {
        msg = msg + "1"
    }
    else {
        msg = msg + "n"
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
    msg = msg + " bytes="
    if class_bytes.length() == 0 {
        msg = msg + "0"
    }
    else if class_bytes.length() < 64 {
        msg = msg + "small"
    }
    else {
        msg = msg + "n"
    }
    msg = msg + " (ldc/ldc_w + Methodref/Class + locals + multi-method)"
    return msg
}
