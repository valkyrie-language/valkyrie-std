# std.adaptor.macos: 控制台 IO
# 封装 Foundation NSLog 为统一 console 接口
# NSLog 自动追加换行，并使用 UTF-8 编码，无需额外转换

namespace std.adaptor.macos.console;

[host_provider(std::console::write)]
micro print(msg: utf8) {
    darwin_ns_log(msg)
}

[host_provider(std::console::write_line)]
micro print_line(msg: utf8) {
    darwin_ns_log(msg)
}

[host_provider(std::console::error_line)]
micro print_err(msg: utf8) {
    darwin_ns_log(msg)
}

[host_provider(std::console::read_line)]
micro read_line(): utf8 {
    return ""
}
