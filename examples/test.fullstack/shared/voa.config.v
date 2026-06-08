{
    project_type: "library",
    target: "wasm32-unknown-browser-wasm",
    build: {
        mode: "prod",
        output: "lib",
        minify: true,
        sourcemap: false
    }
}