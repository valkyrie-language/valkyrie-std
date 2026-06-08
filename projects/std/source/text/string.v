namespace std.text;

micro text_length(self: utf8) -> i32 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_length(self)
        <% case "jvm" %>
        return jvm_string_length(self)
        <% else %>
        return len(self)
    <% end match %>
}

micro text_slice(self: utf8, start: i32, count: i32) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_substring(self, start, count)
        <% case "jvm" %>
        return jvm_string_substring(self, start, start + count)
        <% else %>
        return ""
    <% end match %>
}

micro trim(self: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_trim(self)
        <% case "jvm" %>
        return jvm_string_trim(self)
        <% else %>
        return self
    <% end match %>
}

micro to_lower(self: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_to_lower(self)
        <% case "jvm" %>
        return jvm_string_to_lower(self)
        <% else %>
        return self
    <% end match %>
}

micro replace(self: utf8, old_value: utf8, new_value: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_replace(self, old_value, new_value)
        <% case "jvm" %>
        return jvm_string_replace(self, old_value, new_value)
        <% else %>
        return self
    <% end match %>
}

micro text_index_of(self: utf8, value: utf8) -> i32 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.string_index_of(self, value)
        <% case "jvm" %>
        return jvm_string_index_of(self, value)
        <% else %>
        return -1
    <% end match %>
}

micro contains(self: utf8, value: utf8) -> bool {
    return text_index_of(self, value) >= 0
}

micro starts_with(self: utf8, prefix: utf8) -> bool {
    let prefix_length: i32 = text_length(prefix)
    let self_length: i32 = text_length(self)
    if prefix_length > self_length {
        return false
    }

    return text_slice(self, 0, prefix_length) == prefix
}

micro ends_with(self: utf8, suffix: utf8) -> bool {
    let suffix_length: i32 = text_length(suffix)
    let self_length: i32 = text_length(self)
    if suffix_length > self_length {
        return false
    }

    return text_slice(self, self_length - suffix_length, suffix_length) == suffix
}

micro split(self: utf8, separator: utf8) -> [utf8] {
    let mut result: [utf8] = []
    let separator_length: i32 = text_length(separator)

    if separator_length <= 0 {
        push(result, self)
        return result
    }

    let mut remaining: utf8 = self
    while true {
        let index: i32 = text_index_of(remaining, separator)
        if index < 0 {
            push(result, remaining)
            return result
        }

        push(result, text_slice(remaining, 0, index))

        let remaining_length: i32 = text_length(remaining)
        let next_start: i32 = index + separator_length
        let next_length: i32 = remaining_length - next_start
        if next_length <= 0 {
            push(result, "")
            return result
        }

        remaining = text_slice(remaining, next_start, next_length)
    }
}
