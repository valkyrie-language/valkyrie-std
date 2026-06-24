namespace std.adaptor.clr.math;

# 数学 API

[host_provider("std.math.sqrt")]
micro sqrt(value: f64): f64 {
    return math_sqrt(value)
}

[host_provider("std.math.pow")]
micro pow(base: f64, exp: f64): f64 {
    return math_pow(base, exp)
}

[host_provider("std.math.floor")]
micro floor(value: f64): f64 {
    return math_floor(value)
}

[host_provider("std.math.ceil")]
micro ceil(value: f64): f64 {
    return math_ceiling(value)
}

[host_provider("std.math.round")]
micro round(value: f64): f64 {
    return math_round(value)
}

[host_provider("std.math.sin")]
micro sin(value: f64): f64 {
    return math_sin(value)
}

[host_provider("std.math.cos")]
micro cos(value: f64): f64 {
    return math_cos(value)
}

[host_provider("std.math.tan")]
micro tan(value: f64): f64 {
    return math_tan(value)
}

[host_provider("std.math.log")]
micro log(value: f64): f64 {
    return math_log(value)
}

[host_provider("std.math.log10")]
micro log10(value: f64): f64 {
    return math_log10(value)
}

[clr("System.Runtime", "System.Math", "Abs"), pure]
micro math_abs_i32(value: i32): i32

[clr("System.Runtime", "System.Math", "Abs"), pure]
micro math_abs_f64(value: f64): f64

[clr("System.Runtime", "System.Math", "Max"), pure]
micro math_max_i32(a: i32, b: i32): i32

[clr("System.Runtime", "System.Math", "Min"), pure]
micro math_min_i32(a: i32, b: i32): i32

[clr("System.Runtime", "System.Math", "Sqrt"), pure]
micro math_sqrt(value: f64): f64

[clr("System.Runtime", "System.Math", "Pow"), pure]
micro math_pow(x: f64, y: f64): f64

[clr("System.Runtime", "System.Math", "Floor"), pure]
micro math_floor(value: f64): f64

[clr("System.Runtime", "System.Math", "Ceiling"), pure]
micro math_ceiling(value: f64): f64

[clr("System.Runtime", "System.Math", "Round"), pure]
micro math_round(value: f64): f64

[clr("System.Runtime", "System.Math", "Sin"), pure]
micro math_sin(value: f64): f64

[clr("System.Runtime", "System.Math", "Cos"), pure]
micro math_cos(value: f64): f64

[clr("System.Runtime", "System.Math", "Tan"), pure]
micro math_tan(value: f64): f64

[clr("System.Runtime", "System.Math", "Log"), pure]
micro math_log(value: f64): f64

[clr("System.Runtime", "System.Math", "Log10"), pure]
micro math_log10(value: f64): f64
