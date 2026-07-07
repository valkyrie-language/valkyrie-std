# std.adaptor.wasm: Node/WASM 文件系统 IO
# 通过 [wasm] 导入映射到 `.mjs` 启动壳提供的 `env.*` host 能力。
# Node 自举 build 路径依赖 read/write/exists/list/cwd 契约。

namespace std.adaptor.wasm.io;

[host_provider(std::io::get_current_directory)]
micro get_current_directory() -> utf8 {
    return __host_get_current_directory()
}

[host_provider(std::io::file_exists)]
micro file_exists(path: utf8) -> bool {
    return __host_file_exists(path)
}

[host_provider(std::io::directory_exists)]
micro directory_exists(path: utf8) -> bool {
    return __host_directory_exists(path)
}

[host_provider(std::io::create_directory)]
micro create_directory(path: utf8) -> bool {
    __host_create_directory(path)
    return true
}

[host_provider(std::io::read_file_text)]
micro read_file_text(path: utf8) -> utf8 {
    return __host_read_file_text(path)
}

[host_provider(std::io::write_file_text)]
micro write_file_text(path: utf8, content: utf8) -> bool {
    __host_write_file_text(path, content)
    return true
}

[host_provider(std::io::get_files)]
micro get_files(path: utf8, pattern: utf8, recursive: bool) -> [utf8] {
    let search_option: i32 = if recursive { 1 } else { 0 }
    return __host_get_files(path, pattern, search_option)
}

[wasm("env", "get_current_directory")]
private micro __host_get_current_directory(): utf8

[wasm("env", "file_exists")]
private micro __host_file_exists(path: utf8): bool

[wasm("env", "directory_exists")]
private micro __host_directory_exists(path: utf8): bool

[wasm("env", "create_directory")]
private micro __host_create_directory(path: utf8): unit

[wasm("env", "read_file_text")]
private micro __host_read_file_text(path: utf8): utf8

[wasm("env", "write_file_text")]
private micro __host_write_file_text(path: utf8, content: utf8): unit

[wasm("env", "get_files")]
private micro __host_get_files(path: utf8, pattern: utf8, search_option: i32): [utf8]
