namespace std.text;

⍝ ────────── 可变文本构造器 ──────────
⍝ 集中处理所有修改操作，最终产出不可变的 `Utf8Text`。
⍝ 采用值语义（structure），赋值即移动所有权，避免意外的多份可变引用。
structure Utf8Builder {
    ⍝ 只读暴露底层字节，便于外部检查，但禁止直接赋值
    [get] bytes: Vector<u8>;

    ⍝ 创建一个空构造器
    micro new(capacity: usize) -> Self {
        return Utf8Builder { bytes: Vector::new(capacity) };
    }

    ⍝ 从已存在文本创建一个构造器, 该文本会被消耗
    micro new(text: Utf8Text) -> Self {
        return Utf8Builder { bytes: text._bytes };
    }

    ⍝ 追加一个字符
    micro append(mut self, c: char): unit {
        self.bytes.append(c.to_bytes());
    }

    micro append(mut self, text: &Utf8Text): unit {
        self.bytes.append(text._bytes.clone());
    }

    ⍝ 追加另一个构造器的全部内容，并消耗对方
    micro concat(own self, other: Self) -> Self {
        self.bytes.append(other.bytes);
        return self;
    }

    ⍝ 消耗构造器，生成不可变文本
    micro build(own self) -> Utf8Text {
        return unsafe {
            Utf8Text::from_bytes_unchecked(self.bytes)
        };
    }
}

imply Utf8Builder {
    infix `+=`(mut self, c: char): unit {
        self.append(c);
    }

    infix `+=`(mut self, text: &Utf8Text): unit {
        self.append(text);
    }
}


