namespace effect_system::test;

micro chained_computation() -> i32 / [Write, Read] {
    raise Write { value: 1 };
    return raise Read;
}

micro read_only_computation() -> i32 / [Read] {
    raise Read;
}

micro write_only_computation() -> () / [Write] {
    raise Write { value: 10 };
}

[test]
micro chained_catch_read_write() -> unit {
    let result = chained_computation()
        .catch {
            case Read: resume(42)
        }
        .catch {
            case Write { value }: { print("write={value}"); resume(()) }
        };
    print("chained_catch ok, result={result}")
}

[test]
micro chained_catch_write_then_read() -> unit {
    let result = chained_computation()
        .catch {
            case Write { value }: { print("write={value}"); resume(()) }
        }
        .catch {
            case Read: resume(99)
        };
    print("chained_reverse ok, result={result}")
}

[test]
micro single_catch_with_leftover() -> unit {
    let result = read_only_computation()
        .catch {
            case Write { value }: { print("unreachable"); resume(()) }
        };
    print("leftover_effect propagates")
}