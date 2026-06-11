namespace std.data.text.wit;

[tag(WitTokenKindTag)]
unite WitTokenKind {
    EndOfFile

    /// 关键字 -- 数据变体，携带关键词文本
    Keyword(utf8)

    /// 标识符 -- 数据变体，携带标识符文本
    Identifier(utf8)

    /// 数字字面量 -- 数据变体，携带数字文本
    Number(utf8)

    /// 字符串字面量 -- 数据变体，携带字符串文本
    String(utf8)

    /// 注释 -- 数据变体，携带注释文本
    Comment(utf8)

    /// 标点符号 -- 数据变体，携带标点文本
    Punctuation(utf8)

    /// 包引用 -- 数据变体，携带包路径文本
    PackageRef(utf8)

    /// 类型名称 -- 数据变体，携带类型名文本
    TypeName(utf8)
}

structure WitToken {
    kind: WitTokenKind
    span: TextSpan
    line: usize
    column: usize
}

micro new_wit_token(kind: WitTokenKind, start: usize, stop: usize, line: usize, column: usize) -> WitToken {
    return WitToken {
        kind: kind,
        span: TextSpan {
            start: start,
            stop: stop
        },
        line: line,
        column: column
    }
}

micro eof_wit_token(position: usize, line: usize, column: usize) -> WitToken {
    return new_wit_token(EndOfFile, position, position, line, column)
}