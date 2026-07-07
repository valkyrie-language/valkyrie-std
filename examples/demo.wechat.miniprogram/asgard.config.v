define_config(asgard) {
    name = "demo.wechat.miniprogram",
        platform = "wechat-miniprogram",
        target = "wasm32-unknown-miniprogram-wasm",
        build {
            output = "dist",
            mode = "dev"
        }
}
