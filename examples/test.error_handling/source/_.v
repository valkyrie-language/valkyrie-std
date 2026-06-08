namespace error_handling;

union DivError {
    case DivideByZero()
    case Overflow()
}

effect DivideRequest {
    input: { a: i32; b: i32 }
    output: { value: i32 | DivError }
}

[main]
micro error_handling_main() -> ExitCode {
    let r1 = try Result<i32, DivError> {
        divide(10, 0)
    }
    .match {
        case Fine(v): print("ok={v}")
        case Fail(DivError.DivideByZero()): print("caught zero")
        case Fail(DivError.Overflow()): print("caught overflow")
    }

    let r2 = try {
        let x = divide_with_effect(10, 0)
        print("ok={x}")
    }
    .catch {
        case DivideRequest(req): resume 0
    }

    return ExitCode(0 as i32)
}

micro divide(a: i32, b: i32) -> Result<i32, DivError> {
    if b == 0 {
        return Fail(DivError.DivideByZero())
    }
    if a > 10000 {
        return Fail(DivError.Overflow())
    }
    return Fine(a / b)
}

micro divide_with_effect(a: i32, b: i32) -> i32 / DivideRequest {
    if b == 0 {
        raise DivideRequest { input: { a: a, b: b } }
    }
    return a / b
}
