namespace generic_type::test;

[test]
micro simple_generic() -> unit {
    let x = identity(42)
    let y = identity("hello")
    print("x={x}, y={y}")
}

[test]
micro generic_pair() -> unit {
    let p = Pair(1, "one")
    print("first={p.first}, second={p.second}")
}

[test]
micro generic_pair_swapped() -> unit {
    let p = Pair("a", 2)
    print("first={p.first}, second={p.second}")
}

[test]
micro first_generic() -> unit {
    let x = first(1, "ignored")
    let y = first("a", 2)
    print("x={x}, y={y}")
}

[test]
micro nested_generic() -> unit {
    let box_of_pair = Box(Pair(1, "two"))
    print("nested={box_of_pair.value.first}-{box_of_pair.value.second}")
}

structure Box<T>(value: T)
structure Pair<A, B>(first: A; second: B)

micro identity<T>(value: T) -> T {
    return value
}

micro first<T, U>(a: T, b: U) -> T {
    return a
}

[benchmark]
micro generic_benchmark() -> unit {
    let x = identity(100)
    print("bench={x}")
}
