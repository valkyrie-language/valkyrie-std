namespace std.adaptor.jvm.console;

[host_provider("std.console.write")]
micro write(message: utf8): unit {
    __console_write(message)
}

[host_provider("std.console.write_line")]
micro write_line(message: utf8): unit {
    __console_write_line(message)
}

[host_provider("std.console.error_line")]
micro error_line(message: utf8): unit {
    __console_error_line(message)
}

[host_provider("std.console.read_line")]
micro read_line(): utf8 {
    return __console_read_line(0)
}

[host_provider("std.console.read_char")]
micro read_char(): i32 {
    return __console_read()
}

[jvm("java.lang.System", "out.print")]
private micro __console_write(value: utf8): unit

[jvm("java.lang.System", "out.println")]
private micro __console_write_line(value: utf8): unit

[jvm("java.lang.System", "err.println")]
private micro __console_error_line(value: utf8): unit

[jvm("java.lang.System", "in.read")]
private micro __console_read(): i32

[jvm("java.io.BufferedReader", "readLine")]
private micro __console_read_line(reader: i32): utf8
