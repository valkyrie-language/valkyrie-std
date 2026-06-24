namespace std.async;

# std.async: task - 异步任务

[host_contract]
micro spawn(task: micro() -> unit): unit {
    task()
}

[host_contract]
micro delay(ms: i32): unit {
    return
}

micro yield(): unit {
    delay(0)
}


