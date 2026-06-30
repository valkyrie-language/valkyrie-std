namespace std.data.text.v;

unite TokenKind {
    Identifier(utf8)
    Number(utf8)
    Text(utf8)
    Punctuation(utf8)
    Comment(utf8)
    Whitespace(utf8)
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

⍝ 从 data-carrying kind 变体中提取文本 -- 仅调试/工具用，parser 不得调用
micro token_text(token: Token) -> utf8 {
    match token.kind {
        case Identifier(text):
            return text
        case Number(text):
            return text
        case Text(text):
            return text
        case Punctuation(text):
            return text
        case Comment(text):
            return text
        case Whitespace(text):
            return text
        case EndOfFile:
            return ""
    }
}

micro token_span(token: Token) -> TextSpan {
    return token.span
}

micro token_is(token: Token, kind: TokenKind) -> bool {
    return token.kind == kind
}
