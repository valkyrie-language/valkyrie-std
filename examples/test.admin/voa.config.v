{
    project_type: "application",
    target: "wasm32-unknown-browser-wasm",
    name: "voa-admin",
    version: "0.1.0",
    render: {
        defaultMode: "csr",
        routes: [
            { path: "/login", mode: "csr" },
            { path: "/dashboard", mode: "csr" },
            { path: "/users", mode: "csr" },
            { path: "/users/:id", mode: "csr" },
            { path: "/settings", mode: "csr" }
        ]
    },
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false
    },
    api: {
        directory: "source/api",
        cors: { origin: "*" },
        middleware: {
            logger: true,
            security_headers: true,
            auth: { scheme: "jwt", secret: "dev-secret-key" }
        }
    }
}