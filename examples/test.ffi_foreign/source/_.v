namespace ffi_foreign;

[c("libm", "sqrt")]
foreign micro c_sqrt(x: f64) -> f64

[c("libc", "strlen")]
foreign micro c_strlen(s: utf8) -> i32

[c("libc", "memcpy")]
foreign micro c_memcpy(dst: rawptr, src: rawptr, n: i32) -> rawptr

[syscall(1)]
foreign micro syscall_write(fd: i32, buf: rawptr, count: i32) -> i32

[main]
micro ffi_foreign_main() -> ExitCode {
    let r = c_sqrt(16.0)
    print("sqrt(16)={r}")

    let s = "hello, ffi!"
    let n = c_strlen(s)
    print("strlen={n}")

    let src_buf = "test data"
    let dst_buf = allocate_buffer(64)
    c_memcpy(dst_buf, src_buf.as_ptr(), 11)
    print("memcpy ok")

    syscall_write(1, dst_buf, 11)
    print("\nwrite ok")

    deallocate(dst_buf)
    return ExitCode(0 as i32)
}
