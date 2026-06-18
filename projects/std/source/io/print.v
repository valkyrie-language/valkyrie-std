namespace std.io;

micro print(message: utf8): unit {
    std.console.write_line(message)
}

micro print_line(message: utf8): unit {
    std.console.write_line(message)
}

micro error(message: utf8): unit {
    std.console.error_line(message)
}

micro trace(message: utf8): unit {
    std.console.error_line(message)
}

micro debug(message: utf8): unit {
    <% match arch %>
        <% case "wasm32" %>
    std.adaptor.wasm.console.console_debug(message)
        <% else %>
    print_line(message)
    <% end match %>
}

micro print_fmt(fmt: utf8, arg: utf8): unit {
    let formatted: utf8 = format(fmt, arg)
    print(formatted)
}
