namespace structure_value::test;

structure Point(i32, i32)

[test]
micro simple_struct() -> unit {
    let p = Point(3, 4)
    print("struct ok")
}
