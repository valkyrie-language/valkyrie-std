namespace std.text;

⍝ [AsciiText] 是一个 ascii 文本，它只包含 ascii 字符集
structure AsciiText {
    _bytes: Vector<u8> 
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
    micro chars(self) -> Iterator<Item=char> {
        loop byte in self._bytes {
            yield byte as char
        }
    }
}