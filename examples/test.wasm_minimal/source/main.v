namespace test;

[main]
micro main(): unit {
    var _ = hello()
}

micro hello(): i32 {
    return 42
}