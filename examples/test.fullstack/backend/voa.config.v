{
    project_type: "backend",
    target: "clr-microsoft-unknown-managed",
    server: {
        host: "localhost",
        port: 8080,
        workers: 4
    },
    build: {
        mode: "prod",
        output: "dist",
        minify: false,
        sourcemap: true
    }
}