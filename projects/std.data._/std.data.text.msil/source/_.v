namespace std.data.text.msil;

# Local source span for MSIL text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

structure MsilDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(MsilParseResultKind)]
unite MsilParseResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: MsilDiagnostic }
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
