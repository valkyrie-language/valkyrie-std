namespace std.adaptor.jvm.math;

# 数学 API

[host_provider("std.math.sqrt")]
micro sqrt(value: f64): f64 {
    return jvm_math_sqrt(value)
}

[host_provider("std.math.pow")]
micro pow(base: f64, exp: f64): f64 {
    return jvm_math_pow(base, exp)
}

[host_provider("std.math.floor")]
micro floor(value: f64): f64 {
    return jvm_math_floor(value)
}

[host_provider("std.math.ceil")]
micro ceil(value: f64): f64 {
    return jvm_math_ceil(value)
}

[host_provider("std.math.round")]
micro round(value: f64): f64 {
    return f64(jvm_math_round(value))
}

[host_provider("std.math.sin")]
micro sin(value: f64): f64 {
    return jvm_math_sin(value)
}

[host_provider("std.math.cos")]
micro cos(value: f64): f64 {
    return jvm_math_cos(value)
}

[host_provider("std.math.tan")]
micro tan(value: f64): f64 {
    return jvm_math_tan(value)
}

[host_provider("std.math.log")]
micro log(value: f64): f64 {
    return jvm_math_log(value)
}

[host_provider("std.math.log10")]
micro log10(value: f64): f64 {
    return jvm_math_log10(value)
}

[jvm("java.lang.Math", "abs"), pure]
micro jvm_math_abs_i32(value: i32): i32

[jvm("java.lang.Math", "abs"), pure]
micro jvm_math_abs_f64(value: f64): f64

[jvm("java.lang.Math", "max"), pure]
micro jvm_math_max_i32(a: i32, b: i32): i32

[jvm("java.lang.Math", "min"), pure]
micro jvm_math_min_i32(a: i32, b: i32): i32

[jvm("java.lang.Math", "sqrt"), pure]
micro jvm_math_sqrt(value: f64): f64

[jvm("java.lang.Math", "pow"), pure]
micro jvm_math_pow(x: f64, y: f64): f64

[jvm("java.lang.Math", "floor"), pure]
micro jvm_math_floor(value: f64): f64

[jvm("java.lang.Math", "ceil"), pure]
micro jvm_math_ceil(value: f64): f64

[jvm("java.lang.Math", "round"), pure]
micro jvm_math_round(value: f64): i64

[jvm("java.lang.Math", "sin"), pure]
micro jvm_math_sin(value: f64): f64

[jvm("java.lang.Math", "cos"), pure]
micro jvm_math_cos(value: f64): f64

[jvm("java.lang.Math", "tan"), pure]
micro jvm_math_tan(value: f64): f64

[jvm("java.lang.Math", "log"), pure]
micro jvm_math_log(value: f64): f64

[jvm("java.lang.Math", "log10"), pure]
micro jvm_math_log10(value: f64): f64

[jvm("java.lang.Math", "random"), pure]
micro jvm_math_random(): f64
