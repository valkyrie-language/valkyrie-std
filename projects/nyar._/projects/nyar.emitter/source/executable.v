namespace nyar.emitter.executable;

# Neutral Executable MIR view — isomorphic to Rust `nyar-emitter::executable_provider`
# (`ExecutableFunction` / `ExecutableBlock` / `ExecutableInstruction` / `ExecutableInstructionKind`).
# Emitter must not depend on `nyar.language`; language drivers adapt into this view.
#
# String encoding: IR text fields use language `utf8` (UTF-8). Hosts differ:
# CLR/JVM/JS strings are UTF-16 code units; WASI CM paths/WIT ids stay UTF-8 bytes.
# Lanes must transcode at the boundary — never assume one encoding everywhere.
# Do not flatten `Utf8Text` and `Utf16Text` onto the same host String length/slice API.
# Language AST lives in `std.data.text.valkyrie` (not `std.data.text.v`).

structure ExecutableBlockRef {
    id: u32
}

unite ExecutableTerminator {
    ReturnVoid
    ReturnValue
    Branch { target: ExecutableBlockRef }
    CondBranch { then_target: ExecutableBlockRef, else_target: ExecutableBlockRef }
    Unreachable
}

unite ExecutableInstructionKind {
    Nop
    LoadConstI32 { value: i32 }
    LoadConstNull
    # Language UTF-8 source text; CLR/JVM/JS hosts store UTF-16 — lane must transcode at emit.
    LoadConstString { utf8_source: utf8 }
    LoadArg { index: u16 }
    LoadLocal { index: u16 }
    StoreLocal { index: u16 }
    StoreNamed { name: utf8 }
    LoadSymbol { path: utf8 }
    Call { callee: utf8 }
    CallVirt { callee: utf8 }
    NewObj { ctor: utf8 }
    NewArr { element: utf8 }
    Ldfld { owner: utf8, field: utf8 }
    Stfld { owner: utf8, field: utf8 }
    Dup
    Pop
    Add
    Sub
    Mul
    Div
    Rem
    Neg
    Not
    Ceq
    Clt
    Cgt
    Ret
}

structure ExecutableInstruction {
    kind: ExecutableInstructionKind
}

structure ExecutableBlock {
    id: ExecutableBlockRef
    label: utf8
    instructions: [ExecutableInstruction]
    terminator: ExecutableTerminator
}

structure ExecutableFunction {
    symbol: utf8
    return_is_void: bool
    param_count: u16
    entry: ExecutableBlockRef
    blocks: [ExecutableBlock]
}

structure ExecutableModule {
    name: utf8
    functions: [ExecutableFunction]
}

micro empty_executable_module() -> ExecutableModule {
    return ExecutableModule {
        name: "",
        functions: []
    }
}
