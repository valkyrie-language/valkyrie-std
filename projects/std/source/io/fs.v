namespace std.io;

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
