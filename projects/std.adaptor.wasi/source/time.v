# WASI component model: 时间 provider 与底层绑定

[host_provider("std.io.now")]
micro now(): i64 {
    return wasi_clock_monotonic_now()
}

[host_provider("std.io.monotonic")]
micro monotonic(): i64 {
    return wasi_clock_monotonic_now()
}

[wasi_p2("wasi:clocks/monotonic-clock", "now")]
private extern wasi_clock_monotonic_now(): i64

[wasi_p2("wasi:clocks/monotonic-clock", "resolution")]
private extern wasi_clock_monotonic_resolution(): i64

[wasi_p2("wasi:clocks/wall-clock", "now")]
private extern wasi_clock_wall_now(): (i64, i32)
