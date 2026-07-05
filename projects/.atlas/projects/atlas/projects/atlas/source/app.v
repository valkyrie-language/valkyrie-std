# AtlasApp — 框架主入口（对标 C# AtlasApp）

namespace atlas;

using std.text;
using atlas.core;
using atlas.wire;
using atlas.systems;

micro create_default(args: [utf8]): AtlasHost {
    let mut host: AtlasHost = AtlasHost::new()
    let port: i32 = parse_port_from_args(args)
    host = host.use_port(port)
    host = host.use_middleware(AtlasMiddleware::new("request-log", 10))
    host = host.use_middleware(AtlasMiddleware::new("exception", 20))
    host = host.use_middleware(AtlasMiddleware::new("response-log", 30))
    host = host.use_container(register_default_wire_container())
    host = atlas_register_routes(host)
    return host
}

micro builder(): AtlasHost {
    let mut host: AtlasHost = AtlasHost::new()
    host = host.use_container(register_default_wire_container())
    return host
}

micro register_default_wire_container(): AtlasWireContainer {
    let mut container: AtlasWireContainer = AtlasWireContainer::new()
    container = container.use_logger(ConsoleAtlasSystemLogger::new("atlas"))
    container = container.use_cache(MemoryAtlasCache::new())
    container = container.use_queue(MemoryAtlasQueue::new())
    container = container.use_event_bus(InMemoryAtlasEventBus::new())
    return container
}

micro parse_port_from_args(args: [utf8]): i32 {
    let mut i: i32 = 0
    while i + 1 < args.length {
        if args[i].equals("--port") {
            return parse_i32_or(args[i + 1], 8080)
        }
        i = i + 1
    }
    return 8080
}

micro parse_i32_or(text: utf8, default_value: i32): i32 {
    if text.is_empty() {
        return default_value
    }

    let mut value: i32 = 0
    let mut i: i32 = 0
    let len: i32 = text.length()
    while i < len {
        let ch: utf8 = text.slice(i, 1)
        let digit: i32 = digit_value(ch)
        if digit > 9 {
            return default_value
        }
        value = value * 10 + digit
        i = i + 1
    }
    if value <= 0 {
        return default_value
    }
    return value
}

micro digit_value(ch: utf8): i32 {
    if ch.equals("0") {
        return 0
    }
    if ch.equals("1") {
        return 1
    }
    if ch.equals("2") {
        return 2
    }
    if ch.equals("3") {
        return 3
    }
    if ch.equals("4") {
        return 4
    }
    if ch.equals("5") {
        return 5
    }
    if ch.equals("6") {
        return 6
    }
    if ch.equals("7") {
        return 7
    }
    if ch.equals("8") {
        return 8
    }
    if ch.equals("9") {
        return 9
    }
    return -1
}
