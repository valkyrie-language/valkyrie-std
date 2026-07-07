namespace std.adaptor.jvm.text;

# Language `utf8` / `Utf8Text` on the JVM lane (do not conflate with `Utf16Text.v`):
# - JVM may store the abstract text in `java.lang.String` (UTF-16 **code units**).
# - `Utf8Text.length` / `slice` / `index_of` are Unicode **scalar** indices (std truth).
# - Forbidden: bind those APIs directly to `String.length` / `substring` without
#   scalar ↔ code-unit conversion (`codePointCount` / `offsetByCodePoints`).
# - `Utf16Text` owns the raw UTF-16 code-unit surface (`length` / `substring` OK).

[host_provider(std::text::Utf8Text::length)]
micro host_length(value: std.text.utf8): i32 {
    return utf8_scalar_length(value)
}

[host_provider(std::text::Utf8Text::slice)]
micro host_slice(value: std.text.utf8, start: i32, count: i32): std.text.utf8 {
    return utf8_scalar_slice(value, start, count)
}

[host_provider(std::text::Utf8Text::index_of)]
micro host_index_of(value: std.text.utf8, other: std.text.utf8): i32 {
    return utf8_scalar_index_of(value, other)
}

private micro utf8_scalar_length(value: std.text.utf8): i32 {
    let units: i32 = __jvm_host_string_code_unit_length(value)
    return __jvm_string_code_point_count(value, 0, units)
}

private micro utf8_scalar_slice(value: std.text.utf8, start: i32, count: i32): std.text.utf8 {
    if start < 0 || count < 0 {
        return ""
    }
    let unit_start: i32 = __jvm_string_offset_by_code_points(value, 0, start)
    let unit_end: i32 = __jvm_string_offset_by_code_points(value, unit_start, count)
    if unit_end <= unit_start {
        return ""
    }
    return __jvm_host_string_substring(value, unit_start, unit_end)
}

private micro utf8_scalar_index_of(value: std.text.utf8, other: std.text.utf8): i32 {
    let needle_len: i32 = utf8_scalar_length(other)
    if needle_len == 0 {
        return 0
    }
    let hay_len: i32 = utf8_scalar_length(value)
    if needle_len > hay_len {
        return -1
    }
    let mut i: i32 = 0
    while i <= hay_len - needle_len {
        let part: std.text.utf8 = utf8_scalar_slice(value, i, needle_len)
        if __jvm_host_string_equals(part, other) {
            return i
        }
        i = i + 1
    }
    return -1
}

# Walk / convert primitives only — not the public Utf8Text.length/slice surface.
[jvm("java.lang.String", "length"), pure]
private micro __jvm_host_string_code_unit_length(value: std.text.utf8): i32 { }

[jvm("java.lang.String", "codePointCount"), pure]
private micro __jvm_string_code_point_count(value: std.text.utf8, begin: i32, end: i32): i32 { }

[jvm("java.lang.String", "offsetByCodePoints"), pure]
private micro __jvm_string_offset_by_code_points(value: std.text.utf8, index: i32, code_point_offset: i32): i32 { }

# JVM substring(begin, end) — end exclusive (unlike CLR Substring(start, count)).
[jvm("java.lang.String", "substring"), pure]
private micro __jvm_host_string_substring(value: std.text.utf8, begin: i32, end: i32): std.text.utf8 { }

[jvm("java.lang.String", "equals"), pure]
private micro __jvm_host_string_equals(value: std.text.utf8, other: std.text.utf8): bool { }
