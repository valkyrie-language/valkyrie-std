namespace std.data.text.von;

# Local source span for VON text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

structure VonDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(VonParseResultKind)]
unite VonParseResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: VonDiagnostic }
}

micro new_von_diagnostic(message: utf8, start: usize, stop: usize) -> VonDiagnostic {
    return VonDiagnostic {
        message: message,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}

micro von_parse_take_fail<T>(parsed: VonParseResult<T>) -> VonDiagnostic? {
    match parsed {
        case Fail(error):
            return Some(error)
        else:
            return None()
    }
}

micro von_parse_take_fine<T>(parsed: VonParseResult<T>) -> T? {
    match parsed {
        case Fine(value):
            return Some(value)
        else:
            return None()
    }
}
