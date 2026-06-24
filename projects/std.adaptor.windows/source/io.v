# std.adaptor.windows: 控制台 IO
# 封装 Win32 Console API 为统一 print 接口
# Win32 控制台使用 UTF-16（WriteConsoleW）
# 编码：内部 utf8 → Windows utf16
# STD_OUTPUT_HANDLE = -11, STD_ERROR_HANDLE = -12

# std.adaptor.windows: 控制台 IO
# 封装 Win32 Console API 为统一 print 接口
# Win32 控制台使用 UTF-16（WriteConsoleW）
# 编码：内部 utf8 → Windows utf16
# STD_OUTPUT_HANDLE = -11, STD_ERROR_HANDLE = -12

[host_provider("std.console.write")]
micro print(msg: utf8): unit {
    let handle: i32 = win_get_std_handle(-11)
    let msg16: utf16 = utf8_to_utf16(msg)
    win_write_console(handle, msg16, utf16_len(msg16))
}

[host_provider("std.console.write_line")]
micro print_line(msg: utf8): unit {
    let handle: i32 = win_get_std_handle(-11)
    let line: utf8 = utf8_concat(msg, "\n")
    let msg16: utf16 = utf8_to_utf16(line)
    win_write_console(handle, msg16, utf16_len(msg16))
}

[host_provider("std.console.error_line")]
micro print_err(msg: utf8): unit {
    let handle: i32 = win_get_std_handle(-12)
    let msg16: utf16 = utf8_to_utf16(msg)
    win_write_console(handle, msg16, utf16_len(msg16))
}

[host_provider("std.console.read_line")]
micro read_line(): utf8 {
    return ""
}

[host_provider("std.io.now")]
micro time_ms(): i64 {
    return i64(win_get_tick_count())
}

[host_provider("std.io.monotonic")]
micro monotonic_ms(): i64 {
    return i64(win_get_tick_count())
}

[host_provider("std.io.sleep")]
micro sleep_ms(ms: i32): unit {
    win_sleep(ms)
}
