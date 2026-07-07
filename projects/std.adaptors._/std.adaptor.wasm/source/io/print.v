# std.adaptor.wasm: print 便捷封装（对齐 std.io.print）
# 编码：内部 utf8 → JS 端 utf16

namespace std.adaptor.wasm.io;

micro print(msg: utf8): unit {
    let msg16: utf16 = utf8_to_utf16(msg)
    console_log(msg16)
}

micro print_line(msg: utf8): unit {
    print(msg)
}

micro print_err(msg: utf8): unit {
    let msg16: utf16 = utf8_to_utf16(msg)
    console_error(msg16)
}

micro read_line(): utf8 {
    return ""
}
