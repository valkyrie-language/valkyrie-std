namespace std.data.text.von;

use std.data.text.v;

structure VonDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(VonParseResultKind)]
unite VonParseResult<T> {
    Fine(T)
    Fail(VonDiagnostic)
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
