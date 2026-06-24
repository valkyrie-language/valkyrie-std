namespace std.adaptor.linux.math.random;

[host_provider(std::math::random::__host_new)]
micro host_new() -> std.math.random.Random {
    return std.math.random.Random {
        _state: 1
    }
}

[host_provider(std::math::random::__host_with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    return std.math.random.Random {
        _state: seed
    }
}

[host_provider(std::math::random::__host_next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    return std.math.random.__random_fallback_next_i32(random, max_exclusive)
}

[host_provider(std::math::random::__host_next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    return f64(std.math.random.__random_fallback_next_i32(random, 2147483647)) / 2147483647.0
}
