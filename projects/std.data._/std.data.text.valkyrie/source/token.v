namespace std.data.text.valkyrie;

# Generic lexical token shape for Valkyrie source (`.v`).
# Format-specific token unites (VON/MSIL/WAT/WIT) live in their own packages.

unite TokenKind {
    Identifier { value: utf8 }
    Number { value: utf8 }
    Text { value: utf8 }
    Punctuation { value: utf8 }
    Comment { value: utf8 }
    Whitespace { value: utf8 }
    EndOfFile
}

structure Token {
    kind: TokenKind
    span: TextSpan
}

micro new_token(kind: TokenKind, start: usize, stop: usize) -> Token {
    return Token {
        kind: kind,
        span: TextSpan { start: start, stop: stop }
    }
}

micro token_span(token: Token) -> TextSpan {
    return token.span
}

micro token_is(token: Token, kind: TokenKind) -> bool {
    return token.kind == kind
}
