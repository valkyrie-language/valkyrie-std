# std.adaptor.windows: 时间 contract

namespace std.adaptor.windows.io;

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return i64(win_get_tick_count())
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return i64(win_get_tick_count())
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    win_sleep(ms)
}
