namespace std.text;

structure Utf16Iterator {
    _text: &Utf16Text,
    _offset: usize,
}

imply Utf16Iterator: std.iterator.Iterator {
    type Item = char;

    micro new(text: &Utf16Text) -> Self {
        return Self {
            _text: text,
            _offset: 0,
        }
    }

    micro offset(self) -> usize {
        return self._offset
    }

    micro has_next(self) -> bool {
        return self._offset < self.code_unit_length()
    }

    micro next(mut self) -> Option<char> {
        if !self.has_next() {
            return None
        }

        let first: u16 = self.code_unit_at(self._offset)
        if self.is_high_surrogate(first) && self._offset + 1 < self.code_unit_length() {
            let second: u16 = self.code_unit_at(self._offset + 1)
            if self.is_low_surrogate(second) {
                let high: u32 = (first as u32) - 0xD800
                let low: u32 = (second as u32) - 0xDC00
                let code_point: u32 = 0x10000 + (high << 10) + low
                self._offset = self._offset + 2
                return Some(__char_from_u16(code_point as u16))
            }
        }

        self._offset = self._offset + 1
        return Some(__char_from_u16(first))
    }

    private micro code_unit_length(self) -> usize {
        return self._text.length() as usize
    }

    private micro code_unit_at(self, offset: usize) -> u16 {
        <% match arch %>
            <% case "clr" %>
            return __utf16_clr_char_at(self._text, offset as isize) as u16
            <% case "jvm" %>
            return __utf16_jvm_char_at(self._text, offset as isize) as u16
            <% else %>
            return self._text._repr[offset]
        <% end match %>
    }

    private micro is_high_surrogate(self, value: u16) -> bool {
        return value >= 0xD800 && value <= 0xDBFF
    }

    private micro is_low_surrogate(self, value: u16) -> bool {
        return value >= 0xDC00 && value <= 0xDFFF
    }
}

[clr("System.Runtime", "System.String", "get_Chars"), pure]
private micro __utf16_clr_char_at(value: utf16, index: isize): char { }

[clr("System.Runtime", "System.Convert", "ToChar"), pure]
private micro __char_from_u16(value: u16): char { }

[jvm("java.lang.String", "charAt"), pure]
private micro __utf16_jvm_char_at(value: utf16, index: isize): char { }
