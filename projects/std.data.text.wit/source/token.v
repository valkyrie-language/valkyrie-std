namespace std.data.text.wit;

[tag(WitTokenKindTag)]
unite WitTokenKind {
    EndOfFile

    Keyword

    Identifier

    Number

    String

    Comment

    Punctuation

    PackageRef

    TypeName
}

structure WitToken {
    kind: WitTokenKind
    text: utf8
    span: TextSpan
    line: usize
    column: usize
}

micro new_wit_token(kind: WitTokenKind, text: utf8, start: usize, stop: usize, line: usize, column: usize) -> WitToken {
    return WitToken {
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

micro eof_wit_token(position: usize, line: usize, column: usize) -> WitToken {
    return new_wit_token(EndOfFile, "", position, position, line, column)
}
