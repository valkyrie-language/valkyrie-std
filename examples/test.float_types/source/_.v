namespace float_types;

[main]
micro float_main() -> ExitCode {
    let a: f32 = 3.14
    let b: f64 = 3.141592653589793
    let c = a + b
    print("float types ok")
    return ExitCode(0 as i32)
}