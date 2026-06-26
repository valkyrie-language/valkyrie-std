namespace std.adaptor.clr.math.random;

[host_provider(std::math::random::Random::new)]
micro host_new() -> std.math.random.Random {
    return __random_clr_new()
}

[host_provider(std::math::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    return __random_clr_with_seed(seed)
}

[host_provider(std::math::random::Random::next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    return __random_clr_next_i32(random, max_exclusive)
}

[host_provider(std::math::random::Random::next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    return __random_clr_next_f64(random)
}

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_new(): std.math.random.Random { }

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_with_seed(seed: i32): std.math.random.Random { }

[clr("System.Runtime", "System.Random", "Next")]
private micro __random_clr_next_i32(random: std.math.random.Random, max_exclusive: i32): i32 { }

[clr("System.Runtime", "System.Random", "NextDouble")]
private micro __random_clr_next_f64(random: std.math.random.Random): f64 { }
