namespace nyar.language.valkyrie;

structure SmokeCompilePlan {
    project_dir: utf8
    project_name: utf8
    output_dir: utf8
    canonical_target: utf8
    emit_msil: bool
    source_files: [utf8]
    dependency_count: usize
}

structure SmokeCompileResult {
    ok: bool
    error: utf8
    output: SmokeBuildOutput
}

structure SmokeBuildOutput {
    assembly_name: utf8
    namespace_symbol: utf8
    console_message: utf8
    source_files: [utf8]
}

structure SmokeClrExtern {
    assembly: utf8
    owner_type: utf8
    method_name: utf8
}

micro empty_smoke_compile_plan() -> SmokeCompilePlan {
    return SmokeCompilePlan {
        project_dir: "",
        project_name: "",
        output_dir: "",
        canonical_target: "",
        emit_msil: false,
        source_files: [],
        dependency_count: 0
    }
}

micro empty_smoke_clr_extern() -> SmokeClrExtern {
    return SmokeClrExtern {
        assembly: "mscorlib",
        owner_type: "System.Console",
        method_name: "WriteLine"
    }
}
