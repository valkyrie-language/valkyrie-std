namespace legion.tools.smoke;

[clr("mscorlib", "System.Console", "WriteLine")]
micro console_write_line(message: utf16): unit;

micro version_text() -> utf8 {
    return "Legion smoke v0.1.0"
}

[main]
micro main(): i64 {
    console_write_line("legion.tools smoke")
    return 0
}
