namespace pipe_expression::test;

micro add_one(x: i32) -> i32 { return x + 1 }

[test]
micro simple_pipe() -> unit {
    let result = 5 |> add_one
    print("pipe ok")
}
