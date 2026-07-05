namespace feature_matrix::test;

micro maybe_value(flag: bool) -> i64? {
    if flag {
        return 42
    }
    return null
}

[test]
micro nullable_suffix_and_propagate() -> unit {
    try? {
        let v: i64 = maybe_value(true)?
        if v != 42 {
            panic("nullable value")
        }
    }
}
