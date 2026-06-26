namespace std.adaptor.macos.text;

[host_provider(std::text::Utf16Text::length)]
micro host_length(value: std.text.utf16): isize {
    return value._repr.length
}

[host_provider(std::text::Utf16Text::sub_string)]
micro host_sub_string(value: std.text.utf16, start: isize, count: isize): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::concat)]
micro host_concat(value: std.text.utf16, other: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::contains)]
micro host_contains(value: std.text.utf16, other: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::starts_with)]
micro host_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::ends_with)]
micro host_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::index_of)]
micro host_index_of(value: std.text.utf16, other: std.text.utf16): isize {
    return -1
}

[host_provider(std::text::Utf16Text::trim)]
micro host_trim(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::to_lower)]
micro host_to_lower(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::to_upper)]
micro host_to_upper(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::replace)]
micro host_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::equals)]
micro host_equals(value: std.text.utf16, other: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::char_at)]
micro host_char_at(value: std.text.utf16, index: isize): u16 {
    return value._repr[index as usize]
}
