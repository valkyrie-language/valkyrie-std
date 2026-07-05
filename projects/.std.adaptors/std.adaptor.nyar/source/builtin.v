# std.adaptor.nyar: VM 内置函数 [vm] 绑定
# 将 valkyrie-core 的运行时函数映射为 NyarVM opcode
# 无函数体 = [vm] 声明式绑定，编译器直接映射为对应 opcode

#region 输出

[vm("println")]
micro println_i32(value: i32): i32

[vm("println")]
private micro println_utf8(value: utf8): utf8

[vm("print")]
micro print_i32(value: i32): i32

[vm("print")]
private micro print_utf8(value: utf8): utf8

[host_provider(std::console::write)]
micro write(message: utf8): unit {
    print_utf8(message)
}

[host_provider(std::console::write_line)]
micro write_line(message: utf8): unit {
    println_utf8(message)
}

[host_provider(std::console::error_line)]
micro error_line(message: utf8): unit {
    println_utf8(message)
}

#endregion

#region 系统

[vm("exit")]
micro exit(code: i32): i32

[vm("sleep_ms")]
micro sleep_ms(ms: i32): i32

[vm("get_time")]
private micro __get_time(): i64

[host_provider(std::io::now)]
micro get_time(): i64 {
    return __get_time()
}

[host_provider(std::io::monotonic)]
micro monotonic_time(): i64 {
    return __get_time()
}

[host_provider(std::io::sleep)]
micro sleep(ms: i32): unit {
    sleep_ms(ms)
}

#endregion

#region 数学

[vm("math_sin")]
micro math_sin(x: f64): f64

[vm("math_cos")]
micro math_cos(x: f64): f64

[vm("math_sqrt")]
micro math_sqrt(x: f64): f64

[vm("math_rand")]
micro math_rand(): i32

#endregion
