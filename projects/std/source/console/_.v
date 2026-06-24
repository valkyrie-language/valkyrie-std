# std.console: 统一控制台 API
namespace std.console;

[host_contract]
micro write(message: utf8): unit

[host_contract]
micro write_line(message: utf8): unit

[host_contract]
micro error_line(message: utf8): unit

[host_contract]
micro read_line(): utf8

[host_contract]
micro read_char(): i32
