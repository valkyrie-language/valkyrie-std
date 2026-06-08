namespace ffi_foreign::test;

[c("libm", "sqrt")]
foreign micro c_sqrt(x: f64) -> f64

[c("libm", "pow")]
foreign micro c_pow(base: f64, exp: f64) -> f64

[c("libc", "strlen")]
foreign micro c_strlen(s: utf8) -> i32

[c("libc", "abs")]
foreign micro c_abs(x: i32) -> i32

[test]
micro simple_ffi_c_sqrt() -> unit {
    let r = c_sqrt(9.0)
    print("sqrt={r}")
}

[test]
micro ffi_c_pow() -> unit {
    let r = c_pow(2.0, 10.0)
    print("pow={r}")
}

[test]
micro ffi_c_strlen() -> unit {
    let s = "hello"
    let n = c_strlen(s)
    print("len={n}")
}

[test]
micro ffi_c_abs() -> unit {
    let n = c_abs(-42)
    print("abs={n}")
}

[test]
micro ffi_pointer_pass() -> unit {
    let buf = allocate_buffer(64)
    print("buf={buf != null}")
    deallocate(buf)
}

[test]
micro ffi_string_interop() -> unit {
    let s = "test"
    let utf8_view = s.as_utf8()
    let n = c_strlen(utf8_view)
    print("len={n}")
}

[test]
micro ffi_primitive_types() -> unit {
    let f = c_sqrt(16.0 as f64)
    let i = c_abs(-100)
    let s = c_strlen("test")
    print("f={f}, i={i}, s={s}")
}

[benchmark]
micro ffi_benchmark() -> unit {
    let r = c_sqrt(100.0 as f64)
    print("bench={r}")
}
