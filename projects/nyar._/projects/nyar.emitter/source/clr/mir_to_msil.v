namespace nyar.emitter.clr;

using nyar.emitter.executable;
using std.data.text.msil;

# CLR lane — isomorphic to Rust `backends/clr`: ExecutableModule → typed MSIL.
# Shared Executable MIR view (same input shape as jvm/wasm/wasi).
# String literals: `LoadConstString.utf8_source` is UTF-8; MSIL render emits UTF-16 ldstr.
# Method lowering: `Utf16Text` → System.String code-unit APIs; `Utf8Text.length`/`slice`
# must use scalar conversion (`std.adaptor.clr.text.Utf8Text`) — never bare get_Length.
# CFG labels: block labels and Branch/CondBranch targets both use `clr_block_label(id)`
# so human `block.label` text never desyncs from terminator targets.
# Named locals: `StoreNamed` / plain `LoadSymbol` → `.locals init` + ldloc/stloc (full type
# names on Call/Newobj/Ldfld operands stay as-provided — no short-name rewrite).
# Do not expand `clr_body_lowering` body→MSIL bypass.

micro clr_block_label(id: u32) -> utf8 {
    if id == 0 {
        return "B0"
    }
    if id == 1 {
        return "B1"
    }
    if id == 2 {
        return "B2"
    }
    if id == 3 {
        return "B3"
    }
    return "B"
}

micro clr_local_slot_bytes(index: u16, is_store: bool) -> TypedMsilInstruction {
    if is_store {
        if index == 0 { return typed_instr(Stloc0) }
        if index == 1 { return typed_instr(Stloc1) }
        if index == 2 { return typed_instr(Stloc2) }
        if index == 3 { return typed_instr(Stloc3) }
        return TypedMsilInstruction {
            label: "",
            opcode: Stloc,
            operand: Integer { value: index as i64 }
        }
    }
    if index == 0 { return typed_instr(Ldloc0) }
    if index == 1 { return typed_instr(Ldloc1) }
    if index == 2 { return typed_instr(Ldloc2) }
    if index == 3 { return typed_instr(Ldloc3) }
    return TypedMsilInstruction {
        label: "",
        opcode: Ldloc,
        operand: Integer { value: index as i64 }
    }
}

structure ClrNamedLocals {
    names: [utf8]
}

micro empty_clr_named_locals() -> ClrNamedLocals {
    return ClrNamedLocals { names: [] }
}

micro clr_named_local_find(table: ClrNamedLocals, name: utf8) -> i32 {
    let mut i: usize = 0
    while i < table.names.length() {
        if table.names⁅i⁆ == name {
            return i as i32
        }
        i = i + 1
    }
    return -1
}

micro clr_named_local_ensure(table: ClrNamedLocals, name: utf8) -> ClrNamedLocals {
    if name.length() == 0 {
        return table
    }
    if clr_named_local_find(table, name) >= 0 {
        return table
    }
    let mut out: ClrNamedLocals = table
    out.names = push(out.names, name)
    return out
}

micro clr_collect_named_locals(func: ExecutableFunction) -> ClrNamedLocals {
    let mut table: ClrNamedLocals = empty_clr_named_locals()
    let mut bi: usize = 0
    while bi < func.blocks.length() {
        let block: ExecutableBlock = func.blocks⁅bi⁆
        let mut ii: usize = 0
        while ii < block.instructions.length() {
            match block.instructions⁅ii⁆.kind {
                case StoreNamed { name }: {
                    table = clr_named_local_ensure(table, name)
                }
                case LoadSymbol { path }: {
                    # Paths without `::` / `.` are treated as local names (let bindings).
                    if path.index_of("::") < 0 && path.index_of(".") < 0 {
                        table = clr_named_local_ensure(table, path)
                    }
                }
                else: { }
            }
            ii = ii + 1
        }
        bi = bi + 1
    }
    return table
}

