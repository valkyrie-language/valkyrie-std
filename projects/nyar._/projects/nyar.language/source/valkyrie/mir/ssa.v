namespace nyar.language.valkyrie.mir;

using nyar.language.valkyrie.hir;
using std.data.text.valkyrie;

# Isomorphic shell of Rust `nyar-language::valkyrie::mir::ssa`.

structure MirBlockRef {
    id: u32
}

structure MirValueRef {
    id: u32
}

structure MirField {
    name: utf8
    ty: utf8
}

structure MirStruct {
    name: utf8
    namespace_name: utf8
    fields: [MirField]
    is_value_type: bool
}

unite MirTerminator {
    ReturnVoid
    Return { value: utf8 }
    Jump { target: MirBlockRef }
    CondBranch { cond: utf8, then_target: MirBlockRef, else_target: MirBlockRef }
    Unreachable
}

# Core instruction kinds aligned with Rust MirInstructionKind (flat operands this round).
unite MirInstructionKind {
    LoadConstant { constant: utf8, ty: utf8 }
    LoadSymbol { path: utf8 }
    Copy { source: utf8 }
    StoreVar { name: utf8, value: utf8, ty: utf8 }
    Call { callee: utf8, arguments: [utf8] }
    StructNew { type_name: utf8, field_names: [utf8], field_values: [utf8] }
    TupleNew { field_values: [utf8] }
    FieldGet { object: utf8, field: utf8 }
    FieldSet { object: utf8, field: utf8, value: utf8 }
    ArrayNew { element_ty: utf8, length: utf8 }
    ArrayLiteral { element_ty: utf8, items: [utf8] }
    PatternMatch { value: utf8, pattern: utf8 }
    Binary { op: utf8, left: utf8, right: utf8 }
    Unary { op: utf8, operand: utf8 }
    Nop
}

structure MirInstruction {
    result: MirValueRef
    kind: MirInstructionKind
}

structure MirBlock {
    id: MirBlockRef
    label: utf8
    parameters: [MirValueRef]
    instructions: [MirInstruction]
    terminator: MirTerminator
}

structure MirFunction {
    symbol: utf8
    return_type: utf8
    param_types: [utf8]
    entry: MirBlockRef
    blocks: [MirBlock]
}

structure MirModule {
    name: utf8
    functions: [MirFunction]
    structs: [MirStruct]
    imports: [utf8]
}

structure MirLowerState {
    next_value: u32
    next_block_id: u32
    current_block_id: u32
    current_label: utf8
    instructions: [MirInstruction]
    blocks: [MirBlock]
    return_value: utf8
    has_return: bool
}

micro empty_mir_module() -> MirModule {
    return MirModule {
        name: "",
        functions: [],
        structs: [],
        imports: []
    }
}

micro mir_no_result() -> MirValueRef {
    return MirValueRef { id: 0 }
}

micro mir_push(state: MirLowerState, kind: MirInstructionKind) -> MirLowerState {
    let mut out: MirLowerState = state
    let result: MirValueRef = MirValueRef { id: out.next_value }
    out.next_value = out.next_value + 1
    out.instructions = push(out.instructions, MirInstruction {
        result: result,
        kind: kind
    })
    return out
}

micro mir_value_name(id: u32) -> utf8 {
    if id == 0 { return "v0" }
    if id == 1 { return "v1" }
    if id == 2 { return "v2" }
    if id == 3 { return "v3" }
    if id == 4 { return "v4" }
    if id == 5 { return "v5" }
    if id == 6 { return "v6" }
    if id == 7 { return "v7" }
    return "v"
}

micro mir_close_block(state: MirLowerState, terminator: MirTerminator) -> MirLowerState {
    let mut out: MirLowerState = state
    out.blocks = push(out.blocks, MirBlock {
        id: MirBlockRef { id: out.current_block_id },
        label: out.current_label,
        parameters: [],
        instructions: out.instructions,
        terminator: terminator
    })
    out.instructions = []
    return out
}

micro mir_open_block(state: MirLowerState, block_id: u32, label: utf8) -> MirLowerState {
    let mut out: MirLowerState = state
    out.current_block_id = block_id
    out.current_label = label
    out.instructions = []
    return out
}

micro mir_alloc_block(state: MirLowerState) -> MirLowerState {
    let mut out: MirLowerState = state
    out.next_block_id = out.next_block_id + 1
    return out
}

