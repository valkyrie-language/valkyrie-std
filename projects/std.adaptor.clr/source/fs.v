namespace std.adaptor.clr.fs;

[host_provider("std.io.get_current_directory")]
micro get_current_directory() -> utf8 {
    return __directory_get_current_directory()
}

[host_provider("std.io.file_exists")]
micro file_exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider("std.io.directory_exists")]
micro directory_exists(path: utf8) -> bool {
    return __directory_exists(path)
}

[host_provider("std.io.create_directory")]
micro create_directory(path: utf8) -> bool {
    __directory_create(path)
    return true
}

[host_provider("std.io.read_file_text")]
micro read_file_text(path: utf8) -> utf8 {
    return __file_read_all_text(path)
}

[host_provider("std.io.write_file_text")]
micro write_file_text(path: utf8, content: utf8) -> bool {
    __file_write_all_text(path, content)
    return true
}

[host_provider("std.io.get_files")]
micro get_files(path: utf8, pattern: utf8, recursive: bool) -> [utf8] {
    let search_option: i32 = if recursive { 1 } else { 0 }
    return __directory_get_files(path, pattern, search_option)
}

[clr("System.IO.FileSystem", "System.IO.File", "ReadAllText")]
private micro __file_read_all_text(path: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.File", "WriteAllText")]
private micro __file_write_all_text(path: utf8, content: utf8): unit

[clr("System.IO.FileSystem", "System.IO.File", "Exists")]
private micro __file_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "Exists")]
private micro __directory_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "CreateDirectory")]
private micro __directory_create(path: utf8): unit

[clr("System.IO.FileSystem", "System.IO.Directory", "GetCurrentDirectory")]
private micro __directory_get_current_directory(): utf8

[clr("System.IO.FileSystem", "System.IO.Directory", "GetFiles")]
private micro __directory_get_files(path: utf8, pattern: utf8, search_option: i32): [utf8]
