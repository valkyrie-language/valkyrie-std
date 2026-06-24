namespace std.adaptor.clr.text;

[host_provider("std.text.__utf16_host_length")]
micro host_length(value: std.text.utf16): isize {
    return __utf16_clr_length(value)
}

[host_provider("std.text.__utf16_host_sub_string")]
micro host_sub_string(value: std.text.utf16, start: isize, count: isize): std.text.utf16 {
    return __utf16_clr_substring(value, start, count)
}

[host_provider("std.text.__utf16_host_concat")]
micro host_concat(lhs: std.text.utf16, rhs: std.text.utf16): std.text.utf16 {
    return __utf16_clr_concat(lhs, rhs)
}

[host_provider("std.text.__utf16_host_contains")]
micro host_contains(value: std.text.utf16, other: std.text.utf16): bool {
    return __utf16_clr_contains(value, other)
}

[host_provider("std.text.__utf16_host_starts_with")]
micro host_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool {
    return __utf16_clr_starts_with(value, prefix)
}

[host_provider("std.text.__utf16_host_ends_with")]
micro host_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool {
    return __utf16_clr_ends_with(value, suffix)
}

[host_provider("std.text.__utf16_host_index_of")]
micro host_index_of(value: std.text.utf16, other: std.text.utf16): isize {
    return __utf16_clr_index_of(value, other)
}

[host_provider("std.text.__utf16_host_trim")]
micro host_trim(value: std.text.utf16): std.text.utf16 {
    return __utf16_clr_trim(value)
}

[host_provider("std.text.__utf16_host_to_lower")]
micro host_to_lower(value: std.text.utf16): std.text.utf16 {
    return __utf16_clr_to_lower(value)
}

[host_provider("std.text.__utf16_host_to_upper")]
micro host_to_upper(value: std.text.utf16): std.text.utf16 {
    return __utf16_clr_to_upper(value)
}

[host_provider("std.text.__utf16_host_replace")]
micro host_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 {
    return __utf16_clr_replace(value, old_value, new_value)
}

[host_provider("std.text.__utf16_host_equals")]
micro host_equals(value: std.text.utf16, other: std.text.utf16): bool {
    return __utf16_clr_equals(value, other)
}

[host_provider("std.text.__utf16_host_char_at")]
micro host_char_at(value: std.text.utf16, index: isize): u16 {
    return __utf16_clr_char_at(value, index) as u16
}

[clr("System.Runtime", "System.String", "get_Length"), pure]
private micro __utf16_clr_length(value: std.text.utf16): isize { }

[clr("System.Runtime", "System.String", "Substring"), pure]
private micro __utf16_clr_substring(value: std.text.utf16, start: isize, count: isize): std.text.utf16 { }

[clr("System.Runtime", "System.String", "Concat"), pure]
private micro __utf16_clr_concat(lhs: std.text.utf16, rhs: std.text.utf16): std.text.utf16 { }

[clr("System.Runtime", "System.String", "Contains"), pure]
private micro __utf16_clr_contains(value: std.text.utf16, other: std.text.utf16): bool { }

[clr("System.Runtime", "System.String", "StartsWith"), pure]
private micro __utf16_clr_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool { }

[clr("System.Runtime", "System.String", "EndsWith"), pure]
private micro __utf16_clr_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool { }

[clr("System.Runtime", "System.String", "IndexOf"), pure]
private micro __utf16_clr_index_of(value: std.text.utf16, other: std.text.utf16): isize { }

[clr("System.Runtime", "System.String", "Trim"), pure]
private micro __utf16_clr_trim(value: std.text.utf16): std.text.utf16 { }

[clr("System.Runtime", "System.String", "ToLower"), pure]
private micro __utf16_clr_to_lower(value: std.text.utf16): std.text.utf16 { }

[clr("System.Runtime", "System.String", "ToUpper"), pure]
private micro __utf16_clr_to_upper(value: std.text.utf16): std.text.utf16 { }

[clr("System.Runtime", "System.String", "Replace"), pure]
private micro __utf16_clr_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 { }

[clr("System.Runtime", "System.String", "Equals"), pure]
private micro __utf16_clr_equals(value: std.text.utf16, other: std.text.utf16): bool { }

[clr("System.Runtime", "System.String", "get_Chars"), pure]
private micro __utf16_clr_char_at(value: std.text.utf16, index: isize): char { }
