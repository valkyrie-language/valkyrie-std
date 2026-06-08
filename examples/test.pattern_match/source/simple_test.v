namespace test;

[main]
micro main() -> ExitCode {
    let x = 42
    let label = match x {
        case 42 => "answer"
        else => "other"
    }
    return ExitCode(0 as i32)
}
