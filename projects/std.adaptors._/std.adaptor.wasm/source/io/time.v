# std.adaptor.wasm: 时间 contract

namespace std.adaptor.wasm.io;

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    set_timeout(0, ms)
}
