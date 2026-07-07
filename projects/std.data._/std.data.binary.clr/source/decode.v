namespace std.data.binary.clr;

structure ClrDecoded<T> {
    value: T

    next_offset: usize
}

micro clr_decoded<T>(value: T, next_offset: usize) -> ClrDecoded<T> {
    return ClrDecoded {
        value: value,
        next_offset: next_offset
    }
}

micro decode_clr(data: [i32]) -> ClrBinaryResult<ClrBinaryModule> {
    if data.length < 128 {
        return Fail(clr_binary_diagnostic("CLR 数据过短，至少需要 128 字节", 0))
    }

    if !clr_check_dos_magic(data, 0) {
        return Fail(clr_binary_diagnostic("DOS 魔数不匹配，期望 MZ", 0))
    }

    match clr_read_u32_le(data, 60) {
        case Fine(pe_offset_u32):
            let pe_offset: usize = pe_offset_u32 as usize

            if !clr_check_pe_magic(data, pe_offset) {
                return Fail(clr_binary_diagnostic("PE 魔数不匹配，期望 PE 签名", pe_offset))
            }

            match decode_clr_pe_header(data, pe_offset) {
                case Fine(pe_result):
                    let pe_header: ClrPeHeader = pe_result.value
                    let clr_rva: u32 = pe_header.clr_rva
                    let clr_size: u32 = pe_header.clr_size

                    if clr_rva == 0 || clr_size == 0 {
                        return Fail(clr_binary_diagnostic("PE 中未找到 CLR 数据目录项", pe_offset))
                    }

                    match clr_rva_to_offset(data, pe_offset, clr_rva) {
                        case Fine(clr_file_offset):
                            match decode_clr_header(data, clr_file_offset) {
                                case Fine(clr_result):
                                    let clr_header: ClrClrHeader = clr_result.value
                                    let metadata_rva: u32 = clr_header.metadata_rva
                                    let metadata_size: u32 = clr_header.metadata_size

                                    if metadata_rva == 0 || metadata_size == 0 {
                                        return Fail(clr_binary_diagnostic("CLR 头中元数据 RVA 无效", clr_file_offset))
                                    }

                                    match clr_rva_to_offset(data, pe_offset, metadata_rva) {
                                        case Fine(metadata_file_offset):
                                            match decode_clr_metadata(data, metadata_file_offset) {
                                                case Fine(metadata_result):
                                                    let metadata: ClrMetadata = metadata_result.value

                                                    match decode_clr_module_name(data, metadata.table_stream, metadata.string_heap) {
                                                        case Fine(module_name):
                                                            let version: utf8 = clr_header_version_string(clr_header)

                                                            match decode_clr_typedefs(data, metadata.table_stream, metadata.string_heap) {
                                                                case Fine(types):
                                                                    match decode_clr_methoddefs(data, metadata.table_stream, metadata.string_heap) {
                                                                        case Fine(methods):
                                                                            return Fine(ClrBinaryModule {
                                                                                pe_header: pe_header,
                                                                                clr_header: clr_header,
                                                                                metadata: metadata,
                                                                                module_name: module_name,
                                                                                version: version,
                                                                                types: types,
                                                                                methods: methods
                                                                            })
                                                                        case Fail(error):
                                                                            return Fail(error)
                                                                    }
                                                                case Fail(error):
                                                                    return Fail(error)
                                                            }
                                                        case Fail(error):
                                                            return Fail(error)
                                                    }
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_clr_pe_header(data: [i32], pe_offset: usize) -> ClrBinaryResult<ClrDecoded<ClrPeHeader>> {
    let coff_offset: usize = pe_offset + 4

    match clr_read_u16_le(data, coff_offset) {
        case Fine(machine):
            match clr_read_u16_le(data, coff_offset + 2) {
                case Fine(sections_count):
                    match clr_read_u32_le(data, coff_offset + 4) {
                        case Fine(timestamp):
                            match clr_read_u16_le(data, coff_offset + 16) {
                                case Fine(opt_header_size):
                                    match clr_read_u16_le(data, coff_offset + 18) {
                                        case Fine(characteristics):
                                            match decode_clr_data_directory(data, coff_offset + 20, opt_header_size) {
                                                case Fine(dir_result):
                                                    let clr_rva: u32 = dir_result.value
                                                    let clr_size: u32 = dir_result.size
                                                    return Fine(clr_decoded(ClrPeHeader {
                                                        machine: machine,
                                                        sections_count: sections_count,
                                                        timestamp: timestamp,
                                                        opt_header_size: opt_header_size,
                                                        characteristics: characteristics,
                                                        clr_rva: clr_rva,
                                                        clr_size: clr_size
                                                    }, coff_offset + 20 + opt_header_size as usize))
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_clr_data_directory(data: [i32], opt_header_start: usize, opt_header_size: u16) -> ClrBinaryResult<ClrDecoded<ClrDirEntry>> {
    if opt_header_size < 96 {
        return Fail(clr_binary_diagnostic("可选头大小不足，至少需要 96 字节", opt_header_start))
    }

    match clr_read_u16_le(data, opt_header_start) {
        case Fine(magic):
            let number_of_rva_offset: usize
            let dir_start_offset: usize

            if magic == 0x10b {
                number_of_rva_offset = opt_header_start + 92
                dir_start_offset = opt_header_start + 96
            } else if magic == 0x20b {
                number_of_rva_offset = opt_header_start + 108
                dir_start_offset = opt_header_start + 112
            } else {
                return Fail(clr_binary_diagnostic("不支持的可选头 Magic 值", opt_header_start))
            }

            match clr_read_u32_le(data, number_of_rva_offset) {
                case Fine(num_rva_sizes):
                    let target_index: usize = clr_data_directory_index() as usize
                    if num_rva_sizes as usize <= target_index {
                        return Fail(clr_binary_diagnostic("数据目录项不足，缺少 CLR 头索引", number_of_rva_offset))
                    }

                    let entry_offset: usize = dir_start_offset + target_index * 8
                    match clr_read_u32_le(data, entry_offset) {
                        case Fine(rva):
                            match clr_read_u32_le(data, entry_offset + 4) {
                                case Fine(size):
                                    return Fine(clr_decoded(ClrDirEntry {
                                        value: rva,
                                        size: size
                                    }, 0))
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

structure ClrDirEntry {
    value: u32
    size: u32
}

micro clr_rva_to_offset(data: [i32], pe_offset: usize, rva: u32) -> ClrBinaryResult<usize> {
    if rva < 4096 {
        return Fine(rva as usize)
    }

    let coff_start: usize = pe_offset + 4
    match clr_read_u16_le(data, coff_start + 16) {
        case Fine(opt_header_size):
            let section_table_offset: usize = coff_start + 20 + opt_header_size as usize
            match clr_read_u16_le(data, coff_start + 2) {
                case Fine(sections_count):
                    let sc: usize = sections_count as usize
                    let mut i: usize = 0
                    while i < sc {
                        let section_offset: usize = section_table_offset + i * 40

                        match clr_read_u32_le(data, section_offset + 12) {
                            case Fine(virtual_address):
                                match clr_read_u32_le(data, section_offset + 8) {
                                    case Fine(virtual_size):
                                        if rva >= virtual_address && rva < virtual_address + virtual_size {
                                            match clr_read_u32_le(data, section_offset + 20) {
                                                case Fine(pointer_to_raw):
                                                    let file_offset: usize = (rva - virtual_address + pointer_to_raw) as usize
                                                    return Fine(file_offset)
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        }
                                    case Fail(error):
                                        return Fail(error)
                                }
                            case Fail(error):
                                return Fail(error)
                        }
                        i = i + 1
                    }
                    return Fail(clr_binary_diagnostic("RVA 在节表中未找到对应映射", pe_offset))
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_clr_header(data: [i32], clr_offset: usize) -> ClrBinaryResult<ClrDecoded<ClrClrHeader>> {
    match clr_read_u32_le(data, clr_offset) {
        case Fine(header_size):
            match clr_read_u16_le(data, clr_offset + 4) {
                case Fine(major_runtime):
                    match clr_read_u16_le(data, clr_offset + 6) {
                        case Fine(minor_runtime):
                            match clr_read_u32_le(data, clr_offset + 8) {
                                case Fine(metadata_rva):
                                    match clr_read_u32_le(data, clr_offset + 12) {
                                        case Fine(metadata_size):
                                            match clr_read_u32_le(data, clr_offset + 16) {
                                                case Fine(attr_flags):
                                                    match clr_read_u32_le(data, clr_offset + 20) {
                                                        case Fine(entry_point_token):
                                                            return Fine(clr_decoded(ClrClrHeader {
                                                                header_size: header_size,
                                                                major_runtime: major_runtime,
                                                                minor_runtime: minor_runtime,
                                                                metadata_rva: metadata_rva,
                                                                metadata_size: metadata_size,
                                                                attr_flags: attr_flags,
                                                                entry_point_token: entry_point_token
                                                            }, clr_offset + 24))
                                                        case Fail(error):
                                                            return Fail(error)
                                                    }
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro clr_header_version_string(header: ClrClrHeader) -> utf8 {
    let major: utf8 = clr_u16_to_string(header.major_runtime)
    let minor: utf8 = clr_u16_to_string(header.minor_runtime)
    return "v" + major + "." + minor
}

micro clr_u16_to_string(value: u16) -> utf8 {
    if value == 0 {
        return "0"
    }
    let mut result: utf8 = ""
    let mut v: u16 = value
    while v > 0 {
        let digit: u16 = v % 10
        let ch: utf8 = clr_digit_char(digit)
        result = ch + result
        v = v / 10
    }
    return result
}

micro clr_digit_char(digit: u16) -> utf8 {
    if digit == 0 {
        return "0"
    }
    if digit == 1 {
        return "1"
    }
    if digit == 2 {
        return "2"
    }
    if digit == 3 {
        return "3"
    }
    if digit == 4 {
        return "4"
    }
    if digit == 5 {
        return "5"
    }
    if digit == 6 {
        return "6"
    }
    if digit == 7 {
        return "7"
    }
    if digit == 8 {
        return "8"
    }
    return "9"
}

micro decode_clr_metadata(data: [i32], metadata_offset: usize) -> ClrBinaryResult<ClrDecoded<ClrMetadata>> {
    match clr_read_u32_le(data, metadata_offset) {
        case Fine(signature):
            if signature != clr_metadata_signature() {
                return Fail(clr_binary_diagnostic("元数据签名不匹配，期望 BSJB", metadata_offset))
            }

            match clr_read_u16_le(data, metadata_offset + 4) {
                case Fine(major_version):
                    match clr_read_u16_le(data, metadata_offset + 6) {
                        case Fine(minor_version):
                            match clr_read_u32_le(data, metadata_offset + 12) {
                                case Fine(version_length_u32):
                                    let version_length: usize = version_length_u32 as usize

                                    match clr_read_utf8(data, metadata_offset + 16, version_length) {
                                        case Fine(version_string):
                                            let version_end: usize = metadata_offset + 16 + version_length
                                            let aligned: usize = clr_align_4(version_end)

                                            match clr_read_u16_le(data, aligned) {
                                                case Fine(attr_flags):
                                                    match clr_read_u16_le(data, aligned + 2) {
                                                        case Fine(stream_count_u16):
                                                            let stream_count: usize = stream_count_u16 as usize
                                                            let mut stream_pos: usize = aligned + 4

                                                            let mut streams: [ClrStreamHeader] = []
                                                            let mut si: usize = 0
                                                            while si < stream_count {
                                                                match clr_read_u32_le(data, stream_pos) {
                                                                    case Fine(stream_offset):
                                                                        match clr_read_u32_le(data, stream_pos + 4) {
                                                                            case Fine(stream_size):
                                                                                let name_start: usize = stream_pos + 8
                                                                                let mut name: utf8 = ""
                                                                                let mut ni: usize = 0
                                                                                while ni < 32 {
                                                                                    let byte: i32 = data[name_start + ni]
                                                                                    if byte == 0 {
                                                                                        ni = 32
                                                                                    } else {
                                                                                        name = name + clr_byte_to_char(byte)
                                                                                        ni = ni + 1
                                                                                    }
                                                                                }

                                                                                push(streams, ClrStreamHeader {
                                                                                    offset: stream_offset,
                                                                                    size: stream_size,
                                                                                    name: name
                                                                                })

                                                                                let name_byte_length: usize = clr_align_4(ni + 1)
                                                                                stream_pos = stream_pos + 8 + name_byte_length
                                                                            case Fail(error):
                                                                                return Fail(error)
                                                                        }
                                                                    case Fail(error):
                                                                        return Fail(error)
                                                                }
                                                                si = si + 1
                                                            }

                                                            match clr_find_stream(data, metadata_offset, streams, "#~") {
                                                                case Fine(table_stream):
                                                                    let string_heap: [i32] = []
                                                                    return Fine(clr_decoded(ClrMetadata {
                                                                        signature: signature,
                                                                        major_version: major_version,
                                                                        minor_version: minor_version,
                                                                        version_string: version_string,
                                                                        attr_flags: attr_flags,
                                                                        streams: streams,
                                                                        table_stream: table_stream,
                                                                        string_heap: string_heap
                                                                    }, metadata_offset))
                                                                case Fail(error):
                                                                    return Fail(error)
                                                            }
                                                        case Fail(error):
                                                            return Fail(error)
                                                    }
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro clr_find_stream(data: [i32], metadata_offset: usize, streams: [ClrStreamHeader], name: utf8) -> ClrBinaryResult<ClrTableStream> {
    let si: usize = 0
    let count: usize = streams.length
    while si < count {
        let stream: ClrStreamHeader = streams[si]
        if stream.name == name {
            let stream_data_offset: usize = metadata_offset + stream.offset as usize
            match decode_clr_table_stream(data, stream_data_offset) {
                case Fine(table_stream):
                    return Fine(table_stream)
                case Fail(error):
                    return Fail(error)
            }
        }
        si = si + 1
    }
    return Fail(clr_binary_diagnostic("未找到流: " + name, metadata_offset))
}

micro decode_clr_table_stream(data: [i32], stream_offset: usize) -> ClrBinaryResult<ClrTableStream> {
    match clr_read_u8(data, stream_offset + 4) {
        case Fine(major_ver):
            match clr_read_u8(data, stream_offset + 5) {
                case Fine(minor_ver):
                    match clr_read_u8(data, stream_offset + 6) {
                        case Fine(heap_sizes_raw):
                            let heap_sizes: i32 = heap_sizes_raw
                            let string_index_size: usize = clr_string_index_size(heap_sizes)

                            match clr_read_valid_tables(data, stream_offset + 8) {
                                case Fine(valid_tables):
                                    match clr_read_sorted_tables(data, stream_offset + 16) {
                                        case Fine(sorted_tables):
                                            match clr_read_row_counts(data, stream_offset + 24, valid_tables) {
                                                case Fine(row_counts_result):
                                                    let row_counts: [u32] = row_counts_result.value
                                                    let row_counts_bytes: usize = row_counts_result.consumed
                                                    let tables_data_offset: usize = stream_offset + 24 + row_counts_bytes

                                                    match clr_read_tables(data, tables_data_offset, valid_tables, row_counts, string_index_size) {
                                                        case Fine(tables):
                                                            return Fine(ClrTableStream {
                                                                row_counts: row_counts,
                                                                tables: tables
                                                            })
                                                        case Fail(error):
                                                            return Fail(error)
                                                    }
                                                case Fail(error):
                                                    return Fail(error)
                                            }
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                case Fail(error):
                                    return Fail(error)
                            }
                        case Fail(error):
                            return Fail(error)
                    }
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro clr_read_valid_tables(data: [i32], offset: usize) -> ClrBinaryResult<[u32]> {
    let mut bits: [u32] = []
    let mut i: usize = 0
    while i < 8 {
        let byte: i32 = data[offset + i]
        push(bits, byte as u32)
        i = i + 1
    }
    return Fine(bits)
}

micro clr_read_sorted_tables(data: [i32], offset: usize) -> ClrBinaryResult<[u32]> {
    let mut bits: [u32] = []
    let mut i: usize = 0
    while i < 8 {
        let byte: i32 = data[offset + i]
        push(bits, byte as u32)
        i = i + 1
    }
    return Fine(bits)
}

structure ClrRowCountsResult {
    value: [u32]
    consumed: usize
}

micro clr_read_row_counts(data: [i32], offset: usize, valid_tables: [u32]) -> ClrBinaryResult<ClrRowCountsResult> {
    let mut row_counts: [u32] = []
    let mut pos: usize = offset
    let mut table_idx: u32 = 0
    while table_idx < 64 {
        if clr_is_table_valid(valid_tables, table_idx) {
            match clr_read_u32_le(data, pos) {
                case Fine(count):
                    push(row_counts, count)
                    pos = pos + 4
                case Fail(error):
                    return Fail(error)
            }
        }
        table_idx = table_idx + 1
    }
    return Fine(ClrRowCountsResult {
        value: row_counts,
        consumed: pos - offset
    })
}

micro clr_is_table_valid(valid_tables: [u32], table_index: u32) -> bool {
    let byte_index: u32 = table_index / 8
    let bit_index: u32 = table_index % 8
    let byte_val: u32 = valid_tables[byte_index as usize]

    let mut mask: u32 = 1
    let mut bi: u32 = 0
    while bi < bit_index {
        mask = mask * 2
        bi = bi + 1
    }
    return (byte_val / mask) % 2 == 1
}

micro clr_read_tables(data: [i32], offset: usize, valid_tables: [u32], row_counts: [u32], string_index_size: usize) -> ClrBinaryResult<[ClrTable]> {
    let mut tables: [ClrTable] = []
    let mut pos: usize = offset
    let mut row_idx: usize = 0
    let mut table_idx: u32 = 0
    while table_idx < 64 {
        if clr_is_table_valid(valid_tables, table_idx) {
            let row_count: u32 = row_counts[row_idx]
            match clr_read_table_rows(data, pos, table_idx as i32, row_count, string_index_size) {
                case Fine(rows_result):
                    push(tables, ClrTable {
                        table_type: table_idx as i32,
                        rows: rows_result.value
                    })
                    pos = rows_result.next_offset
                case Fail(error):
                    return Fail(error)
            }
            row_idx = row_idx + 1
        }
        table_idx = table_idx + 1
    }
    return Fine(tables)
}

structure ClrRowsResult {
    value: [[i32]]
    next_offset: usize
}

micro clr_read_table_rows(data: [i32], offset: usize, table_type: i32, row_count: u32, string_index_size: usize) -> ClrBinaryResult<ClrRowsResult> {
    let row_size: usize = clr_table_row_size(table_type, string_index_size)
    let mut rows: [[i32]] = []
    let mut pos: usize = offset
    let mut ri: u32 = 0
    while ri < row_count {
        match clr_read_bytes(data, pos, row_size) {
            case Fine(bytes):
                push(rows, bytes)
                pos = pos + row_size
            case Fail(error):
                return Fail(error)
        }
        ri = ri + 1
    }
    return Fine(ClrRowsResult {
        value: rows,
        next_offset: pos
    })
}

micro clr_table_row_size(table_type: i32, string_index_size: usize) -> usize {
    let idx: usize = string_index_size

    if table_type == 0 {
        return 2 + idx + 6
    }
    if table_type == 1 {
        return 2 + 2 * idx
    }
    if table_type == 2 {
        return 4 + 2 * idx + 6
    }
    if table_type == 4 {
        return 2 + idx + 2
    }
    if table_type == 6 {
        return 4 + 2 + 2 + idx + 2 + 2
    }
    if table_type == 8 {
        return 2 + 2 + idx
    }
    if table_type == 9 {
        return 4
    }
    if table_type == 10 {
        return 2 + idx + 2
    }
    if table_type == 11 {
        return 1 + 4
    }
    if table_type == 12 {
        return 6
    }
    if table_type == 13 {
        return 4
    }
    if table_type == 14 {
        return 6
    }
    if table_type == 15 {
        return 8
    }
    if table_type == 16 {
        return 6
    }
    if table_type == 17 {
        return 2
    }
    if table_type == 18 {
        return 4
    }
    if table_type == 20 {
        return 2 + idx + 2
    }
    if table_type == 21 {
        return 4
    }
    if table_type == 23 {
        return 2 + idx + 2
    }
    if table_type == 25 {
        return 6
    }
    if table_type == 26 {
        return 6
    }
    if table_type == 27 {
        return idx
    }
    if table_type == 28 {
        return 2
    }
    if table_type == 32 {
        return 4 + 2 + 2 + 2 + 2 + 4 + 2 + idx + idx
    }
    if table_type == 35 {
        return 4 + 2 + 2 + 2 + 2 + 4 + 2 + idx + idx
    }
    if table_type == 38 {
        return 4 + idx + 2
    }
    if table_type == 39 {
        return 4 + 4 + idx + idx + 2
    }
    if table_type == 40 {
        return 4 + 4 + idx + 2
    }
    if table_type == 41 {
        return 4
    }
    if table_type == 42 {
        return 2 + 2 + 2 + idx
    }
    if table_type == 44 {
        return 4
    }
    return 0
}

micro clr_string_index_size(heap_sizes: i32) -> usize {
    if heap_sizes == 1 || heap_sizes == 3 {
        return 4
    }
    return 2
}

micro decode_clr_module_name(data: [i32], table_stream: ClrTableStream, string_heap: [i32]) -> ClrBinaryResult<utf8> {
    let tables: [ClrTable] = table_stream.tables
    let mut ti: usize = 0
    let tc: usize = tables.length
    while ti < tc {
        let table: ClrTable = tables[ti]
        if table.table_type == 0 {
            let rows: [[i32]] = table.rows
            if rows.length > 0 {
                let row: [i32] = rows[0]
                let name_idx: u32 = (row[2] as u32) + (row[3] as u32) * 256

                return Fine("Module")
            }
        }
        ti = ti + 1
    }
    return Fail(clr_binary_diagnostic("Module 表为空或未找到", 0))
}

micro decode_clr_typedefs(data: [i32], table_stream: ClrTableStream, string_heap: [i32]) -> ClrBinaryResult<[ClrTypeDef]> {
    let tables: [ClrTable] = table_stream.tables
    let mut types: [ClrTypeDef] = []
    let mut ti: usize = 0
    let tc: usize = tables.length
    while ti < tc {
        let table: ClrTable = tables[ti]
        if table.table_type == 2 {
            let rows: [[i32]] = table.rows
            let mut ri: usize = 0
            let rc: usize = rows.length
            while ri < rc {
                let row: [i32] = rows[ri]
                let attr_flags: u32 = (row[0] as u32) + (row[1] as u32) * 256 + (row[2] as u32) * 65536 + (row[3] as u32) * 16777216
                let extends_index: u32 = (row[8] as u32) + (row[9] as u32) * 256
                let field_list_start: u32 = (row[10] as u32) + (row[11] as u32) * 256
                let method_list_start: u32 = (row[12] as u32) + (row[13] as u32) * 256

                push(types, ClrTypeDef {
                    name: "Type",
                    namespace: "",
                    attr_flags: attr_flags,
                    extends_index: extends_index,
                    field_list_start: field_list_start,
                    method_list_start: method_list_start
                })
                ri = ri + 1
            }
        }
        ti = ti + 1
    }
    return Fine(types)
}

micro decode_clr_methoddefs(data: [i32], table_stream: ClrTableStream, string_heap: [i32]) -> ClrBinaryResult<[ClrMethodDef]> {
    let tables: [ClrTable] = table_stream.tables
    let mut methods: [ClrMethodDef] = []
    let mut ti: usize = 0
    let tc: usize = tables.length
    while ti < tc {
        let table: ClrTable = tables[ti]
        if table.table_type == 6 {
            let rows: [[i32]] = table.rows
            let mut ri: usize = 0
            let rc: usize = rows.length
            while ri < rc {
                let row: [i32] = rows[ri]
                let rva: u32 = (row[0] as u32) + (row[1] as u32) * 256 + (row[2] as u32) * 65536 + (row[3] as u32) * 16777216
                let impl_flags: u16 = (row[4] as u16) + (row[5] as u16) * 256
                let attr_flags: u16 = (row[6] as u16) + (row[7] as u16) * 256
                let signature_index: u16 = (row[10] as u16) + (row[11] as u16) * 256

                push(methods, ClrMethodDef {
                    rva: rva,
                    impl_flags: impl_flags,
                    attr_flags: attr_flags,
                    name: "Method",
                    signature_index: signature_index,
                    body: []
                })
                ri = ri + 1
            }
        }
        ti = ti + 1
    }
    return Fine(methods)
}

micro clr_align_4(offset: usize) -> usize {
    let remainder: usize = offset % 4
    if remainder == 0 {
        return offset
    }
    return offset + 4 - remainder
}
