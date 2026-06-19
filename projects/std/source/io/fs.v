namespace std.io;

micro get_current_directory() -> utf8 {
    <% match arch %>
        <% case "clr" %>
    return __io_clr_directory_get_current_directory()
        <% case "jvm" %>
    return std.adaptor.jvm.system.jvm_get_property("user.dir")
        <% else %>
    return ""
    <% end match %>
}

micro file_exists(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
    return __io_clr_file_exists(path)
        <% case "jvm" %>
    return __io_jvm_file_exists(path)
        <% else %>
    return false
    <% end match %>
}

micro directory_exists(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
    return __io_clr_directory_exists(path)
        <% case "jvm" %>
    return __io_jvm_is_directory(path)
        <% else %>
    return false
    <% end match %>
}

micro create_directory(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
    __io_clr_directory_create(path)
    return true
        <% case "jvm" %>
    return __io_jvm_mkdirs(path)
        <% else %>
    return false
    <% end match %>
}

micro read_file_text(path: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
    return __io_clr_file_read_all_text(path)
        <% case "jvm" %>
    let handle: any = __io_jvm_path_of(path)
    return __io_jvm_file_read_all_text(handle)
        <% else %>
    return ""
    <% end match %>
}

micro write_file_text(path: utf8, content: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
    __io_clr_file_write_all_text(path, content)
    return true
        <% case "jvm" %>
    let handle: any = __io_jvm_path_of(path)
    __io_jvm_file_write_all_text(handle, content)
    return true
        <% else %>
    return false
    <% end match %>
}

micro get_files(path: utf8, pattern: utf8, recursive: bool) -> [utf8] {
    <% match arch %>
        <% case "clr" %>
    let search_option: i32 = if recursive { 1 } else { 0 }
    return __io_clr_directory_get_files(path, pattern, search_option)
        <% else %>
    return []
    <% end match %>
}

[clr("System.IO.FileSystem", "System.IO.File", "ReadAllText")]
private micro __io_clr_file_read_all_text(path: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.File", "WriteAllText")]
private micro __io_clr_file_write_all_text(path: utf8, content: utf8): unit

[clr("System.IO.FileSystem", "System.IO.File", "Exists")]
private micro __io_clr_file_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "Exists")]
private micro __io_clr_directory_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "CreateDirectory")]
private micro __io_clr_directory_create(path: utf8): unit

[clr("System.IO.FileSystem", "System.IO.Directory", "GetCurrentDirectory")]
private micro __io_clr_directory_get_current_directory(): utf8

[clr("System.IO.FileSystem", "System.IO.Directory", "GetFiles")]
private micro __io_clr_directory_get_files(path: utf8, pattern: utf8, search_option: i32): [utf8]

[jvm("java.io.File", "exists")]
private micro __io_jvm_file_exists(path: utf8): bool

[jvm("java.io.File", "mkdirs")]
private micro __io_jvm_mkdirs(path: utf8): bool

[jvm("java.io.File", "isDirectory")]
private micro __io_jvm_is_directory(path: utf8): bool

[jvm("java.nio.file.Path", "of")]
private micro __io_jvm_path_of(path: utf8): any

[jvm("java.nio.file.Files", "readString", "(Ljava/nio/file/Path;)Ljava/lang/String;")]
private micro __io_jvm_file_read_all_text(path_handle: any): utf8

[jvm("java.nio.file.Files", "writeString", "(Ljava/nio/file/Path;Ljava/lang/String;)Ljava/nio/file/Path;")]
private micro __io_jvm_file_write_all_text(path_handle: any, content: utf8): any
