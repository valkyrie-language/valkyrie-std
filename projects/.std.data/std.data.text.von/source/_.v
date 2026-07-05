namespace std.data.text.von;

using std.data.text.v;

structure VonDiagnostic {
    message: utf8
    span: TextSpan
}

structure VonParseResult<T> {
    fine_value: T?
    fail_error: VonDiagnostic?
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

micro Fine<T>(payload: T) -> VonParseResult<T> {
    let result: VonParseResult<T> = VonParseResult {
        fine_value: payload,
        fail_error: null
    }
    return result
}

micro Fail<T>(error: VonDiagnostic) -> VonParseResult<T> {
    let result: VonParseResult<T> = VonParseResult {
        fine_value: null,
        fail_error: error
    }
    return result
}

micro von_parse_take_fine<T>(result: VonParseResult<T>) -> T? {
    return result.fine_value
}

micro von_parse_take_fail<T>(result: VonParseResult<T>) -> VonDiagnostic? {
    return result.fail_error
}
