namespace effect_system::test;

micro stateful_counter() -> i32 / [Get] {
    raise Get;
}

micro compute_with_put(x: i32) -> i32 / [Get, Put] {
    let cur = raise Get;
    raise Put { value: cur + x };
    raise Get;
}

[test]
micro simple_state_get() -> unit {
    let mut state = 0;
    stateful_counter()
        .catch {
            case Get: resume(state)
        };
    print("simple_state_get ok")
}

[test]
micro state_get_put() -> unit {
    let mut state = 0;
    let result = compute_with_put(5)
        .catch {
            case Get: resume(state)
            case Put { value }: { state = value; resume(()) }
        };
    print("state_get_put ok, result={result}")
}

[test]
micro state_with_catch_transparent() -> unit {
    let mut state = 0;
    let result = stateful_counter()
        .catch {
            case Get: resume(state)
        };
    print("catch_transparent ok, result={result}")
}