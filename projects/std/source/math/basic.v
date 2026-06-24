namespace std.math;

# std.math: basic 模块：基础数学函数

micro abs(value: f64): f64 {
    if value < 0.0 {
        return -value
    }

    return value
}

micro max(a: f64, b: f64): f64 {
    if a > b {
        return a
    }

    return b
}

micro min(a: f64, b: f64): f64 {
    if a < b {
        return a
    }

    return b
}

[host_contract]
micro sqrt(value: f64): f64

[host_contract]
micro pow(base: f64, exp: f64): f64

[host_contract]
micro floor(value: f64): f64

[host_contract]
micro ceil(value: f64): f64

[host_contract]
micro round(value: f64): f64

[host_contract]
micro sin(value: f64): f64

[host_contract]
micro cos(value: f64): f64

[host_contract]
micro tan(value: f64): f64

[host_contract]
micro log(value: f64): f64

micro log2(value: f64): f64 {
    return log(value) / log(2.0)
}

[host_contract]
micro log10(value: f64): f64

micro clamp(value: f64, lo: f64, hi: f64): f64 {
    if value < lo {
        return lo
    }

    if value > hi {
        return hi
    }

    return value
}

micro lerp(a: f64, b: f64, t: f64): f64 {
    return a + (b - a) * t
}
