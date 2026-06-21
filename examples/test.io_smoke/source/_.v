namespace hello_world_smoke;

[clr("System.Console", "System.Console", "WriteLine")]
micro console_write_line(value: utf8): unit

[main]
micro hello_world() -> ExitCode {
    console_write_line("Hello World!")
    return ExitCode(0 as i32)
}

[main]
micro hello_world_utf8() -> ExitCode {
    console_write_line("你好，世界！")
    return ExitCode(0 as i32)
}