{
    project_type: "library",
    target: "wasm32-unknown-browser-wasm",
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false,
        format: "esm"
    }
}