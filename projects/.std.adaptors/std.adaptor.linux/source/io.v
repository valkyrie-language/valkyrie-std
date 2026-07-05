# std.adaptor.linux: 控制台 IO
# 封装 POSIX write 系统调用为统一 print 接口
# 文件描述符：stdout = 1, stderr = 2
# 编码：内部 utf8 → C 端 c_str

[host_provider(std::console::write)]
micro print(msg: utf8): unit {
    let cs: c_str = utf8_to_c_str(msg)
    posix_write(1, cs, c_str_length(cs))
}

[host_provider(std::console::write_line)]
micro print_line(msg: utf8): unit {
    let line: utf8 = utf8_concat(msg, "\n")
    let cs: c_str = utf8_to_c_str(line)
    posix_write(1, cs, c_str_length(cs))
}

[host_provider(std::console::error_line)]
micro print_err(msg: utf8): unit {
    let cs: c_str = utf8_to_c_str(msg)
    posix_write(2, cs, c_str_length(cs))
}

[host_provider(std::console::read_line)]
micro read_line(): utf8 {
    return ""
}

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return 0
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return 0
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    posix_nanosleep(0, 0)
}
