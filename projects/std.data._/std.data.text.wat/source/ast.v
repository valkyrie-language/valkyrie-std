namespace std.data.text.wat;

structure WatModule {
    name: utf8
    imports: [WatImport]
    exports: [WatExport]
    functions: [WatFunction]
    memories: [WatMemory]
    tables: [WatTable]
    globals: [WatGlobal]
    data_segments: [WatDataSegment]
    type_definitions: [WatTypeDefinition]
    elem_segments: [WatElemSegment]
    start_function: utf8
}

structure WatTypeDefinition {
    parameters: [utf8]
    results: [utf8]
}

structure WatFunction {
    name: utf8
    parameters: [WatParameter]
    results: [utf8]
    locals: [WatLocal]
    instructions: [WatInstruction]
    export_name: utf8
    import_module: utf8
    import_name: utf8
}

structure WatParameter {
    name: utf8
    value_type: utf8
}

structure WatLocal {
    name: utf8
    value_type: utf8
}

structure WatImport {
    module: utf8
    field: utf8
    descriptor: WatImportDescriptor
}

structure WatExport {
    name: utf8
    kind: utf8
    index: u32
}

structure WatMemory {
    name: utf8
    initial_pages: u32
    max_pages: u32
}

structure WatTable {
    element_type: utf8
    initial_size: u32
    max_size: u32
}

structure WatGlobal {
    name: utf8
    value_type: utf8
    is_mutable: bool
    init_instructions: [WatInstruction]
}

structure WatDataSegment {
    memory_index: u32
    offset_instructions: [WatInstruction]
    data: utf8
}

structure WatElemSegment {
    table: utf8
    offset: utf8
    elements: [utf8]
}

[tag(WatImportDescriptorKind)]
unite WatImportDescriptor {
    Func { value: WatFuncImportDescriptor }
    Memory { value: WatMemoryImportDescriptor }
    Table { value: WatTableImportDescriptor }
    Global { value: WatGlobalImportDescriptor }
}

structure WatFuncImportDescriptor {
    id: utf8
    type_ref: utf8
    parameters: [WatParameter]
    results: [utf8]
}

structure WatMemoryImportDescriptor {
    id: utf8
    min_pages: u32
    max_pages: u32
}

structure WatTableImportDescriptor {
    id: utf8
    element_type: utf8
    min_size: u32
    max_size: u32
}

structure WatGlobalImportDescriptor {
    id: utf8
    is_mutable: bool
    value_type: utf8
}

[tag(WatInstructionKind)]
unite WatInstruction {
    Const { value: WatConstInstruction }
    Variable { value: WatVariableInstruction }
    Call { value: WatCallInstruction }
    Control { value: WatControlInstruction }
    Memory { value: WatMemoryInstruction }
    Simple { value: WatSimpleInstruction }
    Binary { value: WatBinaryInstruction }
    Unary { value: WatUnaryInstruction }
    Compare { value: WatCompareInstruction }
    Generic { value: WatGenericInstruction }
}

structure WatConstInstruction {
    opcode: utf8
    value_type: utf8
    value: utf8
}

structure WatVariableInstruction {
    opcode: utf8
    variable: utf8
}

structure WatCallInstruction {
    opcode: utf8
    function: utf8
    type_ref: utf8
    parameters: [WatParameter]
    results: [utf8]
}

structure WatControlInstruction {
    opcode: utf8
    label: utf8
    results: [utf8]
    body: [WatInstruction]
    else_body: [WatInstruction]
    targets: [utf8]
}

structure WatMemoryInstruction {
    opcode: utf8
    align: utf8
    offset: utf8
}

structure WatSimpleInstruction {
    opcode: utf8
}

structure WatBinaryInstruction {
    opcode: utf8
}

structure WatUnaryInstruction {
    opcode: utf8
}

structure WatCompareInstruction {
    opcode: utf8
}

structure WatGenericInstruction {
    opcode: utf8
    operands: [utf8]
}
