namespace std.text;

structure Utf8Iterator {
    _text: &Utf8Text,
    _offset: usize,
}

imply Utf8Iterator: std.iterator.Iterator {
    type Item = char;

    micro new(text: &Utf8Text) -> Self {
        return Self {
            _text: text,
            _offset: 0,
        }
    }

    micro offset(self) -> usize {
        return self._offset
    }

    micro has_next(self) -> bool {
        return self._offset < self._text.byte_length() as usize
    }

    micro next(mut self) -> Option<char> {
        if !self.has_next() {
            return None
        }

        let first: u8 = self._text._repr[self._offset]
        let width: usize = self.char_width(first)
        let mut code_point: u32 = 0

        if width == 1 {
            code_point = first as u32
        }
        else if width == 2 && self._offset + 1 < self._text._repr.length {
            code_point = ((first as u32) & 0x1F) << 6
            code_point = code_point | ((self._text._repr[self._offset + 1] as u32) & 0x3F)
        }
        else if width == 3 && self._offset + 2 < self._text._repr.length {
            code_point = ((first as u32) & 0x0F) << 12
            code_point = code_point | (((self._text._repr[self._offset + 1] as u32) & 0x3F) << 6)
            code_point = code_point | ((self._text._repr[self._offset + 2] as u32) & 0x3F)
        }
        else if width == 4 && self._offset + 3 < self._text._repr.length {
            code_point = ((first as u32) & 0x07) << 18
            code_point = code_point | (((self._text._repr[self._offset + 1] as u32) & 0x3F) << 12)
            code_point = code_point | (((self._text._repr[self._offset + 2] as u32) & 0x3F) << 6)
            code_point = code_point | ((self._text._repr[self._offset + 3] as u32) & 0x3F)
        }
        else {
            code_point = first as u32
        }

        self._offset = self._offset + width
        return Some(code_point as char)
    }

    private micro char_width(self, first: u8) -> usize {
        if first <= 0x7F {
            return 1
        }

        if first >= 0xC2 && first <= 0xDF {
            return 2
        }

        if first >= 0xE0 && first <= 0xEF {
            return 3
        }

        if first >= 0xF0 && first <= 0xF4 {
            return 4
        }

        return 1
    }
}
