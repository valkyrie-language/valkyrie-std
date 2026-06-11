namespace std.text;

⍝ ────────── 不可变 UTF‑8 文本 ──────────
⍝ 本体采用引用语义（class），数据一旦创建便不可修改。
⍝ 这使得赋值、传参仅复制引用，成本极低，且视图永无失效风险。
class Utf8Text {
    ⍝ 底层字节存储
    ⍝ 友好访问，当前 namespace 可以直接访问和修改，外界不可直接访问或是篡改
    friendly _bytes: Vector<u8>;

    ⍝ 构造一个空的 UTF‑8 文本
    micro new(capacity: usize) -> Self {
        return Utf8Text { _bytes: Vector::new(capacity) };
    }

    ⍝ 返回文本的字节长度
    micro byte_length(self) -> usize {
        return self._bytes.length();
    }

    ⍝ 返回文本的字符（Unicode 标量）个数
    micro count_char(self) -> usize {
        # 依赖于字符遍历，成本为 O(n)
        return self.chars().count();
    }

    ⍝ 转换为可变构造器，允许后续修改
    micro to_builder(self) -> Utf8Builder {
        return Utf8Builder { bytes: self._bytes.clone() };
    }

    ⍝ 从字节序列创建 UTF‑8 文本
    micro from_bytes(bytes: Vector<u8>) -> Self {
        return Utf8Text { _bytes: bytes };
    }

    unsafe micro from_bytes_unchecked(bytes: Vector<u8>) -> Self {
        return Utf8Text {
            _bytes: bytes
        };
    }
}

⍝ Utf8Text 实现 Text trait
imply Utf8Text: Text {
    type View = Utf8View;

    micro is_empty(self) -> bool {
        return self._bytes.is_empty();
    }

    micro view(self, span: TextSpan) -> Utf8View {
        # 视图直接引用 self（堆上对象），不会因 move 而悬空
        return Utf8View {
            text: self,
            span: span
        };
    }

    micro slice(self, span: TextSpan) -> Utf8Text {
        # 拷贝子串以保证独立所有权
        # 未来可优化为共享不可变缓冲，但外部不可见
        let range = span.as_range();
        let new_bytes = Vector<u8>::with_capacity(range.len());
        loop i in range {
            new_bytes.push(self._bytes[i]);
        }
        return Utf8Text { _bytes: new_bytes };
    }
}

⍝ UTF-8 字符迭代器
structure Utf8Iterator {
    _text: &Utf8Text,
    _index: usize,
}

imply Utf8Iterator: Iterator<char> {
    micro next(mut self) -> Option<char> {
        # 到末尾则停止
        if self._index >= self._text._bytes.length() {
            return None;
        }

        # 获取首字节并确定序列长度
        let head = unsafe {
            self._text._bytes.get_unchecked(self._index)
        };
        let len = Self::_char_length_by_head(head)?;

        # 边界检查
        if self._index + len > self._text._bytes.length() {
            return None;
        }

        # 委托解码
        let result = self._text._get_char_at(self._index, len);
        match result {
            case Fine(ch):
                self._index += len;
                return Fine(ch)
            case Fail(error):
                return None;
        }
    }
}

imply Utf8Text {
    micro chars(self) -> Utf8Iterator {
        return Utf8Iterator { _text: self, _index: 0 };
    }

    ⍝ 根据首字节返回字符的字节长度
    private micro _char_length_by_head(byte: u8) -> Option<usize> {
        match byte {
            case 0x00..=0x7F: Some(1),
            case 0xC2..=0xDF: Some(2),
            case 0xE0..=0xEF: Some(3),
            case 0xF0..=0xF4: Some(4),
            else: None
        }
    }

    ⍝ 根据起始偏移和长度解码字符
    private micro _get_char_at(self, offset: usize, length: usize) -> Result<char, InvalidTextError> {
        let bytes = self._bytes;
        let b0 = bytes[offset] as u32;

        # 解码 Unicode 码点，注意位运算优先级，必须加括号
        let codepoint = match length {
            case 1: b0,
            case 2: ((b0 & 0x1F) << 6)
                  | (bytes[offset + 1] as u32 & 0x3F),
            case 3: ((b0 & 0x0F) << 12)
                  | ((bytes[offset + 1] as u32 & 0x3F) << 6)
                  | (bytes[offset + 2] as u32 & 0x3F),
            case 4: ((b0 & 0x07) << 18)
                  | ((bytes[offset + 1] as u32 & 0x3F) << 12)
                  | ((bytes[offset + 2] as u32 & 0x3F) << 6)
                  | (bytes[offset + 3] as u32 & 0x3F),
            else: Fail(InvalidTextError { offset: offset, found: b0 as u8, expected: length }),
        };

        # 转换为 char，如失败则返回错误
        let ch = char::from_u32(codepoint);
        match ch {
            case Fine(c): Fine(c),
            case Fail(error): Fail(InvalidTextError { offset: offset, found: b0 as u8, expected: length }),
        }
    }
}