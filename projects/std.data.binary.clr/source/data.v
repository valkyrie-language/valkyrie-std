namespace std.data.binary.clr;

structure ClrBinaryModule {
    pe_header: ClrPeHeader

    clr_header: ClrClrHeader

    metadata: ClrMetadata

    module_name: utf8

    version: utf8

    types: [ClrTypeDef]

    methods: [ClrMethodDef]
}

structure ClrPeHeader {
    machine: u16

    sections_count: u16

    timestamp: u32

    opt_header_size: u16

    characteristics: u16

    clr_rva: u32

    clr_size: u32
}

structure ClrClrHeader {
    header_size: u32

    major_runtime: u16

    minor_runtime: u16

    metadata_rva: u32

    metadata_size: u32

    attr_flags: u32

    entry_point_token: u32
}

structure ClrMetadata {
    signature: u32

    major_version: u16

    minor_version: u16

    version_string: utf8

    attr_flags: u16

    streams: [ClrStreamHeader]

    table_stream: ClrTableStream

    string_heap: [i32]
}

structure ClrStreamHeader {
    offset: u32

    size: u32

    name: utf8
}

structure ClrTableStream {
    row_counts: [u32]

    tables: [ClrTable]
}

structure ClrTable {
    table_type: i32

    rows: [[i32]]
}

structure ClrTypeDef {
    name: utf8

    namespace: utf8

    attr_flags: u32

    extends_index: u32

    field_list_start: u32

    method_list_start: u32
}

structure ClrMethodDef {
    rva: u32

    impl_flags: u16

    attr_flags: u16

    name: utf8

    signature_index: u16

    body: [i32]
}
