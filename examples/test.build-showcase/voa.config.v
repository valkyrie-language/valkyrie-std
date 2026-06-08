{
    project_type: "application",
    target: "wasm32-unknown-browser-wasm",
    name: "voa-build-showcase",
    version: "0.1.0",
    render: {
        defaultMode: "csr"
    },
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false,
        code_splitting: {
            strategy: "balanced",
            route_based: true,
            component_based: true,
            min_chunk_size: 10240,
            max_chunk_size: 244800
        },
        image: {
            formats: ["webp", "avif", "original"],
            quality: 75,
            lazy: true,
            placeholder: "blur"
        },
        font: {
            display: "swap",
            preload: true,
            inline_critical: true,
            adjust_font_metrics: true
        }
    }
}