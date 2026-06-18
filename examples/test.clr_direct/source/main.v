namespace test;

[clr("System.Console", "System.Console", "WriteLine")]
micro console_write_line(value: utf8): unit

[main]
micro hello() {
    console_write_line("Hello Direct CLR!")
}
