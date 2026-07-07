namespace std.adaptor.jvm.io;

[host_provider(std::io::now)]
micro now(): i64 {
    return __system_current_time_millis()
}

[host_provider(std::io::monotonic)]
micro monotonic(): i64 {
    return __system_nano_time()
}

[host_provider(std::io::sleep)]
micro sleep(ms: i32): unit {
    __thread_sleep(ms)
}

[jvm("java.lang.System", "currentTimeMillis")]
private micro __system_current_time_millis(): i64

[jvm("java.lang.System", "nanoTime")]
private micro __system_nano_time(): i64

[jvm("java.lang.Thread", "sleep")]
private micro __thread_sleep(milliseconds: i32): unit
