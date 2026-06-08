namespace effect_system::test;

micro cause_panic() -> ! / [Panic] {
    raise Panic { message: "致命错误" };
}

micro normal_flow() -> i32 {
    return 42;
}

[test]
micro panic_is_unrecoverable() -> unit {
    micro guarded() -> i32 / [Panic] {
        let x = normal_flow();
        if x > 0 {
            cause_panic();
        }
        return x;
    };
    print("panic_type_check ok")
}

[test]
micro panics_are_not_caught_by_unrelated_catch() -> unit {
    let result = normal_flow()
        .catch {
            case Get: resume(99)
        };
    print("unrelated_catch ok, result={result}")
}