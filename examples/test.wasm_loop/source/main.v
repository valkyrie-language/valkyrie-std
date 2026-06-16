namespace test;

[main]
micro main(): unit {
    let mut i: i32 = 0
    let mut sum: i32 = 0
    while i < 10 {
        sum = sum + i
        i = i + 1
    }
}

micro test_sum(): i32 {
    let mut i: i32 = 0
    let mut sum: i32 = 0
    while i < 10 {
        sum = sum + i
        i = i + 1
    }
    return sum
}