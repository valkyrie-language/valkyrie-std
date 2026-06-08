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

    micro span(self) -> TextSpan {
        return self.span;
    }

    ⍝ 转为不可变文本（有开销，不消耗视图）
    micro to_text(self) -> Utf8Text {
        return self.text.slice(self.span);
    }
}

⍝ Utf8View 自身也实现 Text，以便对视图再切片等操作
imply Utf8View: Text {
    type View = Utf8View;

    micro is_empty(self) -> bool {
        return self.span.is_empty();
    }

    micro view(self, span: TextSpan) -> Utf8View {
        # 将 span 转换为相对于底层文本的绝对区间
        let abs_start = self.span.offset + span.offset;
        let abs_end = abs_start + span.length;
        # 边界检查省略，可信任调用方或内部附加检查
        return Utf8View {
            text: self.text,
            span: TextSpan {
                offset: abs_start,
                length: abs_end - abs_start
            }
        };
    }

    micro slice(self, span: TextSpan) -> Utf8Text {
        return self.view(span).as_text();
    }
}
