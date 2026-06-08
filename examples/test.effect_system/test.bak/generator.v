namespace effect_system::test;

micro generate_numbers() -> () / [Yielder<i32>] {
    yield 1;
    yield 2;
    yield return 3;
}

micro generate_empty() -> () / [Yielder<i32>] {
    yield break;
}

micro generate_single() -> () / [Yielder<i32>] {
    yield return 42;
}

[test]
micro collect_numbers() -> unit {
    let mut list = List<i32>::new();
    generate_numbers()
        .catch {
            case Yielder::Yield { value }:
                list.push(value);
                resume(())
            case Yielder::YieldBreak:
                break
        };
    print("collect_numbers ok, count={list.count}")
}

[test]
micro collect_empty() -> unit {
    let mut list = List<i32>::new();
    generate_empty()
        .catch {
            case Yielder::Yield { value }:
                list.push(value);
                resume(())
            case Yielder::YieldBreak:
                break
        };
    print("collect_empty ok, empty={list.count == 0}")
}

[test]
micro collect_single_yield_return() -> unit {
    let mut list = List<i32>::new();
    generate_single()
        .catch {
            case Yielder::Yield { value }:
                list.push(value);
                resume(())
            case Yielder::YieldBreak:
                break
        };
    print("collect_single ok")
}