namespace std.terminal;

[host_contract]
micro clear(): unit

[host_contract]
micro set_foreground(color: i32): unit

[host_contract]
micro set_background(color: i32): unit

[host_contract]
micro reset_color(): unit

[host_contract]
micro move_to(row: i32, col: i32): unit

[host_contract]
micro size_rows(): i32

[host_contract]
micro size_cols(): i32

[host_contract]
micro poll_key(): i32

[host_contract]
micro enter_alt_screen(): unit

[host_contract]
micro exit_alt_screen(): unit

[host_contract]
micro flush(): unit

[host_contract]
micro put_char(ch: i32): unit

[host_contract]
micro put_str(text: utf8): unit

[host_contract]
micro set_reverse(on: i32): unit

[host_contract]
micro sleep_ms(ms: i32): unit

