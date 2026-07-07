# WASI Preview3 (p3-first) console provider
# 通过 wasi:cli/stdout@0.3#write-via-stream 写 stdout。
# 禁止 wasi_snapshot_preview1 / wasi:io/streams（p1/p2 旧路径，非长期架构）。

namespace std.adaptor.wasi.console;

[host_provider(std::console::write)]
micro write(message: utf8): unit {
    wasi_console_write(message)
}

[host_provider(std::console::write_line)]
micro write_line(message: utf8): unit {
    wasi_console_write(message)
    wasi_console_write("\n")
}

[host_provider(std::console::error_line)]
micro error_line(message: utf8): unit {
    wasi_console_write_err(message)
    wasi_console_write_err("\n")
}

[wasi("wasi:cli/stdout", "write-via-stream")]
private micro wasi_console_write(message: utf8): unit

[wasi("wasi:cli/stderr", "write-via-stream")]
private micro wasi_console_write_err(message: utf8): unit
