namespace std.data.text.von;

unite VonTokenKind {
    Identifier
    StringLiteral
    NumberLiteral
    BooleanLiteral
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
    text: utf8
    span: TextSpan
    line: usize
    column: usize
}

micro new_von_token(kind: VonTokenKind, text: utf8, start: usize, stop: usize) -> VonToken {
    return VonToken {
        kind: kind,
        text: text,
        span: TextSpan {
            start: start,
            stop: stop
        },
        line: 0,
        column: 0
    }
}

micro new_von_marker_token(kind: VonTokenKind, start: usize, stop: usize) -> VonToken {
    return new_von_token(kind, "", start, stop)
}

micro eof_von_token(position: usize) -> VonToken {
    return new_von_marker_token(EndOfFile, position, position)
}
