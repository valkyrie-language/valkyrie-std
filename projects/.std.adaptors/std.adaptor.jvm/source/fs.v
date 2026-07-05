namespace std.adaptor.jvm.fs;

[host_provider(std::io::get_current_directory)]
micro get_current_directory() -> utf8 {
    return __system_get_property("user.dir")
}

[host_provider(std::io::file_exists)]
micro file_exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider(std::io::directory_exists)]
micro directory_exists(path: utf8) -> bool {
    return __is_directory(path)
}

[host_provider(std::io::create_directory)]
micro create_directory(path: utf8) -> bool {
    return __mkdirs(path)
}

[host_provider(std::io::read_file_text)]
micro read_file_text(path: utf8) -> utf8 {
    let handle: any = __path_of(path)
    return __file_read_all_text(handle)
}

[host_provider(std::io::write_file_text)]
micro write_file_text(path: utf8, content: utf8) -> bool {
    let handle: any = __path_of(path)
    __file_write_all_text(handle, content)
    return true
}

[jvm("java.lang.System", "getProperty")]
private micro __system_get_property(key: utf8): utf8

[jvm("java.io.File", "exists")]
private micro __file_exists(path: utf8): bool

[jvm("java.io.File", "mkdirs")]
private micro __mkdirs(path: utf8): bool

[jvm("java.io.File", "isDirectory")]
private micro __is_directory(path: utf8): bool

[jvm("java.nio.file.Path", "of")]
private micro __path_of(path: utf8): any

[jvm("java.nio.file.Files", "readString", "(Ljava/nio/file/Path;)Ljava/lang/String;")]
private micro __file_read_all_text(path_handle: any): utf8

[jvm("java.nio.file.Files", "writeString", "(Ljava/nio/file/Path;Ljava/lang/String;)Ljava/nio/file/Path;")]
private micro __file_write_all_text(path_handle: any, content: utf8): any
