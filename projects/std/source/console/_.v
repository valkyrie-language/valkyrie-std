# std.console: 统一控制台 API
namespace std.console;

micro write(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
    __console_clr_write(message)
        <% case "jvm" %>
    __console_jvm_write(message)
        <% case "wasm32" %>
    std.adaptor.wasm.console.console_log(message)
        <% case "nyar" %>
    std.adaptor.nyar.builtin.print_utf8(message)
        <% else %>
    return
    <% end match %>
}

micro write_line(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
    __console_clr_write_line(message)
        <% case "jvm" %>
    __console_jvm_write_line(message)
        <% case "wasm32" %>
    std.adaptor.wasm.console.console_log(message)
        <% case "nyar" %>
    std.adaptor.nyar.builtin.println_utf8(message)
        <% else %>
    return
    <% end match %>
}

micro error_line(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
    __console_clr_write(message)
        <% case "jvm" %>
    __console_jvm_error_line(message)
        <% case "wasm32" %>
    std.adaptor.wasm.console.console_error(message)
        <% case "nyar" %>
    std.adaptor.nyar.builtin.println_utf8(message)
        <% else %>
    return
    <% end match %>
}

micro read_line(): utf8 {
    <% match arch %>
        <% case "clr" %>
    return __console_clr_read_line()
        <% case "jvm" %>
    return __console_jvm_read_line(0)
        <% else %>
    return ""
    <% end match %>
}

micro read_char(): i32 {
    <% match arch %>
        <% case "clr" %>
    return __console_clr_read_key()
        <% case "jvm" %>
    return __console_jvm_read()
        <% else %>
    return 0
    <% end match %>
}

[clr("System.Console", "System.Console", "Write")]
private micro __console_clr_write(value: utf8): unit { }

[clr("System.Console", "System.Console", "WriteLine")]
private micro __console_clr_write_line(value: utf8): unit { }

[clr("System.Console", "System.Console", "ReadLine")]
private micro __console_clr_read_line(): utf8 { }

[clr("System.Console", "System.Console", "ReadKey")]
private micro __console_clr_read_key(): i32 { }

[jvm("java.lang.System", "out.print")]
private micro __console_jvm_write(value: utf8): unit

[jvm("java.lang.System", "out.println")]
private micro __console_jvm_write_line(value: utf8): unit

[jvm("java.lang.System", "err.println")]
private micro __console_jvm_error_line(value: utf8): unit

[jvm("java.lang.System", "in.read")]
private micro __console_jvm_read(): i32

[jvm("java.io.BufferedReader", "readLine")]
private micro __console_jvm_read_line(reader: i32): utf8
