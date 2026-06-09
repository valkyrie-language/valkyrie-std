namespace std.data.binary.jvm;

structure JvmBinaryDiagnostic {
    message: utf8

    offset: usize
}

[tag(JvmBinaryResultKind)]
unite JvmBinaryResult<T> {
    Fine(T)

    Fail(JvmBinaryDiagnostic)
}

micro jvm_binary_diagnostic(message: utf8, offset: usize) -> JvmBinaryDiagnostic {
    return JvmBinaryDiagnostic {
        message: message,
        offset: offset
    }
}

structure JvmReadResult<T> {
    value: T

    consumed: usize
}

micro jvm_read_u8(data: [i32], offset: usize) -> JvmBinaryResult<JvmReadResult<i32>> {
    if offset >= data.length {
        return Fail(jvm_binary_diagnostic("读取 u8 时数据不足", offset))
    }
    return Fine(JvmReadResult {
        value: data[offset],
        consumed: 1
    })
}

micro jvm_read_u16_be(data: [i32], offset: usize) -> JvmBinaryResult<JvmReadResult<u16>> {
    if offset + 2 > data.length {
        return Fail(jvm_binary_diagnostic("读取 u16 时数据不足", offset))
    }
    let b0: u16 = data[offset] as u16
    let b1: u16 = data[offset + 1] as u16
    let value: u16 = b0 * 256 + b1
    return Fine(JvmReadResult {
        value: value,
        consumed: 2
    })
}

micro jvm_read_u32_be(data: [i32], offset: usize) -> JvmBinaryResult<JvmReadResult<u32>> {
    if offset + 4 > data.length {
        return Fail(jvm_binary_diagnostic("读取 u32 时数据不足", offset))
    }
    let b0: u32 = data[offset] as u32
    let b1: u32 = data[offset + 1] as u32
    let b2: u32 = data[offset + 2] as u32
    let b3: u32 = data[offset + 3] as u32
    let value: u32 = b0 * 16777216 + b1 * 65536 + b2 * 256 + b3
    return Fine(JvmReadResult {
        value: value,
        consumed: 4
    })
}

micro jvm_read_bytes(data: [i32], offset: usize, count: usize) -> JvmBinaryResult<JvmReadResult<[i32]>> {
    if offset + count > data.length {
        return Fail(jvm_binary_diagnostic("读取字节数组时数据不足", offset))
    }
    let mut result: [i32] = []
    let mut i: usize = 0
    while i < count {
        push(result, data[offset + i])
        i = i + 1
    }
    return Fine(JvmReadResult {
        value: result,
        consumed: count
    })
}

micro jvm_read_utf8(data: [i32], offset: usize) -> JvmBinaryResult<JvmReadResult<utf8>> {
    match jvm_read_u16_be(data, offset) {
        case Fine(len_result):
            let length: usize = len_result.value as usize
            let str_offset: usize = offset + 2
            match jvm_read_bytes(data, str_offset, length) {
                case Fine(bytes_result):
                    let mut text: utf8 = ""
                    let mut i: usize = 0
                    while i < bytes_result.value.length {
                        let byte_val: i32 = bytes_result.value[i]
                        if byte_val >= 32 && byte_val < 127 {
                            text = text + byte_to_char(byte_val)
                        }
                        i = i + 1
                    }
                    return Fine(JvmReadResult {
                        value: text,
                        consumed: 2 + bytes_result.consumed
                    })
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

micro byte_to_char(byte: i32) -> utf8 {
    if byte == 32 {
        return " "
    }
    if byte == 95 {
        return "_"
    }
    if byte == 46 {
        return "."
    }
    if byte == 36 {
        return "$"
    }
    if byte == 47 {
        return "/"
    }
    if byte == 59 {
        return ";"
    }
    if byte == 60 {
        return "<"
    }
    if byte == 62 {
        return ">"
    }
    if byte == 40 {
        return "("
    }
    if byte == 41 {
        return ")"
    }
    if byte == 91 {
        return "["
    }
    if byte == 93 {
        return "]"
    }
    if byte == 73 {
        return "I"
    }
    if byte == 74 {
        return "J"
    }
    if byte == 70 {
        return "F"
    }
    if byte == 68 {
        return "D"
    }
    if byte == 66 {
        return "B"
    }
    if byte == 67 {
        return "C"
    }
    if byte == 83 {
        return "S"
    }
    if byte == 90 {
        return "Z"
    }
    if byte == 86 {
        return "V"
    }
    if byte >= 48 && byte <= 57 {
        let digits: utf8 = "0123456789"
        let idx: i32 = byte - 48
        return digit_at(digits, idx)
    }
    if byte >= 65 && byte <= 90 {
        let chars: utf8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let idx: i32 = byte - 65
        return digit_at(chars, idx)
    }
    if byte >= 97 && byte <= 122 {
        let chars: utf8 = "abcdefghijklmnopqrstuvwxyz"
        let idx: i32 = byte - 97
        return digit_at(chars, idx)
    }
    return "?"
}

micro digit_at(text: utf8, idx: i32) -> utf8 {
    let mut i: i32 = 0
    let mut result: utf8 = ""
    while i <= idx {
        if i == idx {
            return ""
        }
        i = i + 1
    }
    return result
}

micro jvm_magic_byte(index: i32) -> i32 {
    if index == 0 {
        return 202
    }
    if index == 1 {
        return 254
    }
    if index == 2 {
        return 186
    }
    if index == 3 {
        return 190
    }
    return 0
}

micro jvm_check_magic(data: [i32], offset: usize) -> bool {
    if offset + 4 > data.length {
        return false
    }
    return data[offset] == 202
        && data[offset + 1] == 254
        && data[offset + 2] == 186
        && data[offset + 3] == 190
}

micro jvm_tag_utf8() -> i32 {
    return 1
}

micro jvm_tag_integer() -> i32 {
    return 3
}

micro jvm_tag_float() -> i32 {
    return 4
}

micro jvm_tag_long() -> i32 {
    return 5
}

micro jvm_tag_double() -> i32 {
    return 6
}

micro jvm_tag_class() -> i32 {
    return 7
}

micro jvm_tag_string() -> i32 {
    return 8
}

micro jvm_tag_fieldref() -> i32 {
    return 9
}

micro jvm_tag_methodref() -> i32 {
    return 10
}

micro jvm_tag_interface_methodref() -> i32 {
    return 11
}

micro jvm_tag_name_and_type() -> i32 {
    return 12
}

micro jvm_tag_method_handle() -> i32 {
    return 15
}

micro jvm_tag_method_type() -> i32 {
    return 16
}

micro jvm_tag_dynamic() -> i32 {
    return 17
}

micro jvm_tag_invoke_dynamic() -> i32 {
    return 18
}

micro jvm_tag_module() -> i32 {
    return 19
}

micro jvm_tag_package() -> i32 {
    return 20
}