micro lower_executable_instruction_kind_to_msil(kind: ExecutableInstructionKind, locals: ClrNamedLocals) -> TypedMsilInstruction {
    match kind {
        case Nop: {
            return typed_instr(Nop)
        }
        case LoadConstNull: {
            return typed_instr(Ldnull)
        }
        case LoadConstString { utf8_source }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Ldstr,
                operand: StringLiteral { utf8_source: utf8_source }
            }
        }
        case LoadConstI32 { value }: {
            if value == -1 {
                return typed_instr(LdcI4M1)
            }
            if value == 0 {
                return typed_instr(LdcI4_0)
            }
            if value == 1 {
                return typed_instr(LdcI4_1)
            }
            if value == 2 {
                return typed_instr(LdcI4_2)
            }
            if value == 3 {
                return typed_instr(LdcI4_3)
            }
            if value == 4 {
                return typed_instr(LdcI4_4)
            }
            if value == 5 {
                return typed_instr(LdcI4_5)
            }
            if value == 6 {
                return typed_instr(LdcI4_6)
            }
            if value == 7 {
                return typed_instr(LdcI4_7)
            }
            if value == 8 {
                return typed_instr(LdcI4_8)
            }
            return TypedMsilInstruction {
                label: "",
                opcode: LdcI4,
                operand: Integer { value: value as i64 }
            }
        }
        case LoadArg { index }: {
            if index == 0 {
                return typed_instr(Ldarg0)
            }
            if index == 1 {
                return typed_instr(Ldarg1)
            }
            if index == 2 {
                return typed_instr(Ldarg2)
            }
            if index == 3 {
                return typed_instr(Ldarg3)
            }
            return TypedMsilInstruction {
                label: "",
                opcode: Ldarg,
                operand: Integer { value: index as i64 }
            }
        }
        case LoadLocal { index }: {
            return clr_local_slot_bytes(index, false)
        }
        case StoreLocal { index }: {
            return clr_local_slot_bytes(index, true)
        }
        case StoreNamed { name }: {
            let slot: i32 = clr_named_local_find(locals, name)
            if slot < 0 {
                return typed_instr(Pop)
            }
            return clr_local_slot_bytes(slot as u16, true)
        }
        case LoadSymbol { path }: {
            let slot: i32 = clr_named_local_find(locals, path)
            if slot >= 0 {
                return clr_local_slot_bytes(slot as u16, false)
            }
            # Unresolved symbol — keep visible; full type/member paths land via Call/Ldfld.
            return TypedMsilInstruction {
                label: "",
                opcode: Ldnull,
                operand: Raw { value: "/*sym " + path + "*/" }
            }
        }
        case Call { callee }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Call,
                operand: Symbol { value: callee }
            }
        }
        case CallVirt { callee }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Callvirt,
                operand: Symbol { value: callee }
            }
        }
        case NewObj { ctor }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Newobj,
                operand: Symbol { value: ctor }
            }
        }
        case NewArr { element }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Newarr,
                operand: TypeName { value: element }
            }
        }
        case Ldfld { owner, field }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Ldfld,
                operand: Field { owner: owner, name: field }
            }
        }
        case Stfld { owner, field }: {
            return TypedMsilInstruction {
                label: "",
                opcode: Stfld,
                operand: Field { owner: owner, name: field }
            }
        }
        case Dup: {
            return typed_instr(Dup)
        }
        case Pop: {
            return typed_instr(Pop)
        }
        case Add: {
            return typed_instr(Add)
        }
        case Sub: {
            return typed_instr(Sub)
        }
        case Mul: {
            return typed_instr(Mul)
        }
        case Div: {
            return typed_instr(Div)
        }
        case Rem: {
            return typed_instr(Rem)
        }
        case Neg: {
            return typed_instr(Neg)
        }
        case Not: {
            return typed_instr(Not)
        }
        case Ceq: {
            return typed_instr(Ceq)
        }
        case Clt: {
            return typed_instr(Clt)
        }
        case Cgt: {
            return typed_instr(Cgt)
        }
        case Ret: {
            return typed_instr(Ret)
        }
    }
}

micro lower_executable_function_to_msil(func: ExecutableFunction) -> TypedMsilMethodBody {
    let named: ClrNamedLocals = clr_collect_named_locals(func)
    let mut sig: MsilMethodSignature = empty_msil_signature()
    if func.return_is_void {
        sig.return_type = Void
    }
    else {
        sig.return_type = Object
    }
    let mut local_tys: [MsilType] = []
    let mut li: usize = 0
    while li < named.names.length() {
        local_tys = push(local_tys, Object)
        li = li + 1
    }
    let mut body: TypedMsilMethodBody = TypedMsilMethodBody {
        method: MsilMethodRef {
            owner: "",
            name: func.symbol,
            signature: sig
        },
        locals: local_tys,
        instructions: [],
        max_stack: 8,
        is_entry_point: false,
        is_async: false
    }
    let mut bi: usize = 0
    while bi < func.blocks.length() {
        let block: ExecutableBlock = func.blocks⁅bi⁆
        let mut lab: utf8 = clr_block_label(block.id.id)
        body.instructions = push(body.instructions, typed_instr_labeled(lab, Nop))
        let mut ii: usize = 0
        while ii < block.instructions.length() {
            body.instructions = push(body.instructions, lower_executable_instruction_kind_to_msil(block.instructions⁅ii⁆.kind, named))
            ii = ii + 1
        }
        match block.terminator {
            case ReturnVoid: {
                body.instructions = push(body.instructions, typed_instr(Ret))
            }
            case ReturnValue: {
                body.instructions = push(body.instructions, typed_instr(Ret))
            }
            case Branch { target }: {
                body.instructions = push(body.instructions, TypedMsilInstruction {
                    label: "",
                    opcode: Br,
                    operand: BranchTarget { label: clr_block_label(target.id) }
                })
            }
            case CondBranch { then_target, else_target }: {
                body.instructions = push(body.instructions, TypedMsilInstruction {
                    label: "",
                    opcode: Brfalse,
                    operand: BranchTarget { label: clr_block_label(else_target.id) }
                })
                body.instructions = push(body.instructions, TypedMsilInstruction {
                    label: "",
                    opcode: Br,
                    operand: BranchTarget { label: clr_block_label(then_target.id) }
                })
            }
            case Unreachable: {
                body.instructions = push(body.instructions, typed_instr(Nop))
            }
        }
        bi = bi + 1
    }
    if body.instructions.length() == 0 {
        body.instructions = push(body.instructions, typed_instr(Ret))
    }
    return body
}

micro lower_executable_module_to_typed_msil(module: ExecutableModule) -> TypedMsilModule {
    let mut out: TypedMsilModule = empty_typed_msil_module()
    out.assembly.name = module.name
    let mut fi: usize = 0
    while fi < module.functions.length() {
        out.global_methods = push(out.global_methods, lower_executable_function_to_msil(module.functions⁅fi⁆))
        fi = fi + 1
    }
    return out
}
