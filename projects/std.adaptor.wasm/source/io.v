# std.web_sdk: 控制台 IO
# 封装 console / performance / timer API 为统一 print 接口
# 浏览器端 JS 自动换行，print 即为 println
# 编码：内部 utf8 → JS 端 utf16

namespace std.adaptor.wasm.io;

#region 输出

micro print(msg: utf8): unit {
    let msg16: utf16 = utf8_to_utf16(msg)
    console_log(msg16)
}

micro print_line(msg: utf8): unit {
    print(msg)
}

micro print_err(msg: utf8): unit {
    let msg16: utf16 = utf8_to_utf16(msg)
    console_error(msg16)
}

#endregion

#region 输入

micro read_line(): utf8 {
    return ""
}

#endregion

#region 计时

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    set_timeout(0, ms)
}

#endregion




