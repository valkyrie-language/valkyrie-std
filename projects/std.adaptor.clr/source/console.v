namespace std.adaptor.clr.console;

[host_provider(std::console::write)]
micro write(message: utf8): unit {
    __console_write(message)
}

[host_provider(std::console::write_line)]
micro write_line(message: utf8): unit {
    __console_write_line(message)
}

[host_provider(std::console::error_line)]
micro error_line(message: utf8): unit {
    __console_error_line(message)
}

[host_provider(std::console::read_line)]
micro read_line(): utf8 {
    return __console_read_line()
}

[host_provider(std::console::read_char)]
micro read_char(): i32 {
    return __console_read_key()
}

[clr("System.Console", "System.Console", "Write")]
private micro __console_write(value: utf8): unit

[clr("System.Console", "System.Console", "WriteLine")]
private micro __console_write_line(value: utf8): unit

[clr("System.Console", "System.Console", "WriteLine")]
private micro __console_error_line(value: utf8): unit

[clr("System.Console", "System.Console", "ReadLine")]
private micro __console_read_line(): utf8

[clr("System.Console", "System.Console", "ReadKey")]
private micro __console_read_key(): i32
