namespace unity.engine.sdk.io;

# Unity 持久化目录文件 IO（`Application.persistentDataPath`）

micro persistent_data_path() -> utf8 {
    return __unity_persistent_data_path()
}

[host_provider(std::io::read_file_text)]
micro read_file_text(path: utf8) -> utf8 {
    let root = persistent_data_path()
    let full = join_path(root, path)
    return __file_read_all_text(full)
}

[host_provider(std::io::write_file_text)]
micro write_file_text(path: utf8, content: utf8) -> bool {
    let root = persistent_data_path()
    let full = join_path(root, path)
    __file_write_all_text(full, content)
    return true
}

micro join_path(left: utf8, right: utf8) -> utf8 {
    if left.ends_with("/") {
        return left + right
    }
    return left + "/" + right
}

[clr("UnityEngine", "UnityEngine.Application", "get_persistentDataPath")]
micro __unity_persistent_data_path(): utf8

[clr("System.IO.FileSystem", "System.IO.File", "ReadAllText")]
private micro __file_read_all_text(path: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.File", "WriteAllText")]
private micro __file_write_all_text(path: utf8, content: utf8): unit
