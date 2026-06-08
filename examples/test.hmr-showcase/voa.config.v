{
    project_type: "application",
    target: "wasm32-unknown-browser-wasm",
    name: "voa-hmr-showcase",
    version: "0.1.0",
    render: {
        defaultMode: "csr"
    },
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false
    },
    devtools: {
        enabled: true,
        panels: ["components", "routes", "cache", "performance"],
        keyboard_shortcuts: true,
        error_overlay: true,
        hmr_indicator: true
    }
}