namespace std.data.text.msil;

[tag(MsilTokenKindTag)]
unite MsilTokenKind {
    EndOfFile

    Directive

    Opcode

    Identifier

    TypeReference

    Number

    String

    IllLabel

    Comment

    Modifier

    Punctuation
}

structure MsilToken {
    kind: MsilTokenKind
    text: utf8
    span: TextSpan
    line: usize
    column: usize
}

micro new_msil_token(kind: MsilTokenKind, text: utf8, start: usize, stop: usize, line: usize, column: usize) -> MsilToken {
    return MsilToken {
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

micro eof_msil_token(position: usize, line: usize, column: usize) -> MsilToken {
    return new_msil_token(EndOfFile, "", position, position, line, column)
}
