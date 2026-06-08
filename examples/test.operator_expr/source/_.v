namespace operator_expr;

[main]
micro operator_main() -> ExitCode {
    let a = 10
    let b = 3

    let add = a + b
    let sub = a - b
    let mul = a * b
    let div = a / b
    let rem = a % b

    let eq = a == b
    let neq = a != b
    let lt = a < b
    let gt = a > b

    let and_val = true && false
    let or_val = true || false
    let not_val = !true

    let neg = -a

    print("operators ok")
    return ExitCode(0 as i32)
}