namespace nyar.language.valkyrie;

using nyar.analyzer;
using nyar.emitter;
using nyar.emitter.executable;
using std.data.text.valkyrie;
using nyar.language.valkyrie.hir;
using nyar.language.valkyrie.mir;

# Language pipeline: AST → HIR → MIR → ExecutableModule → nyar.emitter (any lane).

micro program_facts_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> ProgramFacts {
    let hir: HirModule = hir_from_valkyrie_root(root, module_name)
    let mut facts: ProgramFacts = empty_program_facts()
    facts.module_name = hir.name
    let mut i: usize = 0
    while i < hir.functions.length() {
        let f: HirFunction = hir.functions⁅i⁆
        facts.functions = push(facts.functions, FunctionAnalysis {
            symbol: f.name,
            is_external: f.is_abstract,
            can_suspend: false,
            is_async: false,
            uses_host_interop: false,
            external_import_link: "",
            host_provider_for: "",
            reference_management_hint: ""
        })
        i = i + 1
    }
    return facts
}

micro mir_module_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> MirModule {
    let hir: HirModule = hir_from_valkyrie_root(root, module_name)
    return mir_from_hir_module(hir)
}

micro executable_module_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> ExecutableModule {
    let mir: MirModule = mir_module_from_valkyrie_root(root, module_name)
    return adapt_mir_module_to_executable(mir)
}

# Preferred CLR emit: ExecutableModule → nyar.emitter.clr (not body_source bypass).
micro emit_msil_text_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_clr_from_mir(executable_module)
}

micro emit_jvm_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_jvm_lane(executable_module)
}

micro emit_for_target_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8, target: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_for_target(executable_module, target)
}

# Bootstrap bridge: FragmentSubmission → AST subset → ExecutableModule → emitter.
micro executable_module_from_fragment_submission(submission: FragmentSubmission) -> ExecutableModule {
    let root: ValkyrieRoot = valkyrie_root_from_fragment_submission(submission)
    let mut module_name: utf8 = submission.module_name
    if module_name.length() == 0 {
        module_name = submission_assembly_name(submission)
    }
    return executable_module_from_valkyrie_root(root, module_name)
}

micro emit_clr_from_fragment_submission(submission: FragmentSubmission) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_fragment_submission(submission)
    return emit_clr_from_mir(executable_module)
}

micro emit_jvm_from_fragment_submission(submission: FragmentSubmission) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_fragment_submission(submission)
    return emit_jvm_lane(executable_module)
}

# True when every exported op has a DeclarationBody subset
# (return expr / let+return / simple if / empty).
micro fragment_supports_executable_module_emit(submission: FragmentSubmission) -> bool {
    if submission.exported_operations.length() == 0 {
        return false
    }
    let mut i: usize = 0
    while i < submission.exported_operations.length() {
        let symbol: utf8 = submission.exported_operations⁅i⁆
        let binding: ExternalImportBinding = find_external_binding(submission, symbol)
        if binding.symbol.length() > 0 {
            i = i + 1
            continue
        }
        let body_source: utf8 = find_body_source(submission, symbol)
        let body: DeclarationBody = declaration_body_parse_subset(body_source)
        let trimmed: utf8 = body_source.trim()
        if trimmed.length() > 0 && body.statements.length() == 0 {
            # Non-empty body not covered by subset parser → need legacy or fuller AST.
            return false
        }
        i = i + 1
    }
    return true
}
