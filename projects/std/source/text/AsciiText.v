namespace std.text;

⍝ [AsciiText] 是一个 ascii 文本，它只包含 ascii 字符集
structure AsciiText {
    _bytes: [u8] 
}

structure AsciiIterator {
    _text: AsciiText
    _offset: usize
}

# 基本方法
imply AsciiText: Text {
    ⍝ 获取 ascii 文本的字节数长度
    micro byte_length(self) -> isize {
        return _bytes.length()
    }

    micro char_length(self) -> isize {
        return _bytes.length()
    }

    micro is_empty(self) -> bool {
        return _bytes.is_empty()
    }

    micro to_utf8(self) -> utf8 {
        # 安全性： 任何合法的 ascii 文本都可以转换为 utf8 文本
        unsafe {
            Utf8Text::from_bytes(self._bytes)
        }
    }

    micro to_utf16(self) -> utf16 {
        return _bytes.chars().collect()
    }

    micro to_c_str(self) -> c_str {
        # todo: 实现 c_str 转换
    }
}

# 迭代器方法
imply AsciiText {
    ⍝ 获取 ascii 文本的字符迭代器
    micro chars(self) -> AsciiIterator {
        return AsciiIterator {
            _text: self,
            _offset: 0,
        }
    }
}

imply AsciiText: std::iterator::IntoIterator {
    type Item = char;
    type Iter = AsciiIterator;

    micro into_iterator(self): AsciiIterator {
        return self.chars()
    }
}

imply AsciiIterator: std::iterator::Iterator {
    type Item = char;

    micro has_next(self): bool {
        return self._offset < self._text._bytes.length()
    }

    micro next(mut self): Option<char> {
        if !self.has_next() {
            return None
        }

        let value: char = self._text._bytes[self._offset] as char
        self._offset = self._offset + 1
        return Some(value)
    }
}
