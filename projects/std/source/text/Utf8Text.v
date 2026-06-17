namespace std.text;

type utf8 = Utf8Text

structure InvalidTextError {
    offset: usize,
    found: u8,
    expected: usize
}

micro utf8_eq(a: utf8, b: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_equals(a, b)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_equals(a, b)
        <% else %>
        return a == b
    <% end match %>
}

micro utf8_ne(a: utf8, b: utf8) -> bool {
    return !utf8_eq(a, b)
}

micro utf8_concat(a: utf8, b: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_concat(a, b)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_concat(a, b)
        <% else %>
        return a + b
    <% end match %>
}

micro utf8_len_bytes(s: utf8) -> i32 {
    return utf8_len_chars(s)
}

micro utf8_len_chars(s: utf8) -> i32 {
    return text_length(s)
}

micro utf8_substr(s: utf8, start: i32, len: i32) -> utf8 {
    return text_slice(s, start, len)
}

micro text_length(self: utf8) -> i32 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_length(self)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_length(self)
        <% else %>
        return i32(self.count_char())
    <% end match %>
}

micro text_slice(self: utf8, start: i32, count: i32) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_substring(self, start, count)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_substring(self, start, start + count)
        <% else %>
        return ""
    <% end match %>
}

micro trim(self: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_trim(self)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_trim(self)
        <% else %>
        return self
    <% end match %>
}

micro to_lower(self: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_to_lower(self)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_to_lower(self)
        <% else %>
        return self
    <% end match %>
}

micro to_upper(self: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_to_upper(self)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_to_upper(self)
        <% else %>
        return self
    <% end match %>
}

micro replace(self: utf8, old_value: utf8, new_value: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_replace(self, old_value, new_value)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_replace(self, old_value, new_value)
        <% else %>
        return self
    <% end match %>
}

micro text_index_of(self: utf8, value: utf8) -> i32 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.string.utf8_index_of(self, value)
        <% case "jvm" %>
        return std.adaptor.jvm.utf8.jvm_utf8_index_of(self, value)
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
    ⍝ 返回字符长度。
    ⍝ 在 Valkyrie 中，`.length` 与 `.length()` 等价，因此这里补一个零参数方法入口。
    micro length(self) -> usize {
        return self.count_char();
    }

    ⍝ 判断当前文本是否与目标文本内容相等
    micro equals(self, other: Utf8Text) -> bool {
        return utf8_eq(self, other);
    }

    ⍝ 拼接两个 UTF‑8 文本并返回新的文本
    micro concat(self, other: Utf8Text) -> Utf8Text {
        return utf8_concat(self, other);
    }

    ⍝ 判断当前文本是否包含目标子串
    micro contains(self, value: Utf8Text) -> bool {
        return std.text.contains(self, value);
    }

    ⍝ 判断当前文本是否以指定前缀开头
    micro starts_with(self, prefix: Utf8Text) -> bool {
        return std.text.starts_with(self, prefix);
    }

    ⍝ 判断当前文本是否以指定后缀结尾
    micro ends_with(self, suffix: Utf8Text) -> bool {
        return std.text.ends_with(self, suffix);
    }

    ⍝ 返回目标子串在当前文本中的起始位置
    micro index_of(self, value: Utf8Text) -> i32 {
        return text_index_of(self, value);
    }

    ⍝ 去除当前文本首尾空白
    micro trim(self) -> Utf8Text {
        return std.text.trim(self);
    }

    ⍝ 将当前文本转换为小写
    micro to_lower(self) -> Utf8Text {
        return std.text.to_lower(self);
    }

    ⍝ 将当前文本转换为大写
    micro to_upper(self) -> Utf8Text {
        return std.text.to_upper(self);
    }

    ⍝ 替换当前文本中的指定子串
    micro replace(self, old_value: Utf8Text, new_value: Utf8Text) -> Utf8Text {
        return std.text.replace(self, old_value, new_value);
    }

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
