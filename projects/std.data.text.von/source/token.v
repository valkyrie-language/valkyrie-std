namespace std.data.text.von;

use std.data.text.v;

[tag(VonTokenKindTag)]
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
}

micro new_von_token(kind: VonTokenKind, text: utf8, start: usize, stop: usize) -> VonToken {
    return VonToken {
        kind: kind,
        text: text,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}

micro eof_von_token(position: usize) -> VonToken {
    return new_von_token(EndOfFile, "", position, position)
}