micro mir_lower_operand_text(state: MirLowerState, text: utf8) -> MirLowerState {
    let t: utf8 = text.trim()
    if t.length() == 0 {
        return mir_push(state, LoadConstant { constant: "null", ty: "object" })
    }
    let term: TermExpression = term_from_expression_text(t)
    match term {
        case Binary { op, left, right }: {
            return mir_lower_expr(state, hir_expr_from_term(term))
        }
        case Unary { op, operand }: {
            return mir_lower_expr(state, hir_expr_from_term(term))
        }
        case Literal { lit }: {
            return mir_lower_expr(state, hir_expr_from_term(term))
        }
        case Name { path }: {
            return mir_push(state, LoadSymbol { path: path })
        }
        case Unit: {
            return mir_push(state, LoadConstant { constant: "unit", ty: "unit" })
        }
        else: {
            return mir_lower_expr(state, hir_expr_from_term(term))
        }
    }
}

micro mir_lower_expr(state: MirLowerState, expr: HirExpr) -> MirLowerState {
    match expr.kind {
        case Unit: {
            return mir_push(state, LoadConstant { constant: "unit", ty: "unit" })
        }
        case IntegerLiteral { text }: {
            return mir_push(state, LoadConstant { constant: text, ty: "i32" })
        }
        case FloatLiteral { text }: {
            return mir_push(state, LoadConstant { constant: text, ty: "f64" })
        }
        case StringLiteral { text }: {
            return mir_push(state, LoadConstant { constant: text, ty: "utf8" })
        }
        case BoolLiteral { value }: {
            if value {
                return mir_push(state, LoadConstant { constant: "true", ty: "bool" })
            }
            return mir_push(state, LoadConstant { constant: "false", ty: "bool" })
        }
        case NullLiteral: {
            return mir_push(state, LoadConstant { constant: "null", ty: "object" })
        }
        case Name { path }: {
            return mir_push(state, LoadSymbol { path: path })
        }
        case Call { callee, arguments }: {
            return mir_push(state, Call { callee: callee, arguments: arguments })
        }
        case Field { object, field }: {
            return mir_push(state, FieldGet { object: object, field: field })
        }
        case Binary { op, left, right }: {
            let mut s: MirLowerState = mir_lower_operand_text(state, left)
            let left_v: utf8 = mir_value_name(s.next_value - 1)
            s = mir_lower_operand_text(s, right)
            let right_v: utf8 = mir_value_name(s.next_value - 1)
            return mir_push(s, Binary { op: op, left: left_v, right: right_v })
        }
        case Unary { op, operand }: {
            let mut s: MirLowerState = mir_lower_operand_text(state, operand)
            let operand_v: utf8 = mir_value_name(s.next_value - 1)
            return mir_push(s, Unary { op: op, operand: operand_v })
        }
    }
}

micro mir_lower_block_statements(state: MirLowerState, block: HirBlock) -> MirLowerState {
    let mut s: MirLowerState = state
    let mut si: usize = 0
    while si < block.statements.length() {
        s = mir_lower_statement(s, block.statements⁅si⁆)
        si = si + 1
    }
    if block.has_tail && !s.has_return {
        s = mir_lower_expr(s, block.tail)
        s.has_return = true
        if s.next_value > 0 {
            s.return_value = mir_value_name(s.next_value - 1)
        }
    }
    return s
}

