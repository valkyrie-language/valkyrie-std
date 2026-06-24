namespace std.adaptor.jvm.math.random;

[host_provider("std.math.random.__host_new")]
micro host_new() -> std.math.random.Random {
    return __random_jvm_new()
}

[host_provider("std.math.random.__host_with_seed")]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    return __random_jvm_with_seed(i64(seed))
}

[host_provider("std.math.random.__host_next_i32")]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    return __random_jvm_next_i32(random, max_exclusive)
}

[host_provider("std.math.random.__host_next_f64")]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    return __random_jvm_next_f64(random)
}

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_new(): std.math.random.Random { }

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_with_seed(seed: i64): std.math.random.Random { }

[jvm("java.util.Random", "nextInt")]
private micro __random_jvm_next_i32(random: std.math.random.Random, max_exclusive: i32): i32 { }

[jvm("java.util.Random", "nextDouble")]
private micro __random_jvm_next_f64(random: std.math.random.Random): f64 { }
