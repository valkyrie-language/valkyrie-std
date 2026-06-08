namespace effect_system::test;

micro log_and_compute() -> i32 / [Log] {
    raise Log { message: "计算中..." };
    return 42;
}

micro pure_compute() -> i32 {
    return 100;
}

[test]
micro capture_log_with_try() -> unit {
    let result = try Result<i32, [Log]> {
        log_and_compute()
    };
    result
        .match {
            case Fine(v): print("unexpected fine={v}")
            case Fail(Log { message }): print("log captured: {message}")
        };
    print("capture_log ok")
}

[test]
micro try_pure_computation() -> unit {
    let result = try Result<i32, [Log]> {
        pure_compute()
    };
    result
        .match {
            case Fine(v): print("fine={v}")
            case Fail(Log { message }): print("unexpected fail: {message}")
        };
    print("try_pure ok")
}

[test]
micro try_with_nested_raise() -> unit {
    micro inner() -> i32 / [Log] {
        raise Log { message: "嵌套错误" };
    }
    let result = try Result<i32, [Log]> {
        inner()
    };
    result
        .match {
            case Fine(v): print("unexpected fine={v}")
            case Fail(Log { message }): print("nested log: {message}")
        };
    print("nested_raise ok")
}