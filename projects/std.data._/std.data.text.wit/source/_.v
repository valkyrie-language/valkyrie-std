namespace std.data.text.wit;

# Local source span for WIT text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

structure WitDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(WitParseResultKind)]
unite WitParseResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: WitDiagnostic }
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
