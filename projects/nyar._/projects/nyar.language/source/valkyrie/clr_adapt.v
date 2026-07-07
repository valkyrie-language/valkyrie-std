namespace nyar.language.valkyrie;

using nyar.language.valkyrie.mir;
using nyar.emitter.executable;

# Language MirModule → shared ExecutableModule (driver-side adapt; emitter stays language-free).
# All lanes (CLR / JVM / WASM / WASI) consume ExecutableModule.

micro mir_return_is_void(ty: utf8) -> bool {
    if ty.length() == 0 {
        return true
    }
    if ty == "unit" || ty == "void" {
        return true
    }
    return false
}

micro parse_small_i32(text: utf8) -> i32 {
    if text == "0" || text == "false" { return 0 }
    if text == "1" || text == "true" { return 1 }
    if text == "2" { return 2 }
    if text == "3" { return 3 }
    if text == "4" { return 4 }
    if text == "5" { return 5 }
    if text == "6" { return 6 }
    if text == "7" { return 7 }
    if text == "8" { return 8 }
    if text == "-1" { return -1 }
    return 0
}

# Expand one MIR instruction into Executable ops.
# Composite compares: != → Ceq+Not; <= → Cgt+Not; >= → Clt+Not.
micro adapt_mir_instruction_kinds(kind: MirInstructionKind) -> [ExecutableInstruction] {
    let mut out: [ExecutableInstruction] = []
    match kind {
        case Nop: {
            out = push(out, ExecutableInstruction { kind: Nop })
        }
        case LoadConstant { constant, ty }: {
            if constant == "null" || constant == "unit" {
                out = push(out, ExecutableInstruction { kind: LoadConstNull })
            }
            else if ty == "string" || ty == "utf8" {
                out = push(out, ExecutableInstruction { kind: LoadConstString { utf8_source: constant } })
            }
            else if ty == "i32" || ty == "bool" || ty == "i64" {
                out = push(out, ExecutableInstruction { kind: LoadConstI32 { value: parse_small_i32(constant) } })
            }
            else if constant == "true" {
                out = push(out, ExecutableInstruction { kind: LoadConstI32 { value: 1 } })
            }
            else if constant == "false" {
                out = push(out, ExecutableInstruction { kind: LoadConstI32 { value: 0 } })
            }
            else {
                out = push(out, ExecutableInstruction { kind: LoadConstNull })
            }
        }
        case LoadSymbol { path }: {
            out = push(out, ExecutableInstruction { kind: LoadSymbol { path: path } })
        }
        case Copy { source }: {
            out = push(out, ExecutableInstruction { kind: Dup })
        }
        case StoreVar { name, value, ty }: {
            out = push(out, ExecutableInstruction { kind: StoreNamed { name: name } })
        }
        case Call { callee, arguments }: {
            out = push(out, ExecutableInstruction { kind: Call { callee: callee } })
        }
        case FieldGet { object, field }: {
            out = push(out, ExecutableInstruction { kind: Ldfld { owner: "", field: field } })
        }
        case FieldSet { object, field, value }: {
            out = push(out, ExecutableInstruction { kind: Stfld { owner: "", field: field } })
        }
        case StructNew { type_name, field_names, field_values }: {
            out = push(out, ExecutableInstruction { kind: NewObj { ctor: type_name + "::.ctor" } })
        }
        case TupleNew { field_values }: {
            out = push(out, ExecutableInstruction { kind: NewObj { ctor: "Tuple::.ctor" } })
        }
        case ArrayNew { element_ty, length }: {
            out = push(out, ExecutableInstruction { kind: NewArr { element: element_ty } })
        }
        case ArrayLiteral { element_ty, items }: {
            out = push(out, ExecutableInstruction { kind: NewArr { element: element_ty } })
        }
        case PatternMatch { value, pattern }: {
            out = push(out, ExecutableInstruction { kind: Nop })
        }
        case Binary { op, left, right }: {
            if op == "+" {
                out = push(out, ExecutableInstruction { kind: Add })
            }
            else if op == "-" {
                out = push(out, ExecutableInstruction { kind: Sub })
            }
            else if op == "*" {
                out = push(out, ExecutableInstruction { kind: Mul })
            }
            else if op == "/" {
                out = push(out, ExecutableInstruction { kind: Div })
            }
            else if op == "%" {
                out = push(out, ExecutableInstruction { kind: Rem })
            }
            else if op == "==" {
                out = push(out, ExecutableInstruction { kind: Ceq })
            }
            else if op == "<" {
                out = push(out, ExecutableInstruction { kind: Clt })
            }
            else if op == ">" {
                out = push(out, ExecutableInstruction { kind: Cgt })
            }
            else if op == "!=" {
                out = push(out, ExecutableInstruction { kind: Ceq })
                out = push(out, ExecutableInstruction { kind: Not })
            }
            else if op == "<=" {
                # a <= b ≡ !(a > b)
                out = push(out, ExecutableInstruction { kind: Cgt })
                out = push(out, ExecutableInstruction { kind: Not })
            }
            else if op == ">=" {
                # a >= b ≡ !(a < b)
                out = push(out, ExecutableInstruction { kind: Clt })
                out = push(out, ExecutableInstruction { kind: Not })
            }
            else {
                out = push(out, ExecutableInstruction { kind: Nop })
            }
        }
        case Unary { op, operand }: {
            if op == "-" {
                out = push(out, ExecutableInstruction { kind: Neg })
            }
            else if op == "!" {
                out = push(out, ExecutableInstruction { kind: Not })
            }
            else {
                out = push(out, ExecutableInstruction { kind: Nop })
            }
        }
    }
    return out
}

