namespace std.data.text.wat;

structure WatDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(WatParseResultKind)]
unite WatParseResult<T> {
    Fine(T)
    Fail(WatDiagnostic)
}

micro new_wat_diagnostic(message: utf8, start: usize, stop: usize) -> WatDiagnostic {
    return WatDiagnostic {
        message: message,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}
