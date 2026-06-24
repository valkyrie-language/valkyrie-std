namespace std.terminal;

[host_contract]
micro clear(): unit

[host_contract]
micro set_foreground(color: i32): unit

[host_contract]
micro set_background(color: i32): unit

[host_contract]
micro reset_color(): unit
