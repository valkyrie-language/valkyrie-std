namespace std.adaptor.jvm.async;

[host_provider(std::async::spawn)]
[inline(always)]
private micro task_spawn(_task: micro() -> unit): unit {
    std.adaptor.jvm.thread.jvm_thread_sleep(0)
}

[host_provider(std::async::delay)]
[inline(always)]
private micro task_delay(ms: i32): unit {
    std.adaptor.jvm.thread.jvm_thread_sleep(ms)
}
