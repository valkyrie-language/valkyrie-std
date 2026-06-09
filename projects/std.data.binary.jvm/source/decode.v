namespace std.data.binary.jvm;

micro decode_jvm(data: [i32]) -> JvmBinaryResult<JvmBinaryClassFile> {
    if data.length < 10 {
        return Fail(jvm_binary_diagnostic("JVM ClassFile 数据过短，至少需要 10 字节头部", 0))
    }

    if !jvm_check_magic(data, 0) {
        return Fail(jvm_binary_diagnostic("JVM ClassFile 魔数不匹配，期望 0xCAFEBABE", 0))
    }

    let mut offset: usize = 4

    match jvm_read_u16_be(data, offset) {
        case Fine(minor_result):
            let minor_version: u16 = minor_result.value
            offset = offset + 2

            match jvm_read_u16_be(data, offset) {
                case Fine(major_result):
                    let major_version: u16 = major_result.value
                    offset = offset + 2

                    match jvm_read_u16_be(data, offset) {
                        case Fine(cp_count_result):
                            let constant_pool_count: u16 = cp_count_result.value
                            offset = offset + 2

                            let mut constant_pool: [JvmBinaryConstant] = []
                            let mut cp_index: u16 = 1
                            while cp_index < constant_pool_count {
                                match decode_constant_entry(data, offset) {
                                    case Fine(entry_result):
                                        let entry: JvmBinaryConstant = entry_result.value
                                        push(constant_pool, entry)
                                        offset = entry_result.next_offset

                                        if entry.tag == 5 || entry.tag == 6 {
                                            cp_index = cp_index + 2
                                        } else {
                                            cp_index = cp_index + 1
                                        }
                                    case Fail(error):
                                        return Fail(error)
                                }
                            }

                            match jvm_read_u16_be(data, offset) {
                                case Fine(flags_result):
                                    let access_flags: u16 = flags_result.value
                                    offset = offset + 2

                                    match jvm_read_u16_be(data, offset) {
                                        case Fine(this_result):
                                            let this_class: u16 = this_result.value
                                            offset = offset + 2

                                            match jvm_read_u16_be(data, offset) {
                                                case Fine(super_result):
                                                    let super_class: u16 = super_result.value
                                                    offset = offset + 2

                                                    match decode_interfaces(data, offset) {
                                                        case Fine(if_result):
                                                            let interfaces: [u16] = if_result.value
                                                            offset = if_result.next_offset

                                                            match decode_fields(data, offset) {
                                                                case Fine(fields_result):
                                                                    let fields: [JvmBinaryField] = fields_result.value
                                                                    offset = fields_result.next_offset

                                                                    match decode_methods(data, offset) {
                                                                        case Fine(methods_result):
                                                                            let methods: [JvmBinaryMethod] = methods_result.value
                                                                            offset = methods_result.next_offset

                                                                            match decode_class_attributes(data, offset) {
                                                                                case Fine(attr_result):
                                                                                    let attributes: [JvmBinaryAttribute] = attr_result.value
                                                                                    offset = attr_result.next_offset

                                                                                    match jvm_read_u32_be(data, 0) {
                                                                                        case Fine(magic_result):
                                                                                            return Fine(JvmBinaryClassFile {
                                                                                                magic: magic_result.value,
                                                                                                minor_version: minor_version,
                                                                                                major_version: major_version,
                                                                                                constant_pool: constant_pool,
                                                                                                access_flags: access_flags,
                                                                                                this_class: this_class,
                                                                                                super_class: super_class,
                                                                                                interfaces: interfaces,
                                                                                                fields: fields,
                                                                                                methods: methods,
                                                                                                attributes: attributes
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
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

structure JvmDecoded<T> {
    value: T

    next_offset: usize
}

micro jvm_decoded<T>(value: T, next_offset: usize) -> JvmDecoded<T> {
    return JvmDecoded {
        value: value,
        next_offset: next_offset
    }
}

micro jvm_constant_data_size(tag: i32) -> i32 {
    if tag == 1 {
        return -1
    }
    if tag == 3 || tag == 4 {
        return 4
    }
    if tag == 5 || tag == 6 {
        return 8
    }
    if tag == 7 || tag == 8 || tag == 16 || tag == 19 || tag == 20 {
        return 2
    }
    if tag == 9 || tag == 10 || tag == 11 || tag == 12 || tag == 17 || tag == 18 {
        return 4
    }
    if tag == 15 {
        return 3
    }
    return 0
}

micro decode_constant_entry(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryConstant>> {
    match jvm_read_u8(data, offset) {
        case Fine(tag_result):
            let tag: i32 = tag_result.value
            let mut raw_data: [i32] = []
            push(raw_data, tag)

            let mut consumed: usize = 1

            if tag == 1 {
                match jvm_read_u16_be(data, offset + 1) {
                    case Fine(len_result):
                        let utf8_length: usize = len_result.value as usize
                        push(raw_data, data⁅offset + 1⁆)
                        push(raw_data, data⁅offset + 2⁆)
                        consumed = consumed + 2

                        match jvm_read_bytes(data, offset + consumed, utf8_length) {
                            case Fine(bytes_result):
                                let mut bi: usize = 0
                                while bi < bytes_result.value.length {
                                    push(raw_data, bytes_result.value[bi])
                                    bi = bi + 1
                                }
                                consumed = consumed + utf8_length
                            case Fail(error):
                                return Fail(error)
                        }
                    case Fail(error):
                        return Fail(error)
                }
            } else {
                let data_size: i32 = jvm_constant_data_size(tag)
                if data_size < 0 {
                    return Fail(jvm_binary_diagnostic("未知的常量池标签", offset))
                }
                if data_size > 0 {
                    match jvm_read_bytes(data, offset + 1, data_size as usize) {
                        case Fine(bytes_result):
                            let mut bi: usize = 0
                            while bi < bytes_result.value.length {
                                push(raw_data, bytes_result.value[bi])
                                bi = bi + 1
                            }
                            consumed = consumed + data_size as usize
                        case Fail(error):
                            return Fail(error)
                    }
                }
            }

            return Fine(jvm_decoded(JvmBinaryConstant {
                tag: tag,
                data: raw_data
            }, offset + consumed))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_interfaces(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[u16]>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(count_result):
            let count: u16 = count_result.value
            let mut pos: usize = offset + 2
            let mut interfaces: [u16] = []
            let mut i: u16 = 0
            while i < count {
                match jvm_read_u16_be(data, pos) {
                    case Fine(if_result):
                        push(interfaces, if_result.value)
                        pos = pos + 2
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(jvm_decoded(interfaces, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_fields(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryField]>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(count_result):
            let count: u16 = count_result.value
            let mut pos: usize = offset + 2
            let mut fields: [JvmBinaryField] = []
            let mut i: u16 = 0
            while i < count {
                match decode_field(data, pos) {
                    case Fine(field_result):
                        push(fields, field_result.value)
                        pos = field_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(jvm_decoded(fields, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_field(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryField>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(flags_result):
            let access_flags: u16 = flags_result.value
            let mut pos: usize = offset + 2

            match jvm_read_u16_be(data, pos) {
                case Fine(name_result):
                    let name_index: u16 = name_result.value
                    pos = pos + 2

                    match jvm_read_u16_be(data, pos) {
                        case Fine(desc_result):
                            let descriptor_index: u16 = desc_result.value
                            pos = pos + 2

                            match decode_attributes(data, pos) {
                                case Fine(attr_result):
                                    let attributes: [JvmBinaryAttribute] = attr_result.value
                                    pos = attr_result.next_offset

                                    return Fine(jvm_decoded(JvmBinaryField {
                                        access_flags: access_flags,
                                        name_index: name_index,
                                        descriptor_index: descriptor_index,
                                        attributes: attributes
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
        case Fail(error):
            return Fail(error)
    }
}

micro decode_methods(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryMethod]>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(count_result):
            let count: u16 = count_result.value
            let mut pos: usize = offset + 2
            let mut methods: [JvmBinaryMethod] = []
            let mut i: u16 = 0
            while i < count {
                match decode_method(data, pos) {
                    case Fine(method_result):
                        push(methods, method_result.value)
                        pos = method_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(jvm_decoded(methods, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_method(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryMethod>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(flags_result):
            let access_flags: u16 = flags_result.value
            let mut pos: usize = offset + 2

            match jvm_read_u16_be(data, pos) {
                case Fine(name_result):
                    let name_index: u16 = name_result.value
                    pos = pos + 2

                    match jvm_read_u16_be(data, pos) {
                        case Fine(desc_result):
                            let descriptor_index: u16 = desc_result.value
                            pos = pos + 2

                            match decode_attributes(data, pos) {
                                case Fine(attr_result):
                                    let attributes: [JvmBinaryAttribute] = attr_result.value
                                    pos = attr_result.next_offset

                                    return Fine(jvm_decoded(JvmBinaryMethod {
                                        access_flags: access_flags,
                                        name_index: name_index,
                                        descriptor_index: descriptor_index,
                                        attributes: attributes
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
        case Fail(error):
            return Fail(error)
    }
}

micro decode_class_attributes(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryAttribute]>> {
    return decode_attributes(data, offset)
}

micro decode_attributes(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryAttribute]>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(count_result):
            let count: u16 = count_result.value
            let mut pos: usize = offset + 2
            let mut attributes: [JvmBinaryAttribute] = []
            let mut i: u16 = 0
            while i < count {
                match decode_attribute(data, pos) {
                    case Fine(attr_result):
                        push(attributes, attr_result.value)
                        pos = attr_result.next_offset
                    case Fail(error):
                        return Fail(error)
                }
                i = i + 1
            }
            return Fine(jvm_decoded(attributes, pos))
        case Fail(error):
            return Fail(error)
    }
}

micro decode_attribute(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryAttribute>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(name_result):
            let name_index: u16 = name_result.value
            let mut pos: usize = offset + 2

            match jvm_read_u32_be(data, pos) {
                case Fine(len_result):
                    let attr_length: usize = len_result.value as usize
                    pos = pos + 4

                    match jvm_read_bytes(data, pos, attr_length) {
                        case Fine(data_result):
                            let raw_data: [i32] = data_result.value
                            pos = pos + attr_length
                            return Fine(jvm_decoded(JvmBinaryAttribute {
                                name_index: name_index,
                                data: raw_data
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
