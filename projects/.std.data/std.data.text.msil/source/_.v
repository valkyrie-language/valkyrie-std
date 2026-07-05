namespace std.data.text.msil;

structure MsilDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(MsilParseResultKind)]
unite MsilParseResult<T> {
    Fine(T)
    Fail(MsilDiagnostic)
}

micro new_msil_diagnostic(message: utf8, start: usize, stop: usize) -> MsilDiagnostic {
    return MsilDiagnostic {
        message: message,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}
