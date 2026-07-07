# WASI FS host providers for `std.io` contracts.
#
# 在 `wasi:filesystem/*` Canonical ABI 齐备前，用纯 guest 实现占位：
# 不合成虚假的 wasi 导入（否则 wasmtime 无法链接真实 filesystem world）。
# `build` 再编译会因 file_exists/read 失败而诚实报错；`--version` / `--help` 可先通路。

namespace std.adaptor.wasi.io;

[host_provider(std::io::get_current_directory)]
micro get_current_directory(): utf8 {
    return "."
}

[host_provider(std::io::file_exists)]
micro file_exists(path: utf8): bool {
    return false
}

[host_provider(std::io::directory_exists)]
micro directory_exists(path: utf8): bool {
    return false
}

[host_provider(std::io::create_directory)]
micro create_directory(path: utf8): bool {
    return false
}

[host_provider(std::io::read_file_text)]
micro read_file_text(path: utf8): utf8 {
    return ""
}

[host_provider(std::io::write_file_text)]
micro write_file_text(path: utf8, content: utf8): bool {
    return false
}

[host_provider(std::io::get_files)]
micro get_files(path: utf8, pattern: utf8, recursive: bool): [utf8] {
    return []
}
