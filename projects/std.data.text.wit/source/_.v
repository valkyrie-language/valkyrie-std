namespace std.data.text.wit;

structure WitDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(WitParseResultKind)]
unite WitParseResult<T> {
    Fine(T)
    Fail(WitDiagnostic)
}

micro new_wit_diagnostic(message: utf8, start: usize, stop: usize) -> WitDiagnostic {
    return WitDiagnostic {
        message: message,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}
