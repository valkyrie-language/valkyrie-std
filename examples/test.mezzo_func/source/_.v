namespace mezzo_func;

mezzo process(data: &mut i32) -> i32 {
    data += 1
    return data
}

[main]
micro mezzo_main() -> ExitCode {
    let mut x = 41
    let result = process(&mut x)
    print("mezzo result={result}")
    return ExitCode(0 as i32)
}