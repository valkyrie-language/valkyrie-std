namespace std.io;

micro print(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
        std.console.write(message)
        <% case "jvm" %>
        std.adaptor.jvm.console.jvm_print(message)
        <% case "wasm32" %>
        std.adaptor.wasm.console.console_log(message)
        <% case "nyar" %>
        std.adaptor.nyar.builtin.print_utf8(message)
        <% else %>
        return
    <% end match %>
}

micro print_line(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
        std.console.write_line(message)
        <% case "jvm" %>
        std.adaptor.jvm.console.jvm_println(message)
        <% case "wasm32" %>
        std.adaptor.wasm.console.console_log(message)
        <% case "nyar" %>
        std.adaptor.nyar.builtin.println_utf8(message)
        <% else %>
        return
    <% end match %>
}

micro error(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
        std.console.write(message)
        <% case "jvm" %>
        std.adaptor.jvm.console.jvm_err_println(message)
        <% case "wasm32" %>
        std.adaptor.wasm.console.console_error(message)
        <% case "nyar" %>
        std.adaptor.nyar.builtin.println_utf8(message)
        <% else %>
        return
    <% end match %>
}

micro trace(message: utf8): unit {
    <% match arch %>
        <% case "clr" %>
        std.console.write_line(message)
        <% case "jvm" %>
        std.adaptor.jvm.console.jvm_err_println(message)
        <% case "wasm32" %>
        std.adaptor.wasm.console.console_error(message)
        <% else %>
        return
    <% end match %>
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