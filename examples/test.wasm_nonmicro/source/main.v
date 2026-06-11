namespace test;

[main]
micro main(): unit {
    var _ = get_answer()
}

micro get_answer(): i32 {
    return 42
}