define_config(asgard) {
    name = "demo.tui",
        platform = "terminal",
        target = "x86_64-pc-windows-msvc",
        build {
            output = "dist",
            mode = "dev"
        }
}
