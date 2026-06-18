namespace std.math.random;

[clr("System.Runtime", "System.Random")]
[jvm("java.util.Random")]
class Random {
    _state: i32
}

imply Random {
    micro new() -> Self {
        <% match arch %>
            <% case "clr" %>
            return __random_clr_new()
            <% case "jvm" %>
            return __random_jvm_new()
            <% case "wasm32" %>
            return Self { _state: 0 }
            <% case "nyar" %>
            return Self { _state: 0 }
            <% else %>
            return Self { _state: 1 }
        <% end match %>
    }

    micro with_seed(seed: i32) -> Self {
        let resolved_seed: i32 = __random_normalize_seed(seed)

        <% match arch %>
            <% case "clr" %>
            return __random_clr_with_seed(resolved_seed)
            <% case "jvm" %>
            return __random_jvm_with_seed(i64(resolved_seed))
            <% else %>
            return Self { _state: resolved_seed }
        <% end match %>
    }

    micro next_i32(mut self, max_exclusive: i32) -> i32 {
        if max_exclusive <= 0 {
            return 0
        }

        <% match arch %>
            <% case "clr" %>
            return __random_clr_next_i32(self, max_exclusive)
            <% case "jvm" %>
            return __random_jvm_next_i32(self, max_exclusive)
            <% case "wasm32" %>
            if self._state != 0 {
                return __random_fallback_next_i32(self, max_exclusive)
            }

            return __random_scale_unit(std.adaptor.wasm.math.math_random(), max_exclusive)
            <% case "nyar" %>
            if self._state != 0 {
                return __random_fallback_next_i32(self, max_exclusive)
            }

            return __random_nyar_next_i32(max_exclusive)
            <% else %>
            return __random_fallback_next_i32(self, max_exclusive)
        <% end match %>
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
        <% match arch %>
            <% case "clr" %>
            return __random_clr_next_f64(self)
            <% case "jvm" %>
            return __random_jvm_next_f64(self)
            <% case "wasm32" %>
            if self._state != 0 {
                return f64(__random_fallback_next_i32(self, 2147483647)) / 2147483647.0
            }

            return std.adaptor.wasm.math.math_random()
            <% case "nyar" %>
            if self._state != 0 {
                return f64(__random_fallback_next_i32(self, 2147483647)) / 2147483647.0
            }

            return f64(__random_nyar_next_i32(2147483647)) / 2147483647.0
            <% else %>
            return f64(__random_fallback_next_i32(self, 2147483647)) / 2147483647.0
        <% end match %>
    }
}

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

micro __random_nyar_next_i32(max_exclusive: i32) -> i32 {
    let value: i32 = std.adaptor.nyar.builtin.math_rand()
    if value < 0 {
        return (-value) % max_exclusive
    }

    return value % max_exclusive
}

micro __random_fallback_next_i32(mut random: Random, max_exclusive: i32) -> i32 {
    let next: i32 = random._state * 1103515245 + 12345
    random._state = next

    if next < 0 {
        return (-next) % max_exclusive
    }

    return next % max_exclusive
}

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_new(): Random { }

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_with_seed(seed: i32): Random { }

[clr("System.Runtime", "System.Random", "Next")]
private micro __random_clr_next_i32(random: Random, max_exclusive: i32): i32 { }

[clr("System.Runtime", "System.Random", "NextDouble")]
private micro __random_clr_next_f64(random: Random): f64 { }

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_new(): Random { }

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_with_seed(seed: i64): Random { }

[jvm("java.util.Random", "nextInt")]
private micro __random_jvm_next_i32(random: Random, max_exclusive: i32): i32 { }

[jvm("java.util.Random", "nextDouble")]
private micro __random_jvm_next_f64(random: Random): f64 { }
