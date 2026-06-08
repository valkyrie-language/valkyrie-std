namespace std.data.text.v;

unite TokenKind {
    Identifier
    Number
    Text
    Punctuation
    Comment
    Whitespace
    EndOfFile
}

structure Token {
    kind: TokenKind
    text: utf8
    span: TextSpan
}

micro new_token(kind: TokenKind, text: utf8, start: usize, stop: usize) -> Token {
    return Token {
        kind: kind,
        text: text,
        span: TextSpan { start: start, stop: stop }
    }
}

micro token_text(token: Token) -> utf8 {
    return token.text
}

micro token_span(token: Token) -> TextSpan {
    return token.span
}

micro token_is(token: Token, kind: TokenKind) -> bool {
    return token.kind == kind
}
