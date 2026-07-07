namespace std.data.binary.wasm;

micro decode_wasm(data: [i32]) -> WasmBinaryResult<WasmBinaryModule> {
    if data.length < 8 {
        return Fail(wasm_binary_diagnostic("WASM 数据过短，至少需要 8 字节头部", 0))
    }

    if !wasm_check_magic(data, 0) {
        return Fail(wasm_binary_diagnostic("WASM 魔数不匹配，期望 \\0asm", 0))
    }

    match wasm_read_u32_le(data, 4) {
        case Fine(version_result):
            let version: u32 = version_result.value
            let mut offset: usize = 8

            if version != 1 {
            }

            let mut types: [WasmBinaryFuncType] = []
            let mut imports: [WasmBinaryImport] = []
            let mut function_type_indices: [u32] = []
            let mut tables: [WasmBinaryTable] = []
            let mut memories: [WasmBinaryMemory] = []
            let mut globals: [WasmBinaryGlobal] = []
            let mut exports: [WasmBinaryExport] = []
            let mut start_function_index: i32 = -1
            let mut elements: [WasmBinaryElement] = []
            let mut codes: [WasmBinaryCode] = []
            let mut data_segments: [WasmBinaryData] = []
            let mut custom_sections: [WasmBinaryCustomSection] = []

            while offset < data.length {
                match wasm_read_u8(data, offset) {
                    case Fine(section_id_result):
                        let section_id: i32 = section_id_result.value
                        offset = offset + 1

                        match leb128_decode_u32(data, offset) {
                            case Fine(size_result):
                                let section_size: usize = size_result.value as usize
                                offset = offset + size_result.consumed

                                if section_id == 0 {
                                    match decode_wasm_custom_section(data, offset, section_size) {
                                        case Fine(cs_result):
                                            push(custom_sections, cs_result.value)
                                            offset = offset + section_size
                                        case Fail(error):
                                            offset = offset + section_size
                                    }
                                } else if section_id == 1 {
                                    match decode_wasm_type_section(data, offset) {
                                        case Fine(t_result):
                                            types = t_result.value
                                            offset = t_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 2 {
                                    match decode_wasm_import_section(data, offset) {
                                        case Fine(imp_result):
                                            imports = imp_result.value
                                            offset = imp_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 3 {
                                    match decode_wasm_function_section(data, offset) {
                                        case Fine(f_result):
                                            function_type_indices = f_result.value
                                            offset = f_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 4 {
                                    match decode_wasm_table_section(data, offset) {
                                        case Fine(tbl_result):
                                            tables = tbl_result.value
                                            offset = tbl_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 5 {
                                    match decode_wasm_memory_section(data, offset) {
                                        case Fine(m_result):
                                            memories = m_result.value
                                            offset = m_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 6 {
                                    match decode_wasm_global_section(data, offset) {
                                        case Fine(g_result):
                                            globals = g_result.value
                                            offset = g_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 7 {
                                    match decode_wasm_export_section(data, offset) {
                                        case Fine(e_result):
                                            exports = e_result.value
                                            offset = e_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 8 {
                                    match leb128_decode_u32(data, offset) {
                                        case Fine(start_result):
                                            start_function_index = start_result.value as i32
                                            offset = offset + start_result.consumed
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 9 {
                                    match decode_wasm_element_section(data, offset) {
                                        case Fine(el_result):
                                            elements = el_result.value
                                            offset = el_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 10 {
                                    match decode_wasm_code_section(data, offset) {
                                        case Fine(c_result):
                                            codes = c_result.value
                                            offset = c_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else if section_id == 11 {
                                    match decode_wasm_data_section(data, offset) {
                                        case Fine(d_result):
                                            data_segments = d_result.value
                                            offset = d_result.next_offset
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                } else {
                                    offset = offset + section_size
                                }
                            case Fail(error):
                                return Fail(error)
                        }
                    case Fail(error):
                        return Fail(error)
                }
            }

            return Fine(WasmBinaryModule {
                version: version,
                types: types,
                imports: imports,
                function_type_indices: function_type_indices,
                tables: tables,
                memories: memories,
                globals: globals,
                exports: exports,
                start_function_index: start_function_index,
                elements: elements,
                codes: codes,
                data_segments: data_segments,
                custom_sections: custom_sections
            })
        case Fail(error):
            return Fail(error)
    }
}

structure WasmDecoded<T> {
    value: T
    next_offset: usize
}

micro wasm_decoded<T>(value: T, next_offset: usize) -> WasmDecoded<T> {
    return WasmDecoded {
        value: value,
        next_offset: next_offset
    }
}

micro decode_wasm_custom_section(data: [i32], offset: usize, section_size: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryCustomSection>> {
    match wasm_read_name(data, offset) {
        case Fine(name_result):
            let name: utf8 = name_result.value
            let data_start: usize = offset + name_result.consumed
            let data_length: usize = section_size - name_result.consumed
            match wasm_read_bytes(data, data_start, data_length) {
                case Fine(bytes_result):
                    return Fine(wasm_decoded(WasmBinaryCustomSection {
                        name: name,
                        data: bytes_result.value
                    }, 0))
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_type_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryFuncType]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut types: [WasmBinaryFuncType] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_func_type(data, pos) {
                    case Fine(ft_result):
                        push(types, ft_result.value)
                        pos = ft_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(types, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_func_type(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryFuncType>> {
    match wasm_read_u8(data, offset) {
        case Fine(form_result):
            let form: i32 = form_result.value
            let mut pos: usize = offset + 1

            if form != wasm_func_type_form() {
                return Fail(wasm_binary_diagnostic("无效的函数类型标记", offset))
            }

            match leb128_decode_u32(data, pos) {
                case Fine(param_count_result):
                    let param_count: u32 = param_count_result.value
                    pos = pos + param_count_result.consumed
                    let mut parameters: [utf8] = []
                    let mut pi: u32 = 0
                    while pi < param_count {
                        match decode_wasm_value_type(data, pos) {
                            case Fine(vt_result):
                                push(parameters, vt_result.value)
                                pos = vt_result.next_offset
                            case Fail(error):
                                return Fail(error)
                        }
                        pi = pi + 1
                    }

                    match leb128_decode_u32(data, pos) {
                        case Fine(result_count_result):
                            let result_count: u32 = result_count_result.value
                            pos = pos + result_count_result.consumed
                            let mut results: [utf8] = []
                            let mut ri: u32 = 0
                            while ri < result_count {
                                match decode_wasm_value_type(data, pos) {
                                    case Fine(vt_result):
                                        push(results, vt_result.value)
                                        pos = vt_result.next_offset
                                    case Fail(error):
                                        return Fail(error)
                                }
                                ri = ri + 1
                            }

                            return Fine(wasm_decoded(WasmBinaryFuncType {
                                parameters: parameters,
                                results: results
                            }, pos))
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

micro decode_wasm_value_type(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<utf8>> {
    match wasm_read_u8(data, offset) {
        case Fine(byte_result):
            let code: i32 = byte_result.value
            return Fine(wasm_decoded(wasm_value_type_name(code), offset + 1))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_limits(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryLimits>> {
    match wasm_read_u8(data, offset) {
        case Fine(flags_result):
            let flags: i32 = flags_result.value
            let has_max: bool = flags == 1
            let mut pos: usize = offset + 1

            match leb128_decode_u32(data, pos) {
                case Fine(min_result):
                    let minimum: u32 = min_result.value
                    pos = pos + min_result.consumed

                    let mut maximum: u32 = 0
                    if has_max {
                        match leb128_decode_u32(data, pos) {
                            case Fine(max_result):
                                maximum = max_result.value
                                pos = pos + max_result.consumed
                            case Fail(error):
                                return Fail(error)
                        }
                    }

                    return Fine(wasm_decoded(WasmBinaryLimits {
                        minimum: minimum,
                        maximum: maximum,
                        has_max: has_max
                    }, pos))
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_import_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryImport]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut imports: [WasmBinaryImport] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_import(data, pos) {
                    case Fine(imp_result):
                        push(imports, imp_result.value)
                        pos = imp_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(imports, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_import(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryImport>> {
    match wasm_read_name(data, offset) {
        case Fine(module_result):
            let module: utf8 = module_result.value
            let mut pos: usize = offset + module_result.consumed

            match wasm_read_name(data, pos) {
                case Fine(field_result):
                    let field: utf8 = field_result.value
                    pos = pos + field_result.consumed

                    match wasm_read_u8(data, pos) {
                        case Fine(kind_result):
                            let kind: i32 = kind_result.value
                            pos = pos + 1

                            let mut func_type_index: u32 = 0
                            let mut table_type: WasmBinaryTableType = WasmBinaryTableType {
                                element_type: "funcref",
                                limits: WasmBinaryLimits { minimum: 0, maximum: 0, has_max: false }
                            }
                            let mut memory_type: WasmBinaryLimits = WasmBinaryLimits { minimum: 0, maximum: 0, has_max: false }
                            let mut global_type: WasmBinaryGlobalType = WasmBinaryGlobalType { value_type: "i32", mutable: false }

                            if kind == 0 {
                                match leb128_decode_u32(data, pos) {
                                    case Fine(idx_result):
                                        func_type_index = idx_result.value
                                        pos = pos + idx_result.consumed
                                    case Fail(error):
                                        return Fail(error)
                                }
                            } else if kind == 1 {
                                match decode_wasm_table_type(data, pos) {
                                    case Fine(tt_result):
                                        table_type = tt_result.value
                                        pos = tt_result.next_offset
                                    case Fail(error):
                                        return Fail(error)
                                }
                            } else if kind == 2 {
                                match decode_wasm_limits(data, pos) {
                                    case Fine(lim_result):
                                        memory_type = lim_result.value
                                        pos = lim_result.next_offset
                                    case Fail(error):
                                        return Fail(error)
                                }
                            } else if kind == 3 {
                                match decode_wasm_global_type(data, pos) {
                                    case Fine(gt_result):
                                        global_type = gt_result.value
                                        pos = gt_result.next_offset
                                    case Fail(error):
                                        return Fail(error)
                                }
                            }

                            return Fine(wasm_decoded(WasmBinaryImport {
                                module: module,
                                field: field,
                                kind: kind,
                                function_type_index: func_type_index,
                                table_type: table_type,
                                memory_type: memory_type,
                                global_type: global_type
                            }, pos))
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

micro decode_wasm_function_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[u32]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut indices: [u32] = []
            let mut i: u32 = 0
            while i < count {
                match leb128_decode_u32(data, pos) {
                    case Fine(idx_result):
                        push(indices, idx_result.value)
                        pos = pos + idx_result.consumed
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(indices, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_table_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryTable]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut tables: [WasmBinaryTable] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_table_type(data, pos) {
                    case Fine(tt_result):
                        push(tables, WasmBinaryTable { table_type: tt_result.value })
                        pos = tt_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(tables, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_table_type(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryTableType>> {
    match decode_wasm_value_type(data, offset) {
        case Fine(vt_result):
            let element_type: utf8 = vt_result.value
            let pos: usize = vt_result.next_offset
            match decode_wasm_limits(data, pos) {
                case Fine(lim_result):
                    return Fine(wasm_decoded(WasmBinaryTableType {
                        element_type: element_type,
                        limits: lim_result.value
                    }, lim_result.next_offset))
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_memory_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryMemory]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut memories: [WasmBinaryMemory] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_limits(data, pos) {
                    case Fine(lim_result):
                        push(memories, WasmBinaryMemory { limits: lim_result.value })
                        pos = lim_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(memories, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_global_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryGlobal]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut globals: [WasmBinaryGlobal] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_global_type(data, pos) {
                    case Fine(gt_result):
                        let global_type: WasmBinaryGlobalType = gt_result.value
                        pos = gt_result.next_offset
                        match decode_wasm_init_expr(data, pos) {
                            case Fine(expr_result):
                                push(globals, WasmBinaryGlobal {
                                    global_type: global_type,
                                    init_bytes: expr_result.value
                                })
                                pos = expr_result.next_offset
                            case Fail(error):
                                return Fail(error)
                            }
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(globals, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_global_type(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryGlobalType>> {
    match decode_wasm_value_type(data, offset) {
        case Fine(vt_result):
            let value_type: utf8 = vt_result.value
            let pos: usize = vt_result.next_offset
            match wasm_read_u8(data, pos) {
                case Fine(mut_result):
                    let mutable: bool = mut_result.value == wasm_global_mutable()
                    return Fine(wasm_decoded(WasmBinaryGlobalType {
                        value_type: value_type,
                        mutable: mutable
                    }, pos + 1))
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_init_expr(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[i32]>> {
    let mut result: [i32] = []
    let mut pos: usize = offset

    while pos < data.length {
        match wasm_read_u8(data, pos) {
            case Fine(opcode_result):
                let opcode: i32 = opcode_result.value
                push(result, opcode)
                pos = pos + 1

                if opcode == 11 {
                    return Fine(wasm_decoded(result, pos))
                }

                if opcode == 65 {
                    match leb128_decode_i32(data, pos) {
                        case Fine(leb_result):
                            pos = pos + leb_result.consumed
                        case Fail(error):
                            return Fail(error)
                    }
                } else if opcode == 66 {
                    match leb128_decode_u32(data, pos) {
                        case Fine(leb_result):
                            pos = pos + leb_result.consumed
                        case Fail(error):
                            return Fail(error)
                    }
                } else if opcode == 67 {
                    pos = pos + 4
                } else if opcode == 68 {
                    pos = pos + 8
                } else if opcode == 35 {
                    match leb128_decode_u32(data, pos) {
                        case Fine(leb_result):
                            pos = pos + leb_result.consumed
                        case Fail(error):
                            return Fail(error)
                    }
                }
            case Fail(error):
                return Fail(error)
        }
    }

    return Fail(wasm_binary_diagnostic("初始化表达式未找到 end 操作码", offset))
}

micro decode_wasm_export_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryExport]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut exports: [WasmBinaryExport] = []
            let mut i: u32 = 0
            while i < count {
                match wasm_read_name(data, pos) {
                    case Fine(name_result):
                        let name: utf8 = name_result.value
                        pos = pos + name_result.consumed

                        match wasm_read_u8(data, pos) {
                            case Fine(kind_result):
                                let kind: i32 = kind_result.value
                                pos = pos + 1

                                match leb128_decode_u32(data, pos) {
                                    case Fine(idx_result):
                                        let index: u32 = idx_result.value
                                        pos = pos + idx_result.consumed

                                        push(exports, WasmBinaryExport {
                                            name: name,
                                            kind: kind,
                                            index: index
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
                i = i + 1
            }
            return Fine(wasm_decoded(exports, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_element_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryElement]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut elements: [WasmBinaryElement] = []
            let mut i: u32 = 0
            while i < count {
                match leb128_decode_u32(data, pos) {
                    case Fine(flags_result):
                        let flags: u32 = flags_result.value
                        pos = pos + flags_result.consumed

                        let mut table_index: u32 = 0
                        let mut offset_bytes: [i32] = []

                        if flags == 0 {
                            match decode_wasm_init_expr(data, pos) {
                                case Fine(expr_result):
                                    offset_bytes = expr_result.value
                                    pos = expr_result.next_offset
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if flags == 2 {
                            match leb128_decode_u32(data, pos) {
                                case Fine(tbl_result):
                                    table_index = tbl_result.value
                                    pos = pos + tbl_result.consumed
                                case Fail(error):
                                    return Fail(error)
                            }
                            match decode_wasm_init_expr(data, pos) {
                                case Fine(expr_result):
                                    offset_bytes = expr_result.value
                                    pos = expr_result.next_offset
                                case Fail(error):
                                    return Fail(error)
                            }
                        }

                        match leb128_decode_u32(data, pos) {
                            case Fine(val_count_result):
                                let val_count: u32 = val_count_result.value
                                pos = pos + val_count_result.consumed
                                let mut init_values: [u32] = []
                                let mut vi: u32 = 0
                                while vi < val_count {
                                    match leb128_decode_u32(data, pos) {
                                        case Fine(val_result):
                                            push(init_values, val_result.value)
                                            pos = pos + val_result.consumed
                                        case Fail(error):
                                            return Fail(error)
                                    }
                                    vi = vi + 1
                                }

                                push(elements, WasmBinaryElement {
                                    table_index: table_index,
                                    offset_bytes: offset_bytes,
                                    init_values: init_values
                                })
                            case Fail(error):
                                return Fail(error)
                        }
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(elements, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_code_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryCode]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut codes: [WasmBinaryCode] = []
            let mut i: u32 = 0
            while i < count {
                match decode_wasm_code(data, pos) {
                    case Fine(code_result):
                        push(codes, code_result.value)
                        pos = code_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(codes, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_wasm_code(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<WasmBinaryCode>> {
    match leb128_decode_u32(data, offset) {
        case Fine(body_size_result):
            let body_size: u32 = body_size_result.value
            let mut pos: usize = offset + body_size_result.consumed
            let body_end: usize = pos + body_size as usize

            match leb128_decode_u32(data, pos) {
                case Fine(local_count_result):
                    let local_count: u32 = local_count_result.value
                    pos = pos + local_count_result.consumed
                    let mut locals: [WasmBinaryLocal] = []
                    let mut li: u32 = 0
                    while li < local_count {
                        match leb128_decode_u32(data, pos) {
                            case Fine(n_result):
                                let n: u32 = n_result.value
                                pos = pos + n_result.consumed
                                match decode_wasm_value_type(data, pos) {
                                    case Fine(vt_result):
                                        push(locals, WasmBinaryLocal {
                                            count: n,
                                            value_type: vt_result.value
                                        })
                                        pos = vt_result.next_offset
                                    case Fail(error):
                                        return Fail(error)
                                }
                            case Fail(error):
                                return Fail(error)
                        }
                        li = li + 1
                    }

                    let remaining: usize = body_end - pos
                    match wasm_read_bytes(data, pos, remaining) {
                        case Fine(body_result):
                            return Fine(wasm_decoded(WasmBinaryCode {
                                body_size: body_size,
                                locals: locals,
                                body: body_result.value
                            }, pos + remaining))
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

micro decode_wasm_data_section(data: [i32], offset: usize) -> WasmBinaryResult<WasmDecoded<[WasmBinaryData]>> {
    match leb128_decode_u32(data, offset) {
        case Fine(count_result):
            let count: u32 = count_result.value
            let mut pos: usize = offset + count_result.consumed
            let mut data_segments: [WasmBinaryData] = []
            let mut i: u32 = 0
            while i < count {
                match leb128_decode_u32(data, pos) {
                    case Fine(flags_result):
                        let flags: u32 = flags_result.value
                        pos = pos + flags_result.consumed

                        let mut memory_index: u32 = 0
                        let mut offset_bytes: [i32] = []

                        if flags == 0 {
                            match decode_wasm_init_expr(data, pos) {
                                case Fine(expr_result):
                                    offset_bytes = expr_result.value
                                    pos = expr_result.next_offset
                                case Fail(error):
                                    return Fail(error)
                            }
                        } else if flags == 2 {
                            match leb128_decode_u32(data, pos) {
                                case Fine(mem_result):
                                    memory_index = mem_result.value
                                    pos = pos + mem_result.consumed
                                case Fail(error):
                                    return Fail(error)
                            }
                            match decode_wasm_init_expr(data, pos) {
                                case Fine(expr_result):
                                    offset_bytes = expr_result.value
                                    pos = expr_result.next_offset
                                case Fail(error):
                                    return Fail(error)
                            }
                        }

                        match leb128_decode_u32(data, pos) {
                            case Fine(data_size_result):
                                let data_size: u32 = data_size_result.value
                                pos = pos + data_size_result.consumed

                                match wasm_read_bytes(data, pos, data_size as usize) {
                                    case Fine(bytes_result):
                                        push(data_segments, WasmBinaryData {
                                            memory_index: memory_index,
                                            offset_bytes: offset_bytes,
                                            initializer: bytes_result.value
                                        })
                                        pos = pos + bytes_result.consumed
                                    case Fail(error):
                                        return Fail(error)
                                }
                            case Fail(error):
                                return Fail(error)
                        }
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(wasm_decoded(data_segments, pos))
        case Fail(error):
            return Fail(error)
    }
}
