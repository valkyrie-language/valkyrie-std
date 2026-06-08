namespace unite_compact::test;

unite CompactResult { Ok(i32), Err(string) }

[test]
micro simple_unite() -> unit {
    let ok = CompactResult::Ok(42)
    print("unite ok")
}
