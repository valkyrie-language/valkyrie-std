namespace std.data.text.wat;

[tag(WatTokenKindTag)]
unite WatTokenKind {
    EndOfFile

    Keyword

    Opcode

    Identifier

    Number

    String

    Comment

    Punctuation

    ValueType
}

structure WatToken {
    kind: WatTokenKind
    text: utf8
    span: TextSpan
    line: usize
    column: usize
}

micro new_wat_token(kind: WatTokenKind, text: utf8, start: usize, stop: usize, line: usize, column: usize) -> WatToken {
    return WatToken {
        kind: kind,
        text: text,
        span: TextSpan {
            start: start,
            stop: stop
        },
        line: line,
        column: column
    }
}

micro eof_wat_token(position: usize, line: usize, column: usize) -> WatToken {
    return new_wat_token(EndOfFile, "", position, position, line, column)
}
