namespace std.data.text.von;

using std.data.text.v;

[tag(VonTokenKindTag)]
unite VonTokenKind {
    /// 标识符 -- 数据变体，携带标识符文本
    Identifier(utf8)

    /// 字符串字面量 -- 数据变体，携带字符串内容
    StringLiteral(utf8)

    /// 数字字面量 -- 数据变体，携带数字文本
    NumberLiteral(utf8)

    /// 布尔字面量 -- 数据变体，携带布尔文本 ("true" / "false")
    BooleanLiteral(utf8)

    /// 结构标记 -- 纯分派标记，不携带数据
    LeftBrace
    RightBrace
    LeftBracket
    RightBracket
    Colon
    Comma
    EndOfFile
}

structure VonToken {
    kind: VonTokenKind
    span: TextSpan
    line: usize
    column: usize
}

micro new_von_token(kind: VonTokenKind, start: usize, stop: usize) -> VonToken {
    return VonToken {
        kind: kind,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}

micro eof_von_token(position: usize) -> VonToken {
    return new_von_token(EndOfFile, position, position)
}
