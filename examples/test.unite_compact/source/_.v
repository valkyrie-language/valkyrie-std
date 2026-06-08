namespace unite_compact;

unite CompactResult { Ok(i32), Err(string) }

[main]
micro unite_main() -> ExitCode {
    let ok = CompactResult::Ok(42)
    let err = CompactResult::Err("failed")
    print("unite ok")
    return ExitCode(0 as i32)
}