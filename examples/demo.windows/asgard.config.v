define_config(asgard) {
    name = "demo.windows",
        platform = "windows",
        target = "x86_64-pc-windows-msvc",
        build {
            output = "dist",
            mode = "dev"
        }
}
