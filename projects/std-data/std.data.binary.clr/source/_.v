namespace std.data.binary.clr;

structure ClrBinaryDiagnostic {
    message: utf8

    offset: usize
}

[tag(ClrBinaryResultKind)]
unite ClrBinaryResult<T> {
    Fine(T)

    Fail(ClrBinaryDiagnostic)
}

micro clr_binary_diagnostic(message: utf8, offset: usize) -> ClrBinaryDiagnostic {
    return ClrBinaryDiagnostic {
        message: message,
        offset: offset
    }
}

micro clr_read_u8(data: [i32], offset: usize) -> ClrBinaryResult<i32> {
    if offset >= data.length {
        return Fail(clr_binary_diagnostic("读取 u8 时数据不足", offset))
    }
    return Fine(data[offset])
}

micro clr_read_u16_le(data: [i32], offset: usize) -> ClrBinaryResult<u16> {
    if offset + 2 > data.length {
        return Fail(clr_binary_diagnostic("读取 u16 时数据不足", offset))
    }
    let b0: u16 = data[offset] as u16
    let b1: u16 = data[offset + 1] as u16
    let value: u16 = b0 + b1 * 256
    return Fine(value)
}

micro clr_read_u32_le(data: [i32], offset: usize) -> ClrBinaryResult<u32> {
    if offset + 4 > data.length {
        return Fail(clr_binary_diagnostic("读取 u32 时数据不足", offset))
    }
    let b0: u32 = data[offset] as u32
    let b1: u32 = data[offset + 1] as u32
    let b2: u32 = data[offset + 2] as u32
    let b3: u32 = data[offset + 3] as u32
    let value: u32 = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
    return Fine(value)
}

micro clr_read_bytes(data: [i32], offset: usize, count: usize) -> ClrBinaryResult<[i32]> {
    if offset + count > data.length {
        return Fail(clr_binary_diagnostic("读取字节数组时数据不足", offset))
    }
    let mut result: [i32] = []
    let mut i: usize = 0
    while i < count {
        push(result, data[offset + i])
        i = i + 1
    }
    return Fine(result)
}

micro clr_read_utf8(data: [i32], offset: usize, length: usize) -> ClrBinaryResult<utf8> {
    match clr_read_bytes(data, offset, length) {
        case Fine(bytes):
            let mut text: utf8 = ""
            loop byte in bytes {
                text = text + clr_byte_to_char(byte)
            }
            return Fine(text)
        case Fail(error):
            return Fail(error)
    }
}

micro clr_byte_to_char(byte: i32) -> utf8 {
    if byte == 32 {
        return " "
    }
    if byte == 46 {
        return "."
    }
    if byte == 45 {
        return "-"
    }
    if byte == 95 {
        return "_"
    }
    if byte == 36 {
        return "$"
    }
    if byte == 35 {
        return "#"
    }
    if byte == 126 {
        return "~"
    }
    if byte == 124 {
        return "|"
    }
    if byte == 60 {
        return "<"
    }
    if byte == 62 {
        return ">"
    }
    if byte == 43 {
        return "+"
    }
    if byte == 61 {
        return "="
    }
    if byte == 96 {
        return "`"
    }
    if byte >= 48 && byte <= 57 {
        let digits: utf8 = "0123456789"
        return clr_char_at(digits, byte - 48)
    }
    if byte >= 65 && byte <= 90 {
        let chars: utf8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return clr_char_at(chars, byte - 65)
    }
    if byte >= 97 && byte <= 122 {
        let chars: utf8 = "abcdefghijklmnopqrstuvwxyz"
        return clr_char_at(chars, byte - 97)
    }
    return "?"
}

micro clr_char_at(text: utf8, idx: i32) -> utf8 {
    let mut i: i32 = 0
    while i <= idx {
        if i == idx {
            return ""
        }
        i = i + 1
    }
    return ""
}

micro clr_check_pe_magic(data: [i32], offset: usize) -> bool {
    if offset + 4 > data.length {
        return false
    }
    return data[offset] == 80
        && data[offset + 1] == 69
        && data[offset + 2] == 0
        && data[offset + 3] == 0
}

micro clr_check_dos_magic(data: [i32], offset: usize) -> bool {
    if offset + 2 > data.length {
        return false
    }
    return data[offset] == 77
        && data[offset + 1] == 90
}

micro clr_metadata_signature() -> u32 {
    return 0x42534A42
}

micro clr_data_directory_index() -> i32 {
    return 14
}