micro mir_lower_statement(state: MirLowerState, stmt: HirStatement) -> MirLowerState {
    match stmt.kind {
        case Let { is_mutable, name, ty, has_init, init }: {
            let mut s: MirLowerState = state
            let mut value_name: utf8 = ""
            if has_init {
                s = mir_lower_expr(s, init)
                if s.next_value > 0 {
                    value_name = mir_value_name(s.next_value - 1)
                }
            }
            else {
                s = mir_push(s, LoadConstant { constant: "null", ty: ty })
                value_name = mir_value_name(s.next_value - 1)
            }
            return mir_push(s, StoreVar { name: name, value: value_name, ty: ty })
        }
        case Expr { expr }: {
            return mir_lower_expr(state, expr)
        }
        case Return { has_value, value }: {
            let mut s: MirLowerState = state
            if has_value {
                s = mir_lower_expr(s, value)
                s.has_return = true
                if s.next_value > 0 {
                    s.return_value = mir_value_name(s.next_value - 1)
                }
            }
            else {
                s.has_return = true
                s.return_value = ""
            }
            return s
        }
        case If { condition, then_body, has_else, else_body }: {
            let mut s: MirLowerState = mir_lower_expr(state, condition)
            let mut cond_name: utf8 = "v0"
            if s.next_value > 0 {
                cond_name = mir_value_name(s.next_value - 1)
            }
            let then_id: u32 = s.next_block_id
            s = mir_alloc_block(s)
            let else_id: u32 = s.next_block_id
            s = mir_alloc_block(s)
            let join_id: u32 = s.next_block_id
            s = mir_alloc_block(s)
            s = mir_close_block(s, CondBranch {
                cond: cond_name,
                then_target: MirBlockRef { id: then_id },
                else_target: MirBlockRef { id: else_id }
            })
            s = mir_open_block(s, then_id, "then")
            s = mir_lower_block_statements(s, then_body)
            s = mir_close_block(s, Jump { target: MirBlockRef { id: join_id } })
            s = mir_open_block(s, else_id, "else")
            if has_else {
                s = mir_lower_block_statements(s, else_body)
            }
            s = mir_close_block(s, Jump { target: MirBlockRef { id: join_id } })
            s = mir_open_block(s, join_id, "join")
            return s
        }
        case Break: {
            return mir_push(state, Nop)
        }
        case Continue: {
            return mir_push(state, Nop)
        }
    }
}

micro mir_function_from_hir(f: HirFunction, entry_block_id: u32) -> MirFunction {
    let mut param_types: [utf8] = []
    let mut pi: usize = 0
    while pi < f.params.length() {
        param_types = push(param_types, f.params⁅pi⁆.ty)
        pi = pi + 1
    }
    let mut state: MirLowerState = MirLowerState {
        next_value: 1,
        next_block_id: entry_block_id + 1,
        current_block_id: entry_block_id,
        current_label: "entry",
        instructions: [],
        blocks: [],
        return_value: "",
        has_return: false
    }
    state = mir_lower_block_statements(state, f.body)
    let mut term: MirTerminator = ReturnVoid
    if state.has_return {
        if state.return_value.length() == 0 {
            term = ReturnVoid
        }
        else {
            term = Return { value: state.return_value }
        }
    }
    else if f.return_type.length() > 0 && f.return_type != "unit" && f.return_type != "void" {
        state = mir_push(state, LoadConstant { constant: "null", ty: f.return_type })
        term = Return { value: mir_value_name(state.next_value - 1) }
    }
    state = mir_close_block(state, term)
    let mut symbol: utf8 = f.name
    if f.declaring_namespace.length() > 0 {
        symbol = f.declaring_namespace + "." + f.name
    }
    return MirFunction {
        symbol: symbol,
        return_type: f.return_type,
        param_types: param_types,
        entry: MirBlockRef { id: entry_block_id },
        blocks: state.blocks
    }
}

# HIR → MIR (SSA-ish values + body statements; If → CondBranch CFG).
micro mir_from_hir_module(hir: HirModule) -> MirModule {
    let mut mir: MirModule = empty_mir_module()
    mir.name = hir.name
    let mut ii: usize = 0
    while ii < hir.imports.length() {
        mir.imports = push(mir.imports, hir.imports⁅ii⁆.path)
        ii = ii + 1
    }
    let mut si: usize = 0
    while si < hir.structs.length() {
        let s: HirStruct = hir.structs⁅si⁆
        let mut fields: [MirField] = []
        let mut fi: usize = 0
        while fi < s.fields.length() {
            fields = push(fields, MirField {
                name: s.fields⁅fi⁆.name,
                ty: s.fields⁅fi⁆.ty
            })
            fi = fi + 1
        }
        mir.structs = push(mir.structs, MirStruct {
            name: s.name,
            namespace_name: s.namespace_name,
            fields: fields,
            is_value_type: s.is_value_type
        })
        si = si + 1
    }
    let mut fi2: usize = 0
    let mut next_block: u32 = 0
    while fi2 < hir.functions.length() {
        let mf: MirFunction = mir_function_from_hir(hir.functions⁅fi2⁆, next_block)
        mir.functions = push(mir.functions, mf)
        let mut max_id: u32 = next_block
        let mut bi: usize = 0
        while bi < mf.blocks.length() {
            if mf.blocks⁅bi⁆.id.id >= max_id {
                max_id = mf.blocks⁅bi⁆.id.id + 1
            }
            bi = bi + 1
        }
        next_block = max_id
        fi2 = fi2 + 1
    }
    return mir
}
