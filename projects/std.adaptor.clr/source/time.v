namespace std.adaptor.clr.time;

[host_provider(std::io::now)]
micro now(): i64 {
    return __environment_tick_count64()
}

[host_provider(std::io::monotonic)]
micro monotonic(): i64 {
    return __environment_tick_count64()
}

[host_provider(std::io::sleep)]
micro sleep(ms: i32): unit {
    __thread_sleep(ms)
}

[clr("System.Runtime", "System.Environment", "TickCount64")]
private micro __environment_tick_count64(): i64

[clr("System.Runtime", "System.Threading.Thread", "Sleep")]
private micro __thread_sleep(milliseconds: i32): unit
