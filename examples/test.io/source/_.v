namespace hello_world;

let shared = 42;

⍝ ./hello_world.exe
[main]
micro hello_world() {
    std.console.write_line("Hello World!")
    ExitCode(add_one(shared) as i32)
}

⍝ ./hello_world_utf8.exe 
[main]
micro hello_world_utf8() -> ExitCode {
    std.console.write_line("你好，世界！")
    return ExitCode(add_two(shared) as i32)
}

micro add_one(x: isize) {
    let one = 1;
    return x + one;
}

micro add_two(x: isize) {
    return add_one(add_one(x))
}
