{
    project_type: "application",
    target: "wasm32-unknown-browser-wasm",
    name: "voa-blog",
    version: "0.1.0",
    render: {
        defaultMode: "ssg",
        routes: [
            { path: "/", mode: "ssg" },
            { path: "/posts", mode: "ssg" },
            { path: "/posts/:slug", mode: "ssg" },
            { path: "/about", mode: "ssg" },
            { path: "/api/comments", mode: "ssr" }
        ]
    },
    ssg: {
        generate_paths: ["getStaticPaths"]
    },
    build: {
        mode: "prod",
        output: "dist",
        minify: true,
        sourcemap: false
    }
}