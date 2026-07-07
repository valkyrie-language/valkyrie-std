namespace feature_matrix::test;

[test]
micro effect_catch_surface() -> unit {
    let handled: bool =
    try {
        raise "boom"
    }
    .catch {
        case msg:
            msg == "boom"
        else:
            false
    }
    if !handled {
        panic("effect catch")
    }
}
