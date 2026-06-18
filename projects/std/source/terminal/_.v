namespace std.terminal;

micro clear(): unit {
    <% match arch %>
        <% case "clr" %>
    __terminal_clr_clear()
        <% else %>
    return
    <% end match %>
}

micro set_foreground(color: i32): unit {
    <% match arch %>
        <% case "clr" %>
    __terminal_clr_set_foreground(color)
        <% else %>
    return
    <% end match %>
}

micro set_background(color: i32): unit {
    <% match arch %>
        <% case "clr" %>
    __terminal_clr_set_background(color)
        <% else %>
    return
    <% end match %>
}

micro reset_color(): unit {
    <% match arch %>
        <% case "clr" %>
    __terminal_clr_reset_color()
        <% else %>
    return
    <% end match %>
}

[clr("System.Console", "System.Console", "Clear")]
private micro __terminal_clr_clear(): unit

[clr("System.Console", "System.Console", "set_ForegroundColor")]
private micro __terminal_clr_set_foreground(color: i32): unit

[clr("System.Console", "System.Console", "set_BackgroundColor")]
private micro __terminal_clr_set_background(color: i32): unit

[clr("System.Console", "System.Console", "ResetColor")]
private micro __terminal_clr_reset_color(): unit
