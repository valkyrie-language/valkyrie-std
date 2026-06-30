namespace std.adaptor.clr.async;

[host_provider(std::async::spawn)]
[inline(always)]
private micro task_spawn(_task: micro() -> unit): unit {
    std.adaptor.clr.threading.task_run(0)
}

[host_provider(std::async::delay)]
[inline(always)]
private micro task_delay(ms: i32): unit {
    std.adaptor.clr.threading.task_delay(ms)
}
