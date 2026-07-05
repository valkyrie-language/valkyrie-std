namespace std.data.binary.wasm;

structure WasmBinaryModule {
    version: u32

    types: [WasmBinaryFuncType]

    imports: [WasmBinaryImport]

    function_type_indices: [u32]

    tables: [WasmBinaryTable]

    memories: [WasmBinaryMemory]

    globals: [WasmBinaryGlobal]

    exports: [WasmBinaryExport]

    start_function_index: i32

    elements: [WasmBinaryElement]

    codes: [WasmBinaryCode]

    data_segments: [WasmBinaryData]

    custom_sections: [WasmBinaryCustomSection]
}

structure WasmBinaryFuncType {
    parameters: [utf8]

    results: [utf8]
}

structure WasmBinaryLimits {
    minimum: u32

    maximum: u32

    has_max: bool
}

structure WasmBinaryImport {
    module: utf8

    field: utf8

    kind: i32

    function_type_index: u32

    table_type: WasmBinaryTableType

    memory_type: WasmBinaryLimits

    global_type: WasmBinaryGlobalType
}

structure WasmBinaryExport {
    name: utf8

    kind: i32

    index: u32
}

structure WasmBinaryTableType {
    element_type: utf8

    limits: WasmBinaryLimits
}

structure WasmBinaryTable {
    table_type: WasmBinaryTableType
}

structure WasmBinaryMemory {
    limits: WasmBinaryLimits
}

structure WasmBinaryGlobalType {
    value_type: utf8

    mutable: bool
}

structure WasmBinaryGlobal {
    global_type: WasmBinaryGlobalType

    init_bytes: [i32]
}

structure WasmBinaryCode {
    body_size: u32

    locals: [WasmBinaryLocal]

    body: [i32]
}

structure WasmBinaryLocal {
    count: u32

    value_type: utf8
}

structure WasmBinaryElement {
    table_index: u32

    offset_bytes: [i32]

    init_values: [u32]
}

structure WasmBinaryData {
    memory_index: u32

    offset_bytes: [i32]

    initializer: [i32]
}

structure WasmBinaryCustomSection {
    name: utf8

    data: [i32]
}
