namespace feature_matrix::test;

[test]
micro effect_catch_surface() -> unit {
    let handled: bool = catch raise "boom" {
        case msg:
            msg == "boom"
        else:
            false
    }
    if !handled {
        panic("effect catch")
    }
}
