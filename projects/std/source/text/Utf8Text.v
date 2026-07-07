namespace std.text;

type utf8 = Utf8Text

<% match arch %>
<% case "wasm32" %>
[wasm("env", "utf8_concat")]
private micro __host_utf8_concat(a: Utf8Text, b: Utf8Text): Utf8Text

[wasm("env", "utf8_length")]
private micro __host_utf8_length(s: Utf8Text): i32

[wasm("env", "utf8_trim")]
private micro __host_utf8_trim(s: Utf8Text): Utf8Text

[wasm("env", "utf8_replace")]
private micro __host_utf8_replace(s: Utf8Text, old_value: Utf8Text, new_value: Utf8Text): Utf8Text

[wasm("env", "utf8_starts_with")]
private micro __host_utf8_starts_with(s: Utf8Text, prefix: Utf8Text): bool

[wasm("env", "utf8_ends_with")]
private micro __host_utf8_ends_with(s: Utf8Text, suffix: Utf8Text): bool

[wasm("env", "utf8_contains")]
private micro __host_utf8_contains(s: Utf8Text, other: Utf8Text): bool

[wasm("env", "utf8_equals")]
private micro __host_utf8_equals(a: Utf8Text, b: Utf8Text): bool

[wasm("env", "utf8_index_of")]
private micro __host_utf8_index_of(s: Utf8Text, other: Utf8Text): i32

[wasm("env", "utf8_slice")]
private micro __host_utf8_slice(s: Utf8Text, start: i32, count: i32): Utf8Text
<% end %>

class Utf8Text {
    _repr: [u8]
}

imply Utf8Text {
    micro new(capacity: usize) -> Self {
        return Self { _repr: [] }
    }

    micro from_bytes(bytes: [u8]) -> Self {
        return Self { _repr: bytes }
    }

    micro from_bytes_unchecked(bytes: [u8]) -> Self {
        return Self { _repr: bytes }
    }

    micro byte_length(self) -> i32 {
        return self._repr.length as i32
    }

    micro count_char(self) -> usize {
        let mut index: usize = 0
        let mut count: usize = 0
        while index < self._repr.length {
            let width: usize = self.char_width(index)
            if width == 0 {
                break
            }

            index = index + width
            count = count + 1
        }

        return count
    }

    # Unicode scalar count (std). CLR host_provider must not flatten to String.get_Length.
    [host_contract]
    micro length(self) -> i32 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_length(self)
        <% else %>
        return self.count_char() as i32
        <% end %>
    }

    micro is_empty(self) -> bool {
        return self.byte_length() == 0
    }

    micro equals(self, other: utf8) -> bool {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_equals(self, other)
        <% else %>
        return self._repr == other._repr
        <% end %>
    }

    micro not_equals(self, other: utf8) -> bool {
        return !self.equals(other)
    }

    infix `==`(self, other: utf8): bool {
        return self.equals(other)
    }

    infix `!=`(self, other: utf8): bool {
        return self.not_equals(other)
    }

    infix `+`(self, other: utf8): utf8 {
        return self.concat(other)
    }

    micro concat(self, other: utf8) -> utf8 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_concat(self, other)
        <% else %>
        let mut bytes: [u8] = []
        let mut index: usize = 0
        while index < self._repr.length {
            push(bytes, self._repr⁅index⁆)
            index = index + 1
        }

        index = 0
        while index < other._repr.length {
            push(bytes, other._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
        <% end %>
    }

    micro contains(self, value: utf8) -> bool {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_contains(self, value)
        <% else %>
        return self.index_of(value) >= 0
        <% end %>
    }

    micro starts_with(self, prefix: utf8) -> bool {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_starts_with(self, prefix)
        <% else %>
        let prefix_length: i32 = prefix.length()
        let self_length: i32 = self.length()
        if prefix_length > self_length {
            return false
        }

        return self.slice(0, prefix_length).equals(prefix)
        <% end %>
    }

    micro ends_with(self, suffix: utf8) -> bool {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_ends_with(self, suffix)
        <% else %>
        let suffix_length: i32 = suffix.length()
        let self_length: i32 = self.length()
        if suffix_length > self_length {
            return false
        }

        return self.slice(self_length - suffix_length, suffix_length).equals(suffix)
        <% end %>
    }

    # Scalar index of `value` (std). CLR host_provider converts via UTF-16 walk — not String.IndexOf alone.
    [host_contract]
    micro index_of(self, value: utf8) -> i32 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_index_of(self, value)
        <% else %>
        return self.index_of_repr(value)
        <% end %>
    }

    micro trim(self) -> utf8 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_trim(self)
        <% else %>
        return self
        <% end %>
    }

    micro to_lower(self) -> utf8 {
        return self
    }

    micro to_upper(self) -> utf8 {
        return self
    }

    micro replace(self, old_value: utf8, new_value: utf8) -> utf8 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_replace(self, old_value, new_value)
        <% else %>
        return self
        <% end %>
    }

    micro split(self, separator: utf8) -> [utf8] {
        let mut result: [utf8] = []
        let separator_length: i32 = separator.length()

        if separator_length <= 0 {
            push(result, self)
            return result
        }

        let mut remaining: utf8 = self
        while true {
            let index: i32 = remaining.index_of(separator)
            if index < 0 {
                push(result, remaining)
                return result
            }

            push(result, remaining.slice(0, index))

            let remaining_length: i32 = remaining.length()
            let next_start: i32 = index + separator_length
            let next_length: i32 = remaining_length - next_start
            if next_length <= 0 {
                # Must push utf8/string — never a bare Utf8Text value into `[utf8]`
                # (CLR lowers `[utf8]` as `string[]`; Utf8Text slots make Trim AV).
                push(result, "")
                return result
            }

            remaining = remaining.slice(next_start, next_length)
        }
    }

    # Scalar slice(start, count) (std). CLR host_provider must not flatten to String.Substring without conversion.
    [host_contract]
    micro slice(self, start: i32, count: i32) -> utf8 {
        <% match arch %>
        <% case "wasm32" %>
        return __host_utf8_slice(self, start, count)
        <% else %>
        if start < 0 || count < 0 {
            return Utf8Text { _repr: [] }
        }

        let start_index: usize = start as usize
        let count_value: usize = count as usize
        let start_byte: usize = self.byte_offset(start_index)
        let end_byte: usize = self.byte_offset(start_index + count_value)

        if start_byte >= self._repr.length || start_byte >= end_byte {
            return Utf8Text { _repr: [] }
        }

        let mut bytes: [u8] = []
        let mut index: usize = start_byte
        while index < end_byte && index < self._repr.length {
            push(bytes, self._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
        <% end %>
    }

    private micro char_width(self, index: usize) -> usize {
        if index >= self._repr.length {
            return 0
        }

        let byte: u8 = self._repr⁅index⁆
        if byte <= 0x7F {
            return 1
        }

        if byte >= 0xC2 && byte <= 0xDF {
            return 2
        }

        if byte >= 0xE0 && byte <= 0xEF {
            return 3
        }

        if byte >= 0xF0 && byte <= 0xF4 {
            return 4
        }

        return 1
    }

    private micro byte_offset(self, char_index: usize) -> usize {
        let mut byte_index: usize = 0
        let mut current_char: usize = 0
        while byte_index < self._repr.length && current_char < char_index {
            let width: usize = self.char_width(byte_index)
            if width == 0 {
                return byte_index
            }

            byte_index = byte_index + width
            current_char = current_char + 1
        }

        return byte_index
    }

    private micro index_of_repr(self, value: utf8) -> i32 {
        if value._repr.length == 0 {
            return 0
        }

        if value._repr.length > self._repr.length {
            return -1
        }

        let mut offset: usize = 0
        while offset + value._repr.length <= self._repr.length {
            let mut matched: bool = true
            let mut inner: usize = 0
            while inner < value._repr.length {
                if self._repr⁅offset + inner⁆ != value._repr⁅inner⁆ {
                    matched = false
                    break
                }

                inner = inner + 1
            }

            if matched {
                let mut char_index: usize = 0
                let mut byte_index: usize = 0
                while byte_index < offset {
                    byte_index = byte_index + self.char_width(byte_index)
                    char_index = char_index + 1
                }

                return char_index as i32
            }

            offset = offset + self.char_width(offset)
        }

        return -1
    }

    micro chars(self) -> Utf8Iterator {
        return Utf8Iterator::new(self)
    }
}

imply Utf8Text: std::iterator::IntoIterator {
    type Item = char;
    type Iter = Utf8Iterator;

    micro into_iterator(self): Utf8Iterator {
        return self.chars()
    }
}
