namespace hello_world_smoke;

using std.io.{print_line};

[main]
micro hello_world() -> ExitCode {
    print_line("Hello World!")
    return ExitCode(0 as i32)
}

[main]
micro hello_world_utf8() -> ExitCode {
    print_line("你好，世界！")
    return ExitCode(0 as i32)
}
