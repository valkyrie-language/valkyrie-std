# std.adaptor.macos: 时间 contract

namespace std.adaptor.macos.io;

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return 0
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return 0
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32) {
    return
}
