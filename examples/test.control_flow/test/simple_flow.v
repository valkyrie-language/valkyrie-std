namespace control_flow::test;

[test]
micro simple_flow() -> unit {
    let a = 10
    if a > 0 {
        print("positive")
    } else {
        print("non-positive")
    }

    loop count in 0..2 {
        print("loop")
    }
}
