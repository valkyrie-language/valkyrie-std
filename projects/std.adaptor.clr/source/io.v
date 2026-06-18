namespace std.adaptor.clr.io;

# 文件系统 API

[clr("System.IO.FileSystem", "System.IO.File", "ReadAllText")]
micro file_read_all_text(path: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.File", "WriteAllText")]
micro file_write_all_text(path: utf8, content: utf8): unit

[clr("System.IO.FileSystem", "System.IO.File", "Exists")]
micro file_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.File", "Delete")]
micro file_delete(path: utf8): unit

[clr("System.IO.FileSystem", "System.IO.File", "AppendAllText")]
micro file_append_all_text(path: utf8, content: utf8): unit

[clr("System.IO.FileSystem", "System.IO.Directory", "Exists")]
micro directory_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "CreateDirectory")]
micro directory_create(path: utf8): unit

[clr("System.IO.FileSystem", "System.IO.Directory", "Delete")]
micro directory_delete(path: utf8, recursive: bool): unit

[clr("System.IO.FileSystem", "System.IO.Directory", "GetFiles")]
micro directory_get_files(path: utf8): i32

[clr("System.IO.FileSystem", "System.IO.Directory", "GetCurrentDirectory")]
micro directory_get_current_directory(): utf8

[clr("System.IO.FileSystem", "System.IO.Path", "Combine")]
micro path_combine(path1: utf8, path2: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.Path", "GetExtension")]
micro path_get_extension(path: utf8): utf8

[clr("System.IO.FileSystem", "System.IO.Path", "GetFileName")]
micro path_get_file_name(path: utf8): utf8

