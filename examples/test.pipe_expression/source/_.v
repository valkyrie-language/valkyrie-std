namespace pipe_expression;

micro add_one(x: i32) -> i32 { return x + 1 }
micro double(x: i32) -> i32 { return x * 2 }

[main]
micro pipe_main() -> ExitCode {
    let result = 5 |> add_one |> double
    print("pipe result={result}")
    return ExitCode(0 as i32)
}