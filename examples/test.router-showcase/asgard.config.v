define_config(asgard) {
    project_type = "application",
        target = "wasm32-unknown-browser-wasm",
        name = "voa-router-showcase",
        version = "0.1.0",
        render {
            defaultMode = "csr"
        },
        build {
            mode = "prod",
            output = "dist",
            minify = true,
            sourcemap = false
        }
}
