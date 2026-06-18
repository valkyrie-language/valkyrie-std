namespace std.text;

⍝ ────────── 不可变文本视图 ──────────
⍝ 视图是对 `Utf8Text` 的引用加一个区间，极轻量。
⍝ 因为 `Utf8Text` 不可变且为引用类型，视图始终有效。
structure Utf8View {
    ⍝ 指向底层不可变文本，永远有效
    text: &Utf8Text,
    ⍝ 视图覆盖的字节范围
    span: TextSpan,
}

⍝ Utf8View 实现 TextView trait
imply Utf8View: TextView {
    type Text = Utf8Text;

    micro new(text: &Utf8Text) -> Self {
        return Self {
            text: text,
            span: TextSpan {
                offset: 0,
                length: text.byte_length() as usize,
            }
        }
    }

    micro new(text: &Utf8Text, span: TextSpan) -> Self {
        let full_length: usize = text.byte_length() as usize
        if span.offset >= full_length {
            return Self {
                text: text,
                span: TextSpan {
                    offset: full_length,
                    length: 0,
                }
            }
        }

        let mut length: usize = span.length
        if span.offset + length > full_length {
            length = full_length - span.offset
        }

        return Self {
            text: text,
            span: TextSpan {
                offset: span.offset,
                length: length,
            }
        }
    }

    micro span(self) -> TextSpan {
        return self.span
    }

    ⍝ 转为不可变文本（有开销，不消耗视图）
    micro to_text(self) -> Utf8Text {
        let mut bytes: [u8] = []
        let end: usize = self.end_offset()
        let mut index: usize = self.span.offset
        while index < end {
            push(bytes, self.text._repr[index])
            index = index + 1
        }

        return Utf8Text::from_bytes(bytes)
    }
}

⍝ Utf8View 自身也实现 Text，以便对视图再切片等操作
imply Utf8View: Text {
    type View = Utf8View;

    micro is_empty(self) -> bool {
        return self.span.length == 0
    }

    micro view(self, span: TextSpan) -> Utf8View {
        let view_end: usize = self.end_offset()
        let start: usize = self.span.offset + span.offset
        if start >= view_end {
            return Utf8View::new(self.text, TextSpan {
                offset: view_end,
                length: 0,
            })
        }

        let mut length: usize = span.length
        if start + length > view_end {
            length = view_end - start
        }

        return Utf8View::new(self.text, TextSpan {
            offset: start,
            length: length,
        })
    }

    micro slice(self, span: TextSpan) -> Utf8Text {
        return self.view(span).to_text()
    }
}

imply Utf8View {
    micro byte_length(self) -> usize {
        return self.span.length
    }

    private micro end_offset(self) -> usize {
        return self.span.offset + self.span.length
    }
}
