namespace std.adaptor.clr.console;

# 控制台 API

[clr("System.Console", "Write")]
micro console_write(value: utf8): unit

[clr("System.Console", "WriteLine")]
micro console_write_line(value: utf8): unit

[clr("System.Console", "ReadLine")]
micro console_read_line(): utf8

[clr("System.Console", "ReadKey")]
micro console_read_key(): i32

[clr("System.Console", "Clear")]
micro console_clear(): unit

[clr("System.Console", "set_ForegroundColor")]
micro console_set_fg(color: i32): unit

[clr("System.Console", "set_BackgroundColor")]
micro console_set_bg(color: i32): unit

[clr("System.Console", "ResetColor")]
micro console_reset_color(): unit
