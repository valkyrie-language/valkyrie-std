namespace std.adaptor.wasm.math.random;

using std.math.random.{Random};

[host_provider(std::math::random::__host_new)]
micro host_new() -> std.math.random.Random {
    return Random {
        _state: 0
    }
}

[host_provider(std::math::random::__host_with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    return Random {
        _state: seed
    }
}

[host_provider(std::math::random::__host_next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    if random._state != 0 {
        return std.math.random.__random_fallback_next_i32(random, max_exclusive)
    }

    return std.math.random.__random_scale_unit(std.adaptor.wasm.math.math_random(), max_exclusive)
}

[host_provider(std::math::random::__host_next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    if random._state != 0 {
        return f64(std.math.random.__random_fallback_next_i32(random, 2147483647)) / 2147483647.0
    }

    return std.adaptor.wasm.math.math_random()
}
