namespace std.data.binary.jvm;

micro decode_jvm(data: [i32]) -> JvmBinaryResult<JvmBinaryClassFile> {
    if data.length < 10 {
        return Fail(jvm_binary_diagnostic("JVM ClassFile 数据过短，至少需要 10 字节头部", 0))
    }

    if !jvm_check_magic(data, 0) {
        return Fail(jvm_binary_diagnostic("JVM ClassFile 魔数不匹配，期望 0xCAFEBABE", 0))
    }

    let mut offset: usize = 4

    let minor_version: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let major_version: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let constant_pool_count: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let mut constant_pool: [JvmBinaryConstant] = []
    let mut cp_index: u16 = 1
    while cp_index < constant_pool_count {
        let entry_result = decode_constant_entry(data, offset)?
        let entry: JvmBinaryConstant = entry_result.value
        push(constant_pool, entry)
        offset = entry_result.next_offset

        if entry.tag == 5 || entry.tag == 6 {
            cp_index = cp_index + 2
        } else {
            cp_index = cp_index + 1
        }
    }

    let access_flags: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let this_class: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let super_class: u16 = jvm_read_u16_be(data, offset)?.value
    offset = offset + 2

    let if_result = decode_interfaces(data, offset)?
    let interfaces: [u16] = if_result.value
    offset = if_result.next_offset

    let fields_result = decode_fields(data, offset)?
    let fields: [JvmBinaryField] = fields_result.value
    offset = fields_result.next_offset

    let methods_result = decode_methods(data, offset)?
    let methods: [JvmBinaryMethod] = methods_result.value
    offset = methods_result.next_offset

    let attr_result = decode_class_attributes(data, offset)?
    let attributes: [JvmBinaryAttribute] = attr_result.value
    offset = attr_result.next_offset

    let magic: u32 = jvm_read_u32_be(data, 0)?.value

    return Fine(JvmBinaryClassFile {
        magic: magic,
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
    let tag_result = jvm_read_u8(data, offset)?
    let tag: i32 = tag_result.value
    let mut raw_data: [i32] = []
    push(raw_data, tag)

    let mut consumed: usize = 1

    if tag == 1 {
        let len_result = jvm_read_u16_be(data, offset + 1)?
        let utf8_length: usize = len_result.value as usize
        push(raw_data, data⁅offset + 1⁆)
        push(raw_data, data⁅offset + 2⁆)
        consumed = consumed + 2

        let bytes_result = jvm_read_bytes(data, offset + consumed, utf8_length)?
        let mut bi: usize = 0
        while bi < bytes_result.value.length {
            push(raw_data, bytes_result.value[bi])
            bi = bi + 1
        }
        consumed = consumed + utf8_length
    } else {
        let data_size: i32 = jvm_constant_data_size(tag)
        if data_size < 0 {
            return Fail(jvm_binary_diagnostic("未知的常量池标签", offset))
        }
        if data_size > 0 {
            let bytes_result = jvm_read_bytes(data, offset + 1, data_size as usize)?
            let mut bi: usize = 0
            while bi < bytes_result.value.length {
                push(raw_data, bytes_result.value[bi])
                bi = bi + 1
            }
            consumed = consumed + data_size as usize
        }
    }

    return Fine(jvm_decoded(JvmBinaryConstant {
        tag: tag,
        data: raw_data
    }, offset + consumed))
}

micro decode_interfaces(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[u16]>> {
    let count: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2
    let mut interfaces: [u16] = []
    let mut i: u16 = 0
    while i < count {
        let if_result = jvm_read_u16_be(data, pos)?
        push(interfaces, if_result.value)
        pos = pos + 2
        i = i + 1
    }
    return Fine(jvm_decoded(interfaces, pos))
}

micro decode_fields(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryField]>> {
    let count: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2
    let mut fields: [JvmBinaryField] = []
    let mut i: u16 = 0
    while i < count {
        let field_result = decode_field(data, pos)?
        push(fields, field_result.value)
        pos = field_result.next_offset
        i = i + 1
    }
    return Fine(jvm_decoded(fields, pos))
}

micro decode_field(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryField>> {
    let access_flags: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2

    let name_index: u16 = jvm_read_u16_be(data, pos)?.value
    pos = pos + 2

    let descriptor_index: u16 = jvm_read_u16_be(data, pos)?.value
    pos = pos + 2

    let attr_result = decode_attributes(data, pos)?
    let attributes: [JvmBinaryAttribute] = attr_result.value
    pos = attr_result.next_offset

    return Fine(jvm_decoded(JvmBinaryField {
        access_flags: access_flags,
        name_index: name_index,
        descriptor_index: descriptor_index,
        attributes: attributes
    }, pos))
}

micro decode_methods(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryMethod]>> {
    let count: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2
    let mut methods: [JvmBinaryMethod] = []
    let mut i: u16 = 0
    while i < count {
        let method_result = decode_method(data, pos)?
        push(methods, method_result.value)
        pos = method_result.next_offset
        i = i + 1
    }
    return Fine(jvm_decoded(methods, pos))
}

micro decode_method(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryMethod>> {
    let access_flags: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2

    let name_index: u16 = jvm_read_u16_be(data, pos)?.value
    pos = pos + 2

    let descriptor_index: u16 = jvm_read_u16_be(data, pos)?.value
    pos = pos + 2

    let attr_result = decode_attributes(data, pos)?
    let attributes: [JvmBinaryAttribute] = attr_result.value
    pos = attr_result.next_offset

    return Fine(jvm_decoded(JvmBinaryMethod {
        access_flags: access_flags,
        name_index: name_index,
        descriptor_index: descriptor_index,
        attributes: attributes
    }, pos))
}

micro decode_class_attributes(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryAttribute]>> {
    return decode_attributes(data, offset)
}

micro decode_attributes(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<[JvmBinaryAttribute]>> {
    let count: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2
    let mut attributes: [JvmBinaryAttribute] = []
    let mut i: u16 = 0
    while i < count {
        let attr_result = decode_attribute(data, pos)?
        push(attributes, attr_result.value)
        pos = attr_result.next_offset
        i = i + 1
    }
    return Fine(jvm_decoded(attributes, pos))
}

micro decode_attribute(data: [i32], offset: usize) -> JvmBinaryResult<JvmDecoded<JvmBinaryAttribute>> {
    let name_index: u16 = jvm_read_u16_be(data, offset)?.value
    let mut pos: usize = offset + 2

    let len_result = jvm_read_u32_be(data, pos)?
    let attr_length: usize = len_result.value as usize
    pos = pos + 4

    let raw_data: [i32] = jvm_read_bytes(data, pos, attr_length)?.value
    pos = pos + attr_length

    return Fine(jvm_decoded(JvmBinaryAttribute {
        name_index: name_index,
        data: raw_data
    }, pos))
}