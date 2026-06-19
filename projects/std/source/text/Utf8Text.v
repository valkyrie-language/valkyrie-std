namespace std.text;

type utf8 = Utf8Text

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

    unsafe micro from_bytes_unchecked(bytes: [u8]) -> Self {
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

    micro length(self) -> i32 {
        return self.count_char() as i32
    }

    micro is_empty(self) -> bool {
        return self.byte_length() == 0
    }

    micro equals(self, other: utf8) -> bool {
        return self._repr == other._repr
    }

    micro not_equals(self, other: utf8) -> bool {
        return !self.equals(other)
    }

    micro concat(self, other: utf8) -> utf8 {
        let mut bytes: [u8] = []
        let mut index: usize = 0
        while index < self._repr.length {
            push(bytes, self._repr[index])
            index = index + 1
        }

        index = 0
        while index < other._repr.length {
            push(bytes, other._repr[index])
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
    }

    micro contains(self, value: utf8) -> bool {
        return self.index_of(value) >= 0
    }

    micro starts_with(self, prefix: utf8) -> bool {
        let prefix_length: i32 = prefix.length()
        let self_length: i32 = self.length()
        if prefix_length > self_length {
            return false
        }

        return self.slice(0, prefix_length).equals(prefix)
    }

    micro ends_with(self, suffix: utf8) -> bool {
        let suffix_length: i32 = suffix.length()
        let self_length: i32 = self.length()
        if suffix_length > self_length {
            return false
        }

        return self.slice(self_length - suffix_length, suffix_length).equals(suffix)
    }

    micro index_of(self, value: utf8) -> i32 {
        return self.index_of_repr(value)
    }

    micro trim(self) -> utf8 {
        return self
    }

    micro to_lower(self) -> utf8 {
        return self
    }

    micro to_upper(self) -> utf8 {
        return self
    }

    micro replace(self, old_value: utf8, new_value: utf8) -> utf8 {
        return self
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
                push(result, Utf8Text { _repr: [] })
                return result
            }

            remaining = remaining.slice(next_start, next_length)
        }
    }

    micro slice(self, start: i32, count: i32) -> utf8 {
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
            push(bytes, self._repr[index])
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
    }

    private micro char_width(self, index: usize) -> usize {
        if index >= self._repr.length {
            return 0
        }

        let byte: u8 = self._repr[index]
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
                if self._repr[offset + inner] != value._repr[inner] {
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

imply Utf8Text: std.iterator.IntoIterator {
    type Item = char;
    type Iter = Utf8Iterator;

    micro into_iterator(self): Utf8Iterator {
        return self.chars()
    }
}
