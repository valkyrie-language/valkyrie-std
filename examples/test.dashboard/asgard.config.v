define_config(asgard) {
    project_type = "application",
        target = "wasm32-unknown-browser-wasm",
        name = "voa-dashboard",
        version = "0.1.0",
        render {
            defaultMode = "csr"
        },
        build {
            mode = "prod",
            output = "dist",
            minify = true,
            sourcemap = false
        },
        websocket {
            url = "ws://localhost:3000/__voa_ws__",
            reconnect = true,
            max_reconnect_attempts = 10
        }
}
