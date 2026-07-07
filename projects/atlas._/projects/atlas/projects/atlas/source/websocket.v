# WebSocket 路由 / 连接 / Handler（进程内可测）

namespace atlas.ws;

using std.text;
using atlas.http;

class AtlasWebSocketContext {
    connection_id: utf8
    path: utf8
    handler_id: utf8
    is_open: bool
    outbound_texts: [utf8]
}

class AtlasWebSocketRouteEntry {
    path: utf8
    handler_id: utf8
}

class AtlasWebSocketRouteTable {
    routes: [AtlasWebSocketRouteEntry]
}

class AtlasWebSocketConnection {
    connection_id: utf8
    path: utf8
    handler_id: utf8
    is_open: bool
    outbound_texts: [utf8]
}

class AtlasWebSocketManager {
    connections: [AtlasWebSocketConnection]
    next_id: i32
}

class AtlasWebSocketEvent {
    kind: utf8
    message: utf8
}

imply AtlasWebSocketContext {
    micro new(connection_id: utf8, path: utf8, handler_id: utf8): Self {
        return Self {
            connection_id: connection_id,
            path: path,
            handler_id: handler_id,
            is_open: true,
            outbound_texts: []
        }
    }

    micro send_text(mut self, message: utf8): unit {
        if self.is_open == false {
            return
        }
        push(self.outbound_texts, message)
    }

    micro close(mut self): unit {
        self.is_open = false
    }
}

imply AtlasWebSocketRouteTable {
    micro new(): Self {
        return Self { routes: [] }
    }

    micro map(mut self, path: utf8, handler_id: utf8): Self {
        push(self.routes, AtlasWebSocketRouteEntry { path: path, handler_id: handler_id })
        return self
    }

    micro match_path(self, path: utf8): utf8 {
        let mut i: i32 = 0
        while i < self.routes.length {
            if self.routes[i].path.equals(path) {
                return self.routes[i].handler_id
            }
            i = i + 1
        }
        return ""
    }

    micro has(self, path: utf8): bool {
        return self.match_path(path).is_empty() == false
    }
}

imply AtlasWebSocketManager {
    micro new(): Self {
        return Self { connections: [], next_id: 1 }
    }

    micro allocate_id(mut self): utf8 {
        let id: i32 = self.next_id
        self.next_id = self.next_id + 1
        return "ws-".concat(i32_to_utf8(id))
    }

    micro register(mut self, connection_id: utf8, path: utf8, handler_id: utf8): AtlasWebSocketConnection {
        let conn: AtlasWebSocketConnection = AtlasWebSocketConnection {
            connection_id: connection_id,
            path: path,
            handler_id: handler_id,
            is_open: true,
            outbound_texts: []
        }
        push(self.connections, conn)
        return conn
    }

    micro find(mut self, connection_id: utf8): i32 {
        let mut i: i32 = 0
        while i < self.connections.length {
            if self.connections[i].connection_id.equals(connection_id) {
                return i
            }
            i = i + 1
        }
        return -1
    }

    micro get(self, connection_id: utf8): AtlasWebSocketConnection {
        let mut i: i32 = 0
        while i < self.connections.length {
            if self.connections[i].connection_id.equals(connection_id) {
                return self.connections[i]
            }
            i = i + 1
        }
        return AtlasWebSocketConnection {
            connection_id: "",
            path: "",
            handler_id: "",
            is_open: false,
            outbound_texts: []
        }
    }

    micro append_outbound(mut self, connection_id: utf8, message: utf8): unit {
        let index: i32 = self.find(connection_id)
        if index < 0 {
            return
        }
        push(self.connections[index].outbound_texts, message)
    }

    micro close_connection(mut self, connection_id: utf8): unit {
        let index: i32 = self.find(connection_id)
        if index < 0 {
            return
        }
        self.connections[index].is_open = false
    }

    micro broadcast_text(mut self, message: utf8): unit {
        let mut i: i32 = 0
        while i < self.connections.length {
            if self.connections[i].is_open {
                push(self.connections[i].outbound_texts, message)
            }
            i = i + 1
        }
    }
}

micro i32_to_utf8(value: i32): utf8 {
    if value <= 0 {
        return "0"
    }
    let mut n: i32 = value
    let mut digits: [utf8] = []
    while n > 0 {
        let d: i32 = n % 10
        push(digits, digit_char(d))
        n = n / 10
    }
    let mut out: utf8 = ""
    let mut i: i32 = digits.length - 1
    while i >= 0 {
        out = out.concat(digits[i])
        i = i - 1
    }
    return out
}

micro digit_char(d: i32): utf8 {
    if d == 0 { return "0" }
    if d == 1 { return "1" }
    if d == 2 { return "2" }
    if d == 3 { return "3" }
    if d == 4 { return "4" }
    if d == 5 { return "5" }
    if d == 6 { return "6" }
    if d == 7 { return "7" }
    if d == 8 { return "8" }
    return "9"
}

micro invoke_ws_handler(handler_id: utf8, event: utf8, mut ctx: AtlasWebSocketContext, message: utf8): unit {
    atlas_invoke_ws_handler(handler_id, event, ctx, message)
}

micro invoke_echo_handler(event: utf8, mut ctx: AtlasWebSocketContext, message: utf8): unit {
    if event.equals("connected") {
        ctx.send_text("welcome")
        return
    }
    if event.equals("text") {
        ctx.send_text(message)
        return
    }
    if event.equals("disconnected") {
        ctx.close()
    }
}

micro invoke_chat_handler(event: utf8, mut ctx: AtlasWebSocketContext, message: utf8): unit {
    if event.equals("connected") {
        ctx.send_text("chat-ready")
        return
    }
    if event.equals("text") {
        ctx.send_text("chat:".concat(message))
        return
    }
    if event.equals("disconnected") {
        ctx.close()
    }
}

micro is_websocket_upgrade(request: AtlasRequest): bool {
    if request.method.equals("GET") == false {
        return false
    }
    let upgrade: utf8 = request.get_header("Upgrade")
    if upgrade.equals("websocket") {
        return true
    }
    if upgrade.equals("WebSocket") {
        return true
    }
    return false
}

micro compute_accept_key(sec_key: utf8): utf8 {
    return "atlas-ws-".concat(sec_key)
}

micro status_switching_protocols(): i32 { return 101 }
