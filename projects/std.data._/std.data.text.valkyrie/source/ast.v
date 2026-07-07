namespace std.data.text.valkyrie;

# Isomorphic to Rust `std-data::text::valkyrie::ast` (core shell).
# Full declaration/control-flow nodes land incrementally — not in nyar.language.

structure IdentifierNode {
    name: utf8
    span: TextSpan
}

micro new_identifier_node(name: utf8, start: usize, stop: usize) -> IdentifierNode {
    return IdentifierNode {
        name: name,
        span: TextSpan { start: start, stop: stop }
    }
}

structure NamespaceDeclaration {
    path: utf8
    span: TextSpan
}

structure UsingStatement {
    path: utf8
    span: TextSpan
}

structure FunctionDeclaration {
    name: IdentifierNode
    parameters: [utf8]
    return_type: utf8
    body_present: bool
    body: DeclarationBody
    span: TextSpan
}

structure ClassDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure TraitDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure ImplyDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure UniteDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure AttributeDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure TypeAliasDeclaration {
    name: IdentifierNode
    target: utf8
    span: TextSpan
}

structure FlagsDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure MacroAssignDeclaration {
    name: IdentifierNode
    span: TextSpan
}

structure TestsDeclaration {
    span: TextSpan
}

unite RootStatement {
    Namespace { decl: NamespaceDeclaration }
    Using { stmt: UsingStatement }
    Function { decl: FunctionDeclaration }
    Class { decl: ClassDeclaration }
    Trait { decl: TraitDeclaration }
    Imply { decl: ImplyDeclaration }
    Unite { decl: UniteDeclaration }
    Attribute { decl: AttributeDeclaration }
    TypeAlias { decl: TypeAliasDeclaration }
    Flags { decl: FlagsDeclaration }
    MacroAssign { decl: MacroAssignDeclaration }
    Tests { decl: TestsDeclaration }
}

structure ValkyrieRoot {
    statements: [RootStatement]
}

micro empty_valkyrie_root() -> ValkyrieRoot {
    return ValkyrieRoot {
        statements: []
    }
}
