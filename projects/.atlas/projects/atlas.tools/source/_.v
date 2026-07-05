namespace atlas.tools;

using std.text;
using std.io;
using std.command;
using atlas;
using atlas.core;
using atlas.config;

micro main(args: [utf8]): i32 {
    let mut app: CommandApp = command_app_new("atlas", "Atlas backend framework CLI")
    app = command_app_register(app, CommandModel { name: "dev", description: "Build and run AtlasHost from atlas.config.von" })
    app = command_app_register(app, CommandModel { name: "serve", description: "Start AtlasHost listener" })
    app = command_app_register(app, CommandModel { name: "status", description: "Print compile-time atlas.manifest.json" })
    app = command_app_register(app, CommandModel { name: "health", description: "Probe /health/live and /health/ready" })
    app = command_app_register(app, CommandModel { name: "config", description: "Config commands (validate)" })

    let parsed: ParsedCommand = command_app_run(app, args)
    if parsed.command_name.equals("dev") {
        return cmd_dev(parsed.positional)
    }
    if parsed.command_name.equals("serve") {
        return cmd_serve(parsed.positional)
    }
    if parsed.command_name.equals("status") {
        return cmd_status(parsed.positional)
    }
    if parsed.command_name.equals("health") {
        return cmd_health(parsed.positional)
    }
    if parsed.command_name.equals("config") {
        return cmd_config(parsed.positional)
    }
    print_usage()
    return 1
}

micro print_usage(): unit {
    std.io.print_line("atlas dev|serve|status|health|config validate")
}

micro cmd_dev(args: [utf8]): i32 {
    let config_path: utf8 = resolve_config_path(args)
    let source: utf8 = read_config_or_default(config_path)
    if validate_config_source(source) == false {
        std.io.print_line("config invalid")
        return 1
    }
    let config: AtlasRuntimeConfig = load_runtime_config(source)
    let mut host: AtlasHost = create_default([])
    host = host.use_host(config.listen.host)
    host = host.use_port(config.listen.port)
    host = host.build()
    if config.tls.enabled {
        host.run_tls(config.tls_config())
    } else {
        host.run()
    }
    return 0
}

micro cmd_serve(args: [utf8]): i32 {
    return cmd_dev(args)
}

micro cmd_status(args: [utf8]): i32 {
    let path: utf8 = resolve_manifest_path(args)
    let text: utf8 = std.io.read_file_text(path)
    if text.is_empty() {
        std.io.print_line("manifest not found")
        return 1
    }
    std.io.print_line(text)
    return 0
}

micro cmd_health(args: [utf8]): i32 {
    let port: i32 = resolve_health_port(args)
    let mut host: AtlasHost = create_default([])
    host = host.use_port(port)
    host = host.build()

    let live_raw: utf8 = "GET /health/live HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let live: AtlasResponse = host.serve_once(live_raw)
    if live.status_code != 200 {
        std.io.print_line("live probe failed")
        return 1
    }

    let ready_raw: utf8 = "GET /health/ready HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let ready: AtlasResponse = host.serve_once(ready_raw)
    if ready.status_code != 200 {
        std.io.print_line("ready probe failed")
        return 1
    }
    std.io.print_line("health ok")
    return 0
}

micro cmd_config(args: [utf8]): i32 {
    if args.length < 1 || args[0].equals("validate") == false {
        std.io.print_line("usage: atlas config validate [path]")
        return 1
    }
    let config_path: utf8 = resolve_config_path(args)
    let source: utf8 = read_config_or_default(config_path)
    if validate_config_source(source) {
        std.io.print_line("config valid")
        return 0
    }
    std.io.print_line("config invalid")
    return 1
}

micro resolve_config_path(args: [utf8]): utf8 {
    let mut i: i32 = 0
    while i < args.length {
        if args[i].equals("--config") && i + 1 < args.length {
            return args[i + 1]
        }
        i = i + 1
    }
    if args.length > 0 && args[0].equals("validate") == false && args[0].equals("dev") == false {
        return args[0]
    }
    return "atlas.config.von"
}

micro resolve_manifest_path(args: [utf8]): utf8 {
    let mut i: i32 = 0
    while i < args.length {
        if args[i].equals("--manifest") && i + 1 < args.length {
            return args[i + 1]
        }
        i = i + 1
    }
    return "dist/atlas.manifest.json"
}

micro resolve_health_port(args: [utf8]): i32 {
    let mut i: i32 = 0
    while i + 1 < args.length {
        if args[i].equals("--port") {
            return parse_i32_or(args[i + 1], 8080)
        }
        i = i + 1
    }
    return 8080
}

micro read_config_or_default(path: utf8): utf8 {
    let text: utf8 = std.io.read_file_text(path)
    if text.is_empty() {
        return "listen { host: \"0.0.0.0\" port: 8080 } tls { enabled: false }"
    }
    return text
}

micro parse_i32_or(text: utf8, default_value: i32): i32 {
    if text.is_empty() {
        return default_value
    }
    let mut value: i32 = 0
    let mut i: i32 = 0
    while i < text.length() {
        let ch: utf8 = text.slice(i, 1)
        if ch.equals("0") { value = value * 10 }
        else if ch.equals("1") { value = value * 10 + 1 }
        else if ch.equals("2") { value = value * 10 + 2 }
        else if ch.equals("3") { value = value * 10 + 3 }
        else if ch.equals("4") { value = value * 10 + 4 }
        else if ch.equals("5") { value = value * 10 + 5 }
        else if ch.equals("6") { value = value * 10 + 6 }
        else if ch.equals("7") { value = value * 10 + 7 }
        else if ch.equals("8") { value = value * 10 + 8 }
        else if ch.equals("9") { value = value * 10 + 9 }
        else { return default_value }
        i = i + 1
    }
    if value <= 0 {
        return default_value
    }
    return value
}
