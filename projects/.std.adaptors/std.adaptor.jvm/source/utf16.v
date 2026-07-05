namespace std.adaptor.jvm.text;

[host_provider(std::text::Utf16Text::length)]
micro host_length(value: std.text.utf16): isize {
    return __utf16_jvm_length(value)
}

[host_provider(std::text::Utf16Text::sub_string)]
micro host_sub_string(value: std.text.utf16, start: isize, count: isize): std.text.utf16 {
    return __utf16_jvm_substring(value, start, start + count)
}

[host_provider(std::text::Utf16Text::concat)]
micro host_concat(value: std.text.utf16, other: std.text.utf16): std.text.utf16 {
    return __utf16_jvm_concat(value, other)
}

[host_provider(std::text::Utf16Text::contains)]
micro host_contains(value: std.text.utf16, other: std.text.utf16): bool {
    return __utf16_jvm_contains(value, other)
}

[host_provider(std::text::Utf16Text::starts_with)]
micro host_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool {
    return __utf16_jvm_starts_with(value, prefix)
}

[host_provider(std::text::Utf16Text::ends_with)]
micro host_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool {
    return __utf16_jvm_ends_with(value, suffix)
}

[host_provider(std::text::Utf16Text::index_of)]
micro host_index_of(value: std.text.utf16, other: std.text.utf16): isize {
    return __utf16_jvm_index_of(value, other)
}

[host_provider(std::text::Utf16Text::trim)]
micro host_trim(value: std.text.utf16): std.text.utf16 {
    return __utf16_jvm_trim(value)
}

[host_provider(std::text::Utf16Text::to_lower)]
micro host_to_lower(value: std.text.utf16): std.text.utf16 {
    return __utf16_jvm_to_lower(value)
}

[host_provider(std::text::Utf16Text::to_upper)]
micro host_to_upper(value: std.text.utf16): std.text.utf16 {
    return __utf16_jvm_to_upper(value)
}

[host_provider(std::text::Utf16Text::replace)]
micro host_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 {
    return __utf16_jvm_replace(value, old_value, new_value)
}

[host_provider(std::text::Utf16Text::equals)]
micro host_equals(value: std.text.utf16, other: std.text.utf16): bool {
    return __utf16_jvm_equals(value, other)
}

[host_provider(std::text::Utf16Text::char_at)]
micro host_char_at(value: std.text.utf16, index: isize): u16 {
    return __utf16_jvm_char_at(value, index) as u16
}

[jvm("java.lang.String", "length"), pure]
private micro __utf16_jvm_length(value: std.text.utf16): isize { }

[jvm("java.lang.String", "substring"), pure]
private micro __utf16_jvm_substring(value: std.text.utf16, start: isize, end: isize): std.text.utf16 { }

[jvm("java.lang.String", "concat"), pure]
private micro __utf16_jvm_concat(value: std.text.utf16, other: std.text.utf16): std.text.utf16 { }

[jvm("java.lang.String", "contains"), pure]
private micro __utf16_jvm_contains(value: std.text.utf16, other: std.text.utf16): bool { }

[jvm("java.lang.String", "startsWith"), pure]
private micro __utf16_jvm_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool { }

[jvm("java.lang.String", "endsWith"), pure]
private micro __utf16_jvm_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool { }

[jvm("java.lang.String", "indexOf"), pure]
private micro __utf16_jvm_index_of(value: std.text.utf16, other: std.text.utf16): isize { }

[jvm("java.lang.String", "trim"), pure]
private micro __utf16_jvm_trim(value: std.text.utf16): std.text.utf16 { }

[jvm("java.lang.String", "toLowerCase"), pure]
private micro __utf16_jvm_to_lower(value: std.text.utf16): std.text.utf16 { }

[jvm("java.lang.String", "toUpperCase"), pure]
private micro __utf16_jvm_to_upper(value: std.text.utf16): std.text.utf16 { }

[jvm("java.lang.String", "replace"), pure]
private micro __utf16_jvm_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 { }

[jvm("java.lang.String", "equals"), pure]
private micro __utf16_jvm_equals(value: std.text.utf16, other: std.text.utf16): bool { }

[jvm("java.lang.String", "charAt"), pure]
private micro __utf16_jvm_char_at(value: std.text.utf16, index: isize): char { }
