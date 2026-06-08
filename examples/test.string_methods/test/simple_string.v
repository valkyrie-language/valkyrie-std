namespace string_methods::test;

[test]
micro simple_string() -> unit {
    let s = "Hello, World!"
    let r = "ok"
    print("len={s.length}, result={r}")
}

[test]
micro string_interpolation() -> unit {
    let name = "Valkyrie"
    let msg = "hello, {name}!"
    print(msg)
}

[test]
micro string_concat() -> unit {
    let a = "foo"
    let b = "bar"
    let c = "{a}{b}"
    print(c)
}

[test]
micro string_multiline() -> unit {
    let s = @"
        line 1
        line 2
    "
    print(s)
}

[test]
micro string_contains() -> unit {
    let s = "Hello, World!"
    let has = s.contains("World")
    print("has={has}")
}

[test]
micro string_replace() -> unit {
    let s = "Hello, World!"
    let r = s.replace("World", "Valkyrie")
    print(r)
}

[test]
micro string_split() -> unit {
    let s = "a,b,c"
    let parts = s.split(",")
    print("count={parts.length}")
}

[test]
micro string_starts_ends() -> unit {
    let s = "Hello, World!"
    let sw = s.starts_with("Hello")
    let ew = s.ends_with("!")
    print("start={sw}, end={ew}")
}

[test]
micro string_trim() -> unit {
    let s = "  spaced  "
    let t = s.trim()
    print("trimmed={t}")
}

[test]
micro string_case() -> unit {
    let s = "Hello"
    let u = s.to_upper()
    let l = s.to_lower()
    print("upper={u}, lower={l}")
}

[benchmark]
micro string_benchmark() -> unit {
    let s = "Hello, World!"
    let r = s.replace("World", "Valkyrie")
    print("bench: {r}")
}
