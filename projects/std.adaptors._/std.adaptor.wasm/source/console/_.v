# std.web_sdk: Console API
# [js_builtin] 直接映射 JS 内置全局对象，无依赖
# console 是副作用函数，不标注 pure
# 字符串 contract 统一优先使用 utf8，由底层绑定承担宿主桥接

namespace std.adaptor.wasm.console;

[host_provider(std::console::write)]
micro write(message: utf8): unit {
    let host_message: utf16 = utf8_to_utf16(message)
    console_log(host_message)
}

[host_provider(std::console::write_line)]
micro write_line(message: utf8): unit {
    let host_message: utf16 = utf8_to_utf16(message)
    console_log(host_message)
}

[host_provider(std::console::error_line)]
micro error_line(message: utf8): unit {
    let host_message: utf16 = utf8_to_utf16(message)
    console_error(host_message)
}

#region 日志

[js_builtin("console.log")]
micro console_log(msg: utf16): unit

[js_builtin("console.warn")]
micro console_warn(msg: utf16): unit

[js_builtin("console.error")]
micro console_error(msg: utf16): unit

[js_builtin("console.debug")]
micro console_debug(msg: utf16): unit

[js_builtin("console.info")]
micro console_info(msg: utf16): unit

#endregion

#region 分组

[js_builtin("console.group")]
micro console_group(label: utf16): unit

[js_builtin("console.groupEnd")]
micro console_group_end(): unit

#endregion

#region 计时

[js_builtin("console.time")]
micro console_time(label: utf16): unit

[js_builtin("console.timeEnd")]
micro console_time_end(label: utf16): unit

#endregion

#region 清空

[js_builtin("console.clear")]
micro console_clear(): unit

#endregion
