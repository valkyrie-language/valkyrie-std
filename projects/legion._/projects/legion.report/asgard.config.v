define_config(asgard) {
    project_type = "library",
        target = "wasm32-unknown-browser-wasm",
        platform = "browser",
        name = "legion.report",
        version = "workspace",
        render {
            defaultMode = "ssg",
            routes = [
                { path = "/test-report", mode = "ssg" },
                { path = "/coverage-report", mode = "ssg" },
                { path = "/bench-report", mode = "ssg" }
            ]
        },
        build {
            mode = "report",
            output = "dist",
            minify = false,
            sourcemap = false,
            chunk {
                js_mode = "split",
                css_mode = "merge"
            }
        }
}
