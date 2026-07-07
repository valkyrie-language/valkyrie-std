# WASI component model: 时间 provider 与底层绑定

namespace std.adaptor.wasi.io;

[host_provider(std::io::now)]
micro now(): i64 {
    return wasi_clock_monotonic_now()
}

[host_provider(std::io::monotonic)]
micro monotonic(): i64 {
    return wasi_clock_monotonic_now()
}

[wasi("wasi:clocks/monotonic-clock", "now")]
private micro wasi_clock_monotonic_now(): i64

