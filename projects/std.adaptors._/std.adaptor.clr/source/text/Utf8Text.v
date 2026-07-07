namespace std.adaptor.clr.text;

# Language `utf8` / `Utf8Text` on the CLR lane (do not conflate with `Utf16Text.v`):
# - CLR may store the abstract text in `System.String` (UTF-16 **code units**).
# - `Utf8Text.length` / `slice` / `index_of` are Unicode **scalar** indices (std truth).
# - Forbidden: bind those APIs directly to `String.get_Length` / `Substring` without
#   scalar ↔ code-unit conversion.
# - `Utf16Text` owns the raw UTF-16 code-unit surface (`get_Length` / `Substring` OK).

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
    let units: i32 = __clr_host_string_code_unit_length(value) as i32
    let mut i: i32 = 0
    let mut count: i32 = 0
    while i < units {
        let cu: u16 = __clr_host_string_char_at(value, i) as u16
        if cu >= 0xD800 && cu <= 0xDBFF && (i + 1) < units {
            i = i + 2
        }
        else {
            i = i + 1
        }
        count = count + 1
    }
    return count
}

private micro utf8_scalar_to_code_unit(value: std.text.utf8, scalar_index: i32): i32 {
    if scalar_index <= 0 {
        return 0
    }
    let units: i32 = __clr_host_string_code_unit_length(value) as i32
    let mut i: i32 = 0
    let mut seen: i32 = 0
    while i < units && seen < scalar_index {
        let cu: u16 = __clr_host_string_char_at(value, i) as u16
        if cu >= 0xD800 && cu <= 0xDBFF && (i + 1) < units {
            i = i + 2
        }
        else {
            i = i + 1
        }
        seen = seen + 1
    }
    return i
}

private micro utf8_scalar_slice(value: std.text.utf8, start: i32, count: i32): std.text.utf8 {
    if start < 0 || count < 0 {
        return ""
    }
    let unit_start: i32 = utf8_scalar_to_code_unit(value, start)
    let unit_end: i32 = utf8_scalar_to_code_unit(value, start + count)
    let unit_count: i32 = unit_end - unit_start
    if unit_count <= 0 {
        return ""
    }
    return __clr_host_string_substring(value, unit_start, unit_count)
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
        if __clr_host_string_equals(part, other) {
            return i
        }
        i = i + 1
    }
    return -1
}

# Walk / convert primitives only — not the public Utf8Text.length/slice surface.
[clr("System.Runtime", "System.String", "get_Length"), pure]
private micro __clr_host_string_code_unit_length(value: std.text.utf8): isize { }

[clr("System.Runtime", "System.String", "get_Chars"), pure]
private micro __clr_host_string_char_at(value: std.text.utf8, index: i32): char { }

[clr("System.Runtime", "System.String", "Substring"), pure]
private micro __clr_host_string_substring(value: std.text.utf8, start: i32, count: i32): std.text.utf8 { }

[clr("System.Runtime", "System.String", "Equals"), pure]
private micro __clr_host_string_equals(value: std.text.utf8, other: std.text.utf8): bool { }
