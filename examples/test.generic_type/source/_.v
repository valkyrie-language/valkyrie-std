namespace generic_type;

structure Box<T>(value: T)
union Shape {
    case Circle(f32)
    case Square(f32)
}
trait Eq {
    equals(self, other: Self) -> bool
}

[main]
micro generic_type_main() -> ExitCode {
    let int_box = Box(42)
    let str_box = Box("hello")
    print("int={int_box.value}, str={str_box.value}")

    let x = identity(42)
    let y = identity("world")
    print("x={x}, y={y}")

    let pair = Pair(1, "one")
    let pair2 = Pair("a", 2)
    print("pair=({pair.first}, {pair.second})")

    return ExitCode(0 as i32)
}

micro identity<T>(value: T) -> T {
    return value
}

micro first<T, U>(a: T, b: U) -> T {
    return a
}

structure Pair<A, B>(first: A; second: B)
