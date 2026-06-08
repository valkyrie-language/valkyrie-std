namespace integer_types;

[main]
micro integer_main() -> ExitCode {
    let a: i8 = 127
    let b: i16 = 32767
    let c: i32 = 2147483647
    let d: i64 = 9223372036854775807
    let e: u8 = 255
    let f: u16 = 65535
    let g: u32 = 4294967295
    let h: u64 = 18446744073709551615
    print("integer types ok")
    return ExitCode(0 as i32)
}