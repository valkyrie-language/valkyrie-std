namespace std.adaptor.clr.threading;

# 线程 API

[clr("System.Runtime", "System.Threading.Tasks.Task", "Run")]
micro task_run(action: i32): i32

[clr("System.Runtime", "System.Threading.Tasks.Task", "Delay")]
micro task_delay(milliseconds: i32): i32

[clr("System.Runtime", "System.Threading.Tasks.Task", "WaitAll")]
micro task_wait_all(tasks: i32): unit

[clr("System.Runtime", "System.Threading.Thread", "Sleep")]
micro thread_sleep(milliseconds: i32): unit

