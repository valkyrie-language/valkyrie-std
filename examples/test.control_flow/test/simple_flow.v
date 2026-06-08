namespace control_flow::test;

[test]
micro simple_flow() -> unit {
    let a = 10
    if a > 0 {
        print("positive")
    } else {
        print("non-positive")
    }

    let mut count = 0
    while count < 2 {
        print("loop")
        count += 1
    }
}
