# std.io: read — 控制台输入

namespace std.io;

micro read_line(): utf8 {
    return std.console.read_line()
}

micro read_all(): utf8 {
    return read_file_text("")
}

micro read_char(): i32 {
    return std.console.read_char()
}

micro read_int(): Option<i32> {
    let line: utf8 = std.io.read_line()
    if line == "" {
        return None
    }
    return Some(to_i32(line))
}

micro read_f64(): Option<f64> {
    let line: utf8 = std.io.read_line()
    if line == "" {
        return None
    }
    return Some(to_f64(line))
}

micro stdin_lines(): List<utf8> {
    let lines: List<utf8> = List::new()
    let mut line: utf8 = std.io.read_line()
    while line != "" {
        List.push(lines, line)
        line = std.io.read_line()
    }
    return lines
}
