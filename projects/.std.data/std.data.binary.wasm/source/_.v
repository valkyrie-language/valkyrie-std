namespace std.data.binary.wasm;

structure WasmBinaryDiagnostic {
    message: utf8

    offset: usize
}

[tag(WasmBinaryResultKind)]
unite WasmBinaryResult<T> {
    Fine(T)

    Fail(WasmBinaryDiagnostic)
}

micro wasm_binary_diagnostic(message: utf8, offset: usize) -> WasmBinaryDiagnostic {
    return WasmBinaryDiagnostic {
        message: message,
        offset: offset
    }
}

structure Leb128Decoded<T> {
    value: T

    consumed: usize
}

micro leb128_decode_u32(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<u32>> {
    let mut result: u32 = 0
    let mut shift: u32 = 0
    let mut pos: usize = offset
    let length: usize = data.length

    while pos < length {
        let byte: i32 = data[pos]
        let byte_val: u32 = byte as u32
        let low_bits: u32 = byte_val % 128
        let has_more: bool = byte_val >= 128

        let mut mult: u32 = 1
        let mut s: u32 = 0
        while s < shift {
            mult = mult * 128
            s = s + 1
        }
        result = result + low_bits * mult

        pos = pos + 1

        if !has_more {
            return Fine(Leb128Decoded {
                value: result,
                consumed: pos - offset
            })
        }

        shift = shift + 7

        if shift >= 35 {
            return Fail(wasm_binary_diagnostic("LEB128 编码溢出，超过 u32 范围", offset))
        }
    }

    return Fail(wasm_binary_diagnostic("LEB128 编码意外结束", offset))
}

micro leb128_decode_i32(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<i32>> {
    let mut result: i32 = 0
    let mut shift: u32 = 0
    let mut pos: usize = offset
    let length: usize = data.length

    while pos < length {
        let byte: i32 = data[pos]
        let byte_val: u32 = byte as u32
        let low_bits: u32 = byte_val % 128

        let mut mult: u32 = 1
        let mut s: u32 = 0
        while s < shift {
            mult = mult * 128
            s = s + 1
        }
        result = result + (low_bits * mult) as i32

        pos = pos + 1

        if byte_val < 128 {
            if shift < 31 && (low_bits % 64) >= 32 {
                let mut sign_mult: i32 = -1
                let mut sign_shift: u32 = shift + 7
                let mut sign_val: i32 = 1
                let mut si: u32 = 0
                while si < sign_shift {
                    sign_val = sign_val * 2
                    si = si + 1
                }
                result = result + sign_mult * sign_val
            }
            return Fine(Leb128Decoded {
                value: result,
                consumed: pos - offset
            })
        }

        shift = shift + 7

        if shift >= 35 {
            return Fail(wasm_binary_diagnostic("LEB128 有符号编码溢出", offset))
        }
    }

    return Fail(wasm_binary_diagnostic("LEB128 有符号编码意外结束", offset))
}

micro wasm_read_u8(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<i32>> {
    if offset >= data.length {
        return Fail(wasm_binary_diagnostic("读取 u8 时数据不足", offset))
    }
    return Fine(Leb128Decoded {
        value: data[offset],
        consumed: 1
    })
}

micro wasm_read_u32_le(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<u32>> {
    if offset + 4 > data.length {
        return Fail(wasm_binary_diagnostic("读取 u32 时数据不足", offset))
    }
    let b0: u32 = data[offset] as u32
    let b1: u32 = data[offset + 1] as u32
    let b2: u32 = data[offset + 2] as u32
    let b3: u32 = data[offset + 3] as u32
    let value: u32 = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
    return Fine(Leb128Decoded {
        value: value,
        consumed: 4
    })
}

micro wasm_read_bytes(data: [i32], offset: usize, count: usize) -> WasmBinaryResult<Leb128Decoded<[i32]>> {
    if offset + count > data.length {
        return Fail(wasm_binary_diagnostic("读取字节数组时数据不足", offset))
    }
    let mut result: [i32] = []
    let mut i: usize = 0
    while i < count {
        push(result, data[offset + i])
        i = i + 1
    }
    return Fine(Leb128Decoded {
        value: result,
        consumed: count
    })
}

micro wasm_read_name(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<utf8>> {
    match leb128_decode_u32(data, offset) {
        case Fine(length_result):
            let length: usize = length_result.value as usize
            let str_offset: usize = offset + length_result.consumed
            match wasm_read_bytes(data, str_offset, length) {
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
                    return Fine(Leb128Decoded {
                        value: text,
                        consumed: length_result.consumed + bytes_result.consumed
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

structure WasmConstants {
}

micro wasm_check_magic(data: [i32], offset: usize) -> bool {
    if offset + 4 > data.length {
        return false
    }
    return data[offset] == 0
        && data[offset + 1] == 97
        && data[offset + 2] == 115
        && data[offset + 3] == 109
}

micro wasm_value_type_name(code: i32) -> utf8 {
    if code == 127 {
        return "i32"
    }
    if code == 126 {
        return "i64"
    }
    if code == 125 {
        return "f32"
    }
    if code == 124 {
        return "f64"
    }
    if code == 112 {
        return "funcref"
    }
    if code == 111 {
        return "externref"
    }
    return "unknown"
}

micro wasm_func_type_form() -> i32 {
    return 96
}

micro wasm_global_mutable() -> i32 {
    return 1
}
