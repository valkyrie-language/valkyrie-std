namespace hello_world;

using std.io.{print_line};

⍝ ./hello_world.exe
[main]
micro hello_world() {
    print_line("Hello World!")
    ExitCode(add_one(42) as i32)
}

⍝ ./hello_world_utf8.exe 
[main]
micro hello_world_utf8() -> ExitCode {
    print_line("你好，世界！")
    return ExitCode(add_two(42) as i32)
}

micro add_one(x: isize) -> isize {
    let one = 1;
    return x + one;
}

micro add_two(x: isize) -> isize {
    return add_one(add_one(x))
}
