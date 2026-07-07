# std.adaptor.linux: 时间 contract（内核 syscall）

namespace std.adaptor.linux.io;

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return 0
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return 0
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    sys_nanosleep(0, 0)
}
