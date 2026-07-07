define_config(asgard) {
    project_type = "application",
        target = "wasm32-unknown-browser-wasm",
        build {
            mode = "dev",
            output = "dist",
            minify = false,
            sourcemap = true,
            format = "esm",
            chunk {
                wasm_threshold = 51200,
                js_mode = "per-component",
                css_mode = "merged"
            }
        }
}
