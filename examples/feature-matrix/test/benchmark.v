namespace feature_matrix::test;

[benchmark]
micro bench_noop() -> unit {
    let x: i64 = 1 + 1
    if x != 2 {
        panic("bench noop")
    }
}
