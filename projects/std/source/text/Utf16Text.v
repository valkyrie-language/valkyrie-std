namespace std.text;

type utf16 = Utf16Text

⍝ UTF-16 编码的字符串
[clr("System.Runtime", "System.String")]
[jvm("java.lang.String")]
class Utf16Text {
    _repr: [u16]
}

imply Utf16Text {
    micro length(self) -> isize {
        return __utf16_host_length(self)
    }

    micro is_empty(self) -> bool {
        if self.length() == 0 {
            return true
        }

        return false
    }

    micro sub_string(self, start: isize, count: isize) -> utf16 {
        return __utf16_host_sub_string(self, start, count)
    }

    micro concat(self, other: utf16) -> utf16 {
        return __utf16_host_concat(self, other)
    }

    micro contains(self, value: utf16) -> bool {
        return __utf16_host_contains(self, value)
    }

    micro starts_with(self, prefix: utf16) -> bool {
        return __utf16_host_starts_with(self, prefix)
    }

    micro ends_with(self, suffix: utf16) -> bool {
        return __utf16_host_ends_with(self, suffix)
    }

    micro index_of(self, value: utf16) -> isize {
        return __utf16_host_index_of(self, value)
    }

    micro trim(self) -> utf16 {
        return __utf16_host_trim(self)
    }

    micro to_lower(self) -> utf16 {
        return __utf16_host_to_lower(self)
    }

    micro to_upper(self) -> utf16 {
        return __utf16_host_to_upper(self)
    }

    micro replace(self, old_value: utf16, new_value: utf16) -> utf16 {
        return __utf16_host_replace(self, old_value, new_value)
    }

    micro equals(self, other: utf16) -> bool {
        return __utf16_host_equals(self, other)
    }

    micro chars(self) -> Utf16Iterator {
        return Utf16Iterator::new(self)
    }
}

[host_contract]
micro __utf16_host_length(value: utf16): isize

[host_contract]
micro __utf16_host_sub_string(value: utf16, start: isize, count: isize): utf16

[host_contract]
micro __utf16_host_concat(lhs: utf16, rhs: utf16): utf16

[host_contract]
micro __utf16_host_contains(value: utf16, other: utf16): bool

[host_contract]
micro __utf16_host_starts_with(value: utf16, prefix: utf16): bool

[host_contract]
micro __utf16_host_ends_with(value: utf16, suffix: utf16): bool

[host_contract]
micro __utf16_host_index_of(value: utf16, other: utf16): isize

[host_contract]
micro __utf16_host_trim(value: utf16): utf16

[host_contract]
micro __utf16_host_to_lower(value: utf16): utf16

[host_contract]
micro __utf16_host_to_upper(value: utf16): utf16

[host_contract]
micro __utf16_host_replace(value: utf16, old_value: utf16, new_value: utf16): utf16

[host_contract]
micro __utf16_host_equals(value: utf16, other: utf16): bool

imply Utf16Text: std.iterator.IntoIterator {
    type Item = char;
    type Iter = Utf16Iterator;

    micro into_iterator(self): Utf16Iterator {
        return self.chars()
    }
}

