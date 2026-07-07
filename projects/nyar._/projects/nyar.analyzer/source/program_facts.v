namespace nyar.analyzer;

# Isomorphic to Rust `nyar-analyzer::ProgramFacts` (language-neutral).
# Symbols are utf8 paths until `nyar.types::QualifiedName` is translated.

structure EntryContract {
    symbol: utf8
    requires_wrapper: bool
}

structure ImportContract {
    path: utf8
    local_name: utf8
}

structure ExportContract {
    exported_name: utf8
    local_name: utf8
    partition: utf8
}

structure RuntimeRequirement {
    key: utf8
    value: utf8
}

structure FunctionAnalysis {
    symbol: utf8
    is_external: bool
    can_suspend: bool
    is_async: bool
    uses_host_interop: bool
    external_import_link: utf8
    host_provider_for: utf8
    reference_management_hint: utf8
}

unite TypeDefinitionKind {
    Enum
    Unite
    Flags
}

structure TypeVariantFact {
    name: utf8
    tag: i32
    has_payload: bool
}

structure TypeDefinitionFact {
    name: utf8
    kind: TypeDefinitionKind
    variants: [TypeVariantFact]
}

structure ProgramFacts {
    module_name: utf8
    entries: [EntryContract]
    imports: [ImportContract]
    exports: [ExportContract]
    functions: [FunctionAnalysis]
    type_definitions: [TypeDefinitionFact]
    capabilities: [utf8]
    reference_management: utf8
    runtime_requirements: [RuntimeRequirement]
}

micro empty_program_facts() -> ProgramFacts {
    return ProgramFacts {
        module_name: "",
        entries: [],
        imports: [],
        exports: [],
        functions: [],
        type_definitions: [],
        capabilities: [],
        reference_management: "",
        runtime_requirements: []
    }
}

micro program_facts_primary_entry(facts: ProgramFacts) -> EntryContract {
    if facts.entries.length() == 0 {
        return EntryContract {
            symbol: "",
            requires_wrapper: false
        }
    }
    return facts.entries⁅0⁆
}
