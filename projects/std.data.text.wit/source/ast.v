namespace std.data.text.wit;

structure WitDocument {
    package: utf8
    definitions: [WitDefinition]
}

[tag(WitDefinitionKind)]
unite WitDefinition {
    Interface(WitInterfaceDef)
    World(WitWorldDef)
    TypeDef(WitTypeDef)
    Use(WitUseDef)
    Include(WitIncludeDef)
}

structure WitInterfaceDef {
    name: utf8
    types: [WitTypeDef]
    functions: [WitFunctionDef]
    resources: [WitResourceDef]
}

structure WitWorldDef {
    name: utf8
    imports: [WitWorldItem]
    exports: [WitWorldItem]
}

structure WitWorldItem {
    name: utf8
    target: utf8
}

[tag(WitTypeDefKind)]
unite WitTypeDef {
    Record(utf8, [WitField])
    Variant(utf8, [WitCase])
    Enum(utf8, [utf8])
    Flags(utf8, [utf8])
    TypeAlias(utf8, utf8)
    Resource(utf8)
}

structure WitField {
    name: utf8
    type_ref: utf8
}

structure WitCase {
    name: utf8
    type_ref: utf8
}

structure WitFunctionDef {
    name: utf8
    is_static: bool
    is_constructor: bool
    parameters: [WitParam]
    results: [WitResult]
}

structure WitParam {
    name: utf8
    type_ref: utf8
}

structure WitResult {
    name: utf8
    type_ref: utf8
}

structure WitResourceDef {
    name: utf8
}

structure WitUseDef {
    path: utf8
    alias: utf8
}

structure WitIncludeDef {
    path: utf8
}
