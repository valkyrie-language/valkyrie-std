# std.adaptor.wasm: Node/WASM UTF-8 文本操作
# Node 自举 build 路径中 cli/const_utf8 返回 JS anyref 字符串；
# 标准库 Utf8Text 基于 _repr 字节数组的实现无法对其做 concat/slice 等，
# 因此通过 host import 委托给 .mjs 启动壳。
# 索引契约：utf8_length / utf8_slice / utf8_index_of = Unicode 标量（[...s]），
# 不是 JS string.length 的 UTF-16 code unit。

namespace std.adaptor.wasm.text;

[host_provider(std::text::Utf8Text::concat)]
micro host_concat(value: std.text.utf8, other: std.text.utf8): std.text.utf8 {
    return __host_utf8_concat(value, other)
}

[host_provider(std::text::Utf8Text::length)]
micro host_length(value: std.text.utf8): i32 {
    return __host_utf8_length(value)
}

[host_provider(std::text::Utf8Text::trim)]
micro host_trim(value: std.text.utf8): std.text.utf8 {
    return __host_utf8_trim(value)
}

[host_provider(std::text::Utf8Text::replace)]
micro host_replace(value: std.text.utf8, old_value: std.text.utf8, new_value: std.text.utf8): std.text.utf8 {
    return __host_utf8_replace(value, old_value, new_value)
}

[host_provider(std::text::Utf8Text::starts_with)]
micro host_starts_with(value: std.text.utf8, prefix: std.text.utf8): bool {
    return __host_utf8_starts_with(value, prefix)
}

[host_provider(std::text::Utf8Text::ends_with)]
micro host_ends_with(value: std.text.utf8, suffix: std.text.utf8): bool {
    return __host_utf8_ends_with(value, suffix)
}

[host_provider(std::text::Utf8Text::contains)]
micro host_contains(value: std.text.utf8, other: std.text.utf8): bool {
    return __host_utf8_contains(value, other)
}

[host_provider(std::text::Utf8Text::equals)]
micro host_equals(value: std.text.utf8, other: std.text.utf8): bool {
    return __host_utf8_equals(value, other)
}

[host_provider(std::text::Utf8Text::index_of)]
micro host_index_of(value: std.text.utf8, other: std.text.utf8): i32 {
    return __host_utf8_index_of(value, other)
}

[host_provider(std::text::Utf8Text::slice)]
micro host_slice(value: std.text.utf8, start: i32, count: i32): std.text.utf8 {
    return __host_utf8_slice(value, start, count)
}

[wasm("env", "utf8_concat")]
private micro __host_utf8_concat(a: utf8, b: utf8): utf8

[wasm("env", "utf8_length")]
private micro __host_utf8_length(s: utf8): i32

[wasm("env", "utf8_trim")]
private micro __host_utf8_trim(s: utf8): utf8

[wasm("env", "utf8_replace")]
private micro __host_utf8_replace(s: utf8, old_value: utf8, new_value: utf8): utf8

[wasm("env", "utf8_starts_with")]
private micro __host_utf8_starts_with(s: utf8, prefix: utf8): bool

[wasm("env", "utf8_ends_with")]
private micro __host_utf8_ends_with(s: utf8, suffix: utf8): bool

[wasm("env", "utf8_contains")]
private micro __host_utf8_contains(s: utf8, other: utf8): bool

[wasm("env", "utf8_equals")]
private micro __host_utf8_equals(a: utf8, b: utf8): bool

[wasm("env", "utf8_index_of")]
private micro __host_utf8_index_of(s: utf8, other: utf8): i32

[wasm("env", "utf8_slice")]
private micro __host_utf8_slice(s: utf8, start: i32, count: i32): utf8
