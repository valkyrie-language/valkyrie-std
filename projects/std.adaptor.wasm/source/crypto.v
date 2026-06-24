namespace std.adaptor.wasm.crypto;

# std.web_sdk: Crypto API
# [js_builtin] 直接映射 JS 内置 Crypto API，无依赖
# getRandomValues 有副作用（填充随机值），randomUUID 有副作用
# JS 字符串内部为 UTF-16，所有字符串参数标注为 utf16

[host_provider("std.crypto.random_bytes")]
micro random_bytes(len: i32): utf8 {
    if len > 0 {
        crypto_random(0, len)
    }

    return ""
}

[host_provider("std.crypto.random_uuid")]
micro random_uuid(): utf8 {
    let host_value: utf16 = crypto_uuid()
    return utf16_to_utf8(host_value)
}

#region 随机值

[js_builtin("crypto.getRandomValues")]
micro crypto_random(buf: i32, len: i32): unit

[js_builtin("crypto.randomUUID")]
micro crypto_uuid(): utf16

#endregion
