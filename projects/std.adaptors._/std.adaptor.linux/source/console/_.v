# std.adaptor.linux: 控制台 IO
# 封装 Linux write 系统调用为统一 console 接口
# 文件描述符：stdout = 1, stderr = 2
# 编码：内部 utf8 → 内核缓冲 c_str

namespace std.adaptor.linux.console;

[host_provider(std::console::write)]
micro print(msg: utf8): unit {
    let cs: c_str = utf8_to_c_str(msg)
    sys_write(1, cs, c_str_length(cs))
}

[host_provider(std::console::write_line)]
micro print_line(msg: utf8): unit {
    let line: utf8 = utf8_concat(msg, "\n")
    let cs: c_str = utf8_to_c_str(line)
    sys_write(1, cs, c_str_length(cs))
}

[host_provider(std::console::error_line)]
micro print_err(msg: utf8): unit {
    let cs: c_str = utf8_to_c_str(msg)
    sys_write(2, cs, c_str_length(cs))
}

[host_provider(std::console::read_line)]
micro read_line(): utf8 {
    return ""
}
