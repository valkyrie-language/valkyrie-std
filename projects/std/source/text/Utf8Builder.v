namespace std.text;

⍝ ────────── 可变文本构造器 ──────────
⍝ 集中处理所有修改操作，最终产出不可变的 `Utf8Text`。
⍝ 内部使用 `ArrayList<u8>` 累积字节，避免频繁扩容时反复创建新数组。
structure Utf8Builder {
    ⍝ 只读暴露底层字节，便于外部检查，但禁止直接赋值
    [get] bytes: ArrayList<u8>
}

imply Utf8Builder {
    ⍝ 创建一个空构造器
    micro new(capacity: usize) -> Self {
        return Utf8Builder { bytes: ArrayList::new(capacity) }
    }

    ⍝ 从已存在文本创建一个构造器, 该文本会被消耗
    micro new(text: Utf8Text) -> Self {
        let mut bytes: ArrayList<u8> = ArrayList::new(text._repr.length)
        let mut index: usize = 0
        while index < text._repr.length {
            bytes.push(text._repr[index])
            index = index + 1
        }

        return Utf8Builder { bytes: bytes }
    }

    micro is_empty(self) -> bool {
        return self.bytes.is_empty()
    }

    micro byte_length(self) -> usize {
        return self.bytes.length()
    }

    ⍝ 追加一个字符
    micro append(mut self, c: char): unit {
        let encoded: [u8] = c.to_bytes()
        let mut index: usize = 0
        while index < encoded.length {
            self.bytes.push(encoded[index])
            index = index + 1
        }
    }

    micro append(mut self, text: &Utf8Text): unit {
        let mut index: usize = 0
        while index < text._repr.length {
            self.bytes.push(text._repr[index])
            index = index + 1
        }
    }

    ⍝ 追加另一个构造器的全部内容，并消耗对方
    micro concat(mut self, other: Self) -> Self {
        let mut index: usize = 0
        while index < other.bytes.length() {
            self.bytes.push(other.bytes.get(index + 1).unwrap())
            index = index + 1
        }

        return self
    }

    ⍝ 消耗构造器，生成不可变文本
    micro build(self) -> Utf8Text {
        let mut bytes: [u8] = []
        let mut index: usize = 0
        while index < self.bytes.length() {
            push(bytes, self.bytes.get(index + 1).unwrap())
            index = index + 1
        }

        return unsafe {
            Utf8Text::from_bytes_unchecked(bytes)
        }
    }

    infix `+=`(mut self, c: char): unit {
        self.append(c)
    }

    infix `+=`(mut self, text: &Utf8Text): unit {
        self.append(text)
    }
}


