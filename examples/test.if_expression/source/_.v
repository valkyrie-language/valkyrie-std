namespace if_expression;

[main]
micro if_expr_main() -> ExitCode {
    let a = 10
    let b = 20
    let max = if a > b { a } else { b }
    print("max={max}")

    let label = if max > 15 {
        "big"
    } else if max > 5 {
        "medium"
    } else {
        "small"
    }
    print("label={label}")

    return ExitCode(0 as i32)
}