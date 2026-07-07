define_config(asgard) {
    name = "demo.ios",
        platform = "ios",
        target = "aarch64-apple-ios-aapcs64",
        build {
            output = "dist",
            mode = "dev"
        }
}
