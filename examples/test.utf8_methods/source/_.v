namespace utf8_methods;

[main]
micro utf8_methods_main() -> ExitCode {
    let s = "Hello, World!"
    print("len={s.length}")
    print("upper={s.to_upper()}")
    print("lower={s.to_lower()}")
    print("trim={'  spaced  '.trim()}")
    print("slice={s.slice(0, 5)}")
    print("contains={s.contains(\"World\")}")
    print("replace={s.replace(\"World\", \"Valkyrie\")}")
    print("split={s.split(\",\")}")
    print("starts={s.starts_with(\"Hello\")}")
    print("ends={s.ends_with(\"!\")}")
    print("reverse={s.reverse()}")

    return ExitCode(0 as i32)
}
