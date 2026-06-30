# std.adaptor.nyar: UTF-8 文本操作 [vm] 绑定
# 将 valkyrie-core 的 UTF-8 文本操作映射为 NyarVM opcode
# NyarVM 内部文本表示为 UTF-8 编码

#region utf8 操作

[vm("utf8_concat")]
micro utf8_concat(a: utf8, b: utf8): utf8

[vm("utf8_len_bytes")]
micro utf8_len_bytes(s: utf8): i32

[vm("utf8_len_chars")]
micro utf8_len_chars(s: utf8): i32

[vm("utf8_substr")]
micro utf8_substr(s: utf8, start: i32, len: i32): utf8

[vm("utf8_eq")]
micro utf8_eq(a: utf8, b: utf8): bool

[vm("utf8_ne")]
micro utf8_ne(a: utf8, b: utf8): bool

#endregion
