namespace std.io;

<% match arch %>
<% case "wasm32" %>
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

micro get_current_directory() -> utf8 {
    return __host_get_current_directory()
}

micro file_exists(path: utf8) -> bool {
    return __host_file_exists(path)
}

micro directory_exists(path: utf8) -> bool {
    return __host_directory_exists(path)
}

micro create_directory(path: utf8) -> bool {
    __host_create_directory(path)
    return true
}

micro read_file_text(path: utf8) -> utf8 {
    return __host_read_file_text(path)
}

micro write_file_text(path: utf8, content: utf8) -> bool {
    __host_write_file_text(path, content)
    return true
}

micro get_files(path: utf8, pattern: utf8, recursive: bool) -> [utf8] {
    let search_option: i32 = if recursive { 1 } else { 0 }
    return __host_get_files(path, pattern, search_option)
}
<% else %>
[host_contract]
micro get_current_directory() -> utf8

[host_contract]
micro file_exists(path: utf8) -> bool

[host_contract]
micro directory_exists(path: utf8) -> bool

[host_contract]
micro create_directory(path: utf8) -> bool

[host_contract]
micro read_file_text(path: utf8) -> utf8

[host_contract]
micro write_file_text(path: utf8, content: utf8) -> bool

[host_contract]
micro get_files(path: utf8, pattern: utf8, recursive: bool) -> [utf8]
<% end %>
