namespace std.adaptor.wasm.async;

[host_provider(std::async::spawn)]
[inline(always)]
private micro task_spawn(_task: micro() -> unit): unit {
    std.adaptor.wasm.timer.queue_microtask(0)
}

[host_provider(std::async::delay)]
[inline(always)]
private micro task_delay(ms: i32): unit {
    std.adaptor.wasm.timer.set_timeout(0, ms)
}
