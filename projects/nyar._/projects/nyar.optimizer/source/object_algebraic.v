namespace nyar.optimizer;

# Isomorphic to Rust `nyar-optimizer` Object Algebraic boundary.
# E-Graph / rewrite theory land later; this round is the program shell only.

structure ObjectAlgebraicDimension {
    name: utf8
    exported_operations: [utf8]
    required_capabilities: [utf8]
    reference_management_hint: utf8
}

structure AlgebraicTerm {
    kind: utf8
    payload: utf8
}

structure ObjectAlgebraicProgram {
    module_name: utf8
    exports: [utf8]
    dimensions: [ObjectAlgebraicDimension]
    structured_terms: [AlgebraicTerm]
}

unite RewritePhase {
    Normalize
    Saturate
    PreProjection
}

structure RewriteEquation {
    name: utf8
    phase: RewritePhase
    left: utf8
    right: utf8
}

micro empty_object_algebraic_program() -> ObjectAlgebraicProgram {
    return ObjectAlgebraicProgram {
        module_name: "",
        exports: [],
        dimensions: [],
        structured_terms: []
    }
}

micro register_dimension(program: ObjectAlgebraicProgram, dimension: ObjectAlgebraicDimension) -> ObjectAlgebraicProgram {
    let mut out: ObjectAlgebraicProgram = program
    out.dimensions = push(out.dimensions, dimension)
    return out
}
