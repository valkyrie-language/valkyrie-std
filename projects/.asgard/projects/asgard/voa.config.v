{
    project_type: "library",
    target: "wasm32-unknown-browser-wasm",
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false,
        format: "esm",
        chunk: {
            wasm_threshold: 51200,
            js_mode: "per-component",
            css_mode: "merged"
        }
    }
}