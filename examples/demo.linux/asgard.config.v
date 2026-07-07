define_config(asgard) {
    name = "demo.linux",
        platform = "linux",
        target = "x86_64-unknown-linux-gnu",
        build {
            output = "dist",
            mode = "dev"
        }
}
