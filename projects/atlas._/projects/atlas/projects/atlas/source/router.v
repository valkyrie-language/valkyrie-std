# Atlas 路由 — 显式注册与路径匹配（纯 V，无反射扫描）

namespace atlas.core;

using std.text;
using atlas.http;

class AtlasRoute {
    method: utf8
    path: utf8
    handler_id: utf8
}

class AtlasRouteMatch {
    found: bool
    handler_id: utf8
    params: [AtlasHeaderPair]
}

class AtlasRouter {
    routes: [AtlasRoute]
}

imply AtlasRouter {
    micro new(): Self {
        return Self { routes: [] }
    }

    micro map(mut self, method: utf8, path: utf8, handler_id: utf8): unit {
        push(self.routes, AtlasRoute {
            method: method,
            path: path,
            handler_id: handler_id
        })
    }

    micro get(mut self, path: utf8, handler_id: utf8): unit {
        self.map("GET", path, handler_id)
    }

    micro post(mut self, path: utf8, handler_id: utf8): unit {
        self.map("POST", path, handler_id)
    }

    micro put_route(mut self, path: utf8, handler_id: utf8): unit {
        self.map("PUT", path, handler_id)
    }

    micro delete_route(mut self, path: utf8, handler_id: utf8): unit {
        self.map("DELETE", path, handler_id)
    }

    micro match_route(self, method: utf8, path: utf8): AtlasRouteMatch {
        let mut i: i32 = 0
        while i < self.routes.length {
            let route: AtlasRoute = self.routes[i]
            if route.method.equals(method) {
                if try_match_path(route.path, path) {
                    return AtlasRouteMatch {
                        found: true,
                        handler_id: route.handler_id,
                        params: extract_params(route.path, path)
                    }
                }
            }
            i = i + 1
        }

        return AtlasRouteMatch {
            found: false,
            handler_id: "",
            params: []
        }
    }
}

micro try_match_path(pattern: utf8, actual: utf8): bool {
    let pattern_parts: [utf8] = split_path_segments(pattern)
    let actual_parts: [utf8] = split_path_segments(actual)

    if pattern_parts.length != actual_parts.length {
        return false
    }

    let mut i: i32 = 0
    while i < pattern_parts.length {
        let pat: utf8 = pattern_parts[i]
        let act: utf8 = actual_parts[i]
        if !pat.starts_with(":") {
            if !pat.equals(act) {
                return false
            }
        }
        i = i + 1
    }
    return true
}

micro extract_params(pattern: utf8, actual: utf8): [AtlasHeaderPair] {
    let pattern_parts: [utf8] = split_path_segments(pattern)
    let actual_parts: [utf8] = split_path_segments(actual)
    let mut params: [AtlasHeaderPair] = []
    let mut i: i32 = 0
    while i < pattern_parts.length {
        let pat: utf8 = pattern_parts[i]
        if pat.starts_with(":") {
            let name: utf8 = pat.slice(1, pat.length() - 1)
            push(params, AtlasHeaderPair { key: name, value: actual_parts[i] })
        }
        i = i + 1
    }
    return params
}

micro split_path_segments(path: utf8): [utf8] {
    if path.equals("/") {
        return []
    }
    if path.is_empty() {
        return []
    }

    let trimmed: utf8 = trim_path_slashes(path)
    let raw: [utf8] = trimmed.split("/")
    let mut result: [utf8] = []
    let mut i: i32 = 0
    while i < raw.length {
        if !raw[i].is_empty() {
            push(result, raw[i])
        }
        i = i + 1
    }
    return result
}

micro trim_path_slashes(path: utf8): utf8 {
    let mut start: i32 = 0
    let mut end: i32 = path.length()
    if end > 0 {
        if path.starts_with("/") {
            start = 1
        }
    }
    if end > start {
        if path.ends_with("/") {
            end = end - 1
        }
    }
    if end <= start {
        return ""
    }
    return path.slice(start, end - start)
}
