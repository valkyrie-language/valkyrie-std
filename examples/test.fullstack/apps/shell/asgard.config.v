define_config(asgard) {
    project_type = "application"
    name = "fullstack-shell"
    platform = "browser"
    target = "wasm32-unknown-browser-wasm"
    render {
        defaultMode = "ssg"
    }
    build {
        mode = "prod"
        output = "dist"
        sourcemap = true
    }
    hot_reload {
        enabled = true
        port = 3002
    }
}
