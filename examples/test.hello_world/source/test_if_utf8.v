namespace hello_world;

[main]
micro test_utf8_if(args: [utf8]) -> unit {
    let cmd: utf8 = args[0]

    if cmd == "build" {
        print("build command")
        return
    }

    if cmd == "test" {
        print("test command")
        return
    }

    print("unknown command")
}
