namespace hello_world;

[main]
micro test_utf8_if(args: [utf8]) -> unit {
    let cmd: utf8 = args[0]

    if cmd == "build" {
        std::console::write_line("build command")
        return
    }

    if cmd == "test" {
        std::console::write_line("test command")
        return
    }

    std::console::write_line("unknown command")
}
