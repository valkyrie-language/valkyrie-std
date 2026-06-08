namespace error_handling::test;

unite DivError {
    DivideByZero { fraction: i32 }
    Overflow
}

effect DivideRequest {
    input: { a: i32; b: i32 }
    output: { value: i32 | DivError }
}

[test]
micro simple_error() -> unit {
    let result = try Result<i32, DivError> {
        divide(10, 0)
    }
    .match {
        case Fine(v): "ok"
        case Fail(DivError.DivideByZero()): "caught zero"
        case Fail(DivError.Overflow()): "caught overflow"
    }
    print(result)
}

[test]
micro effect_catch_with_resume() -> unit {
    let value = try {
        divide_with_effect(10, 0)
    }
    .catch {
        case DivideRequest(req): resume 0
    }
    print("value={value}")
}

[test]
micro effect_rethrow_to_result() -> unit {
    let result = try {
        let x = divide_with_effect(100, 0)
        Fine(x)
    }
    .catch {
        case DivideRequest(req): 
            resume Fail(DivError.DivideByZero())
    }
    .match {
        case Fine(v): "ok"
        case Fail(DivError.DivideByZero()): "rethrown"
    }
    print(result)
}

[test]
micro question_mark_propagation() -> unit {
    let ok = try Result<i32, DivError> {
        chain(10, 0)
    }
    .match {
        case Fine(v): "ok"
        case Fail(DivError.DivideByZero()): "zero"
    }
    let ok2 = try Result<i32, DivError> {
        chain(20, 2)
    }
    .match {
        case Fine(v): "ok"
        case Fail(DivError.DivideByZero()): "zero"
    }
    print("ok={ok}, ok2={ok2}")
}

[test]
micro catch_with_branch() -> unit {
    let value = try {
        divide_with_effect(10, 0)
    }
    .catch {
        case DivideRequest(req):
            if req.input.b == 0 {
                resume -1
            } else {
                resume req.input.a / req.input.b
            }
    }
    print("value={value}")
}

[test]
micro pipe_to_catch() -> unit {
    let value = 10
    let fallback = with_default(0)
    let result = value |> fallback()
    print("result={result}")
}

micro divide(a: i32, b: i32) -> Result<i32, DivError> {
    if b == 0 {
        return Fail(DivError.DivideByZero())
    }
    return Fine(a / b)
}

micro divide_with_effect(a: i32, b: i32) -> i32 / DivideRequest {
    if b == 0 {
        raise DivideRequest { input: { a: a, b: b } }
    }
    return a / b
}

micro catch_default() -> micro(i32) -> i32 / DivideRequest {
    return micro(v) { v }
}

micro with_default(default: i32) -> micro(i32) -> i32 {
    return micro(v) {
        if v == 0 { default } else { v }
    }
}

micro chain(a: i32, b: i32) -> Result<i32, DivError> {
    let x = divide(a, b)?
    let y = divide(x, 2)?
    return Fine(y)
}

[benchmark]
micro error_benchmark() -> unit {
    let r = try Result<i32, DivError> {
        divide(100, 1)
    }
    .match {
        case Fine(v): "ok"
        case Fail(DivError.DivideByZero()): "zero"
    }
    print("bench done: {r}")
}
