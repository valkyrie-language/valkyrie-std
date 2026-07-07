namespace std.data.text.wat;

# Local source span for WAT text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

structure WatDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(WatParseResultKind)]
unite WatParseResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: WatDiagnostic }
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
