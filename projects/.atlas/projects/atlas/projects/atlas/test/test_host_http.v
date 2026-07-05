# HTTP host shell tests

using atlas;
using atlas.core;
using atlas.http;
using atlas.ws;

[test]
micro `parse and serve_once health`() {
    let mut host: AtlasHost = create_default([])
    host = host.get_route("/api/health", "health")
    host = host.build()
    let raw: utf8 = "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let response: AtlasResponse = host.serve_once(raw)
    if response.status_code != 200 {
        panic("serve_once health")
    }
    if response.body.contains("status-ok") == false {
        panic("health body")
    }
}

[test]
micro `format_http_response has status line`() {
    let response: AtlasResponse = AtlasResponse::with_body(200, "ok", "text/plain")
    let raw: utf8 = format_http_response(response)
    if raw.starts_with("HTTP/1.1 200") == false {
        panic("status line")
    }
    if raw.contains("ok") == false {
        panic("body")
    }
}

[test]
micro `run with io backend serves one request`() {
    let mut host: AtlasHost = create_default([])
    host = host.get_route("/api/health", "health")
    host = host.build()
    let raw: utf8 = "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n"
    host = host.use_io(AtlasTransport::with_request(raw))
    host.run()
    if host.io.writes.length < 1 {
        panic("expected write")
    }
    if host.io.writes[0].contains("status-ok") == false {
        panic("written body")
    }
}

[test]
micro `run websocket upgrade keeps hijacked connection`() {
    let mut routes: AtlasWebSocketRouteTable = AtlasWebSocketRouteTable::new()
    routes = routes.map("/ws/echo", "echo")
    let mut host: AtlasHost = create_default([])
    host = host.use_websocket(routes)
    host = host.build()

    let framed: [i32] = WebSocketEnframer::text().enframe_text("hey")
    let upgrade: utf8 = "GET /ws/echo HTTP/1.1\r\nUpgrade: websocket\r\nSec-WebSocket-Key: abc\r\n\r\n"
    let mut io: AtlasTransport = AtlasTransport::idle()
    io.active = true
    push(io.queued_fds, 7)
    push(io.queued_raw, upgrade)
    push(io.queued_raw, bytes_to_utf8(framed))
    host = host.use_io(io)
    host.run()
    if host.last_hijacked == false {
        panic("hijack")
    }
    if host.io.writes.length < 1 {
        panic("101 response written")
    }
    if host.io.writes[0].contains("101") == false {
        panic("101 status")
    }
}
