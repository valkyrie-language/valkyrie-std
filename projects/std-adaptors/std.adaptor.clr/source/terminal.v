namespace std.adaptor.clr.terminal;

[host_provider(std::terminal::clear)]
micro clear(): unit {
    __terminal_clr_clear()
}

[host_provider(std::terminal::set_foreground)]
micro set_foreground(color: i32): unit {
    __terminal_clr_set_foreground(color)
}

[host_provider(std::terminal::set_background)]
micro set_background(color: i32): unit {
    __terminal_clr_set_background(color)
}

[host_provider(std::terminal::reset_color)]
micro reset_color(): unit {
    __terminal_clr_reset_color()
}

[clr("System.Console", "System.Console", "Clear")]
private micro __terminal_clr_clear(): unit

[clr("System.Console", "System.Console", "set_ForegroundColor")]
private micro __terminal_clr_set_foreground(color: i32): unit

[clr("System.Console", "System.Console", "set_BackgroundColor")]
private micro __terminal_clr_set_background(color: i32): unit

[clr("System.Console", "System.Console", "ResetColor")]
private micro __terminal_clr_reset_color(): unit
