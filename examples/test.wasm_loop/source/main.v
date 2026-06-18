namespace test;

[main]
micro main(): unit {
    let mut sum: i32 = 0
    loop i in 0..10 {
        sum = sum + i
    }
}

micro test_sum(): i32 {
    let mut sum: i32 = 0
    loop i in 0..10 {
        sum = sum + i
    }
    return sum
}