micro adapt_mir_terminator(term: MirTerminator) -> ExecutableTerminator {
    match term {
        case ReturnVoid: {
            return ReturnVoid
        }
        case Return { value }: {
            return ReturnValue
        }
        case Jump { target }: {
            return Branch { target: ExecutableBlockRef { id: target.id } }
        }
        case CondBranch { cond, then_target, else_target }: {
            return CondBranch {
                then_target: ExecutableBlockRef { id: then_target.id },
                else_target: ExecutableBlockRef { id: else_target.id }
            }
        }
        case Unreachable: {
            return Unreachable
        }
    }
}

micro adapt_mir_function(f: MirFunction) -> ExecutableFunction {
    let mut blocks: [ExecutableBlock] = []
    let mut bi: usize = 0
    while bi < f.blocks.length() {
        let b: MirBlock = f.blocks⁅bi⁆
        let mut instructions: [ExecutableInstruction] = []
        let mut ii: usize = 0
        while ii < b.instructions.length() {
            let expanded: [ExecutableInstruction] = adapt_mir_instruction_kinds(b.instructions⁅ii⁆.kind)
            let mut ei: usize = 0
            while ei < expanded.length() {
                instructions = push(instructions, expanded⁅ei⁆)
                ei = ei + 1
            }
            ii = ii + 1
        }
        blocks = push(blocks, ExecutableBlock {
            id: ExecutableBlockRef { id: b.id.id },
            label: b.label,
            instructions: instructions,
            terminator: adapt_mir_terminator(b.terminator)
        })
        bi = bi + 1
    }
    return ExecutableFunction {
        symbol: f.symbol,
        return_is_void: mir_return_is_void(f.return_type),
        param_count: f.param_types.length() as u16,
        entry: ExecutableBlockRef { id: f.entry.id },
        blocks: blocks
    }
}

micro adapt_mir_module_to_executable(mir: MirModule) -> ExecutableModule {
    let mut out: ExecutableModule = empty_executable_module()
    out.name = mir.name
    let mut fi: usize = 0
    while fi < mir.functions.length() {
        out.functions = push(out.functions, adapt_mir_function(mir.functions⁅fi⁆))
        fi = fi + 1
    }
    return out
}
