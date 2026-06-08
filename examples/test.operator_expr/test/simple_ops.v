namespace operator_expr::test;

[test]
micro simple_ops() -> unit {
    let a = 10
    let b = 3
    let add = a + b
    let eq = a == b
    let not_val = !true
    print("operators ok")
}
