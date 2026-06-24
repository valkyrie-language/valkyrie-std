namespace std.math.random;

[clr("System.Runtime", "System.Random")]
[jvm("java.util.Random")]
class Random {
    _state: i32
}

imply Random {
    micro new() -> Self {
        return __host_new()
    }

    micro with_seed(seed: i32) -> Self {
        let resolved_seed: i32 = __random_normalize_seed(seed)
        return __host_with_seed(resolved_seed)
    }

    micro next_i32(mut self, max_exclusive: i32) -> i32 {
        if max_exclusive <= 0 {
            return 0
        }

        return __host_next_i32(self, max_exclusive)
    }

    micro next_range(mut self, min: i32, max: i32) -> i32 {
        if max <= min {
            return min
        }

        return min + self.next_i32(max - min)
    }

    micro next_bool(mut self) -> bool {
        return self.next_i32(2) == 1
    }

    micro next_f64(mut self) -> f64 {
        return __host_next_f64(self)
    }
}

[host_contract]
micro __host_new() -> Random

[host_contract]
micro __host_with_seed(seed: i32) -> Random

[host_contract]
micro __host_next_i32(random: Random, max_exclusive: i32) -> i32

[host_contract]
micro __host_next_f64(random: Random) -> f64

micro __random_normalize_seed(seed: i32) -> i32 {
    if seed == 0 {
        return 1
    }

    return seed
}

micro __random_scale_unit(unit_value: f64, max_exclusive: i32) -> i32 {
    let scaled: i32 = i32(unit_value * f64(max_exclusive))
    if scaled >= max_exclusive {
        return max_exclusive - 1
    }

    if scaled < 0 {
        return 0
    }

    return scaled
}

micro __random_fallback_next_i32(mut random: Random, max_exclusive: i32) -> i32 {
    let next: i32 = random._state * 1103515245 + 12345
    random._state = next

    if next < 0 {
        return (-next) % max_exclusive
    }

    return next % max_exclusive
}
