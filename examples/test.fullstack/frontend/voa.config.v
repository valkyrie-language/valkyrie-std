{
    project_type: "application",
    target: "wasm32-unknown-browser-wasm",
    server: {
        host: "localhost",
        port: 3002
    },
    build: {
        mode: "prod",
        output: "dist",
        sourcemap: true
    },
    hot_reload: {
        enabled: true
    }
}