# WebSocket upgrade and handler tests

using atlas;
using atlas.core;
using atlas.http;
using atlas.ws;

[test]
micro `websocket upgrade returns 101 and hijacks`() {
    let mut routes: AtlasWebSocketRouteTable = AtlasWebSocketRouteTable::new()
    routes = routes.map("/ws/echo", "echo")
    let mut host: AtlasHost = create_default([])
    host = host.use_websocket(routes)
    host = host.build()

    let mut request: AtlasRequest = AtlasRequest::new("GET", "/ws/echo")
    request.set_header("Upgrade", "websocket")
    request.set_header("Sec-WebSocket-Key", "demo-key")

    let response: AtlasResponse = host.process(request)
    if response.status_code != 101 {
        panic("expect switching protocols")
    }
    if host.last_hijacked == false {
        panic("expect hijacked")
    }
    if host.last_connection_id.is_empty() {
        panic("connection id")
    }
    let conn: AtlasWebSocketConnection = host.ws_manager.get(host.last_connection_id)
    if conn.outbound_texts.length < 1 {
        panic("welcome on connect")
    }
    if conn.outbound_texts[0].equals("welcome") == false {
        panic("welcome text")
    }
}

[test]
micro `websocket feed text echoes`() {
    let mut routes: AtlasWebSocketRouteTable = AtlasWebSocketRouteTable::new()
    routes = routes.map("/ws/echo", "echo")
    let mut host: AtlasHost = create_default([])
    host = host.use_websocket(routes)
    host = host.build()

    let mut request: AtlasRequest = AtlasRequest::new("GET", "/ws/echo")
    request.set_header("Upgrade", "websocket")
    request.set_header("Sec-WebSocket-Key", "k")
    let _response: AtlasResponse = host.process(request)
    let id: utf8 = host.last_connection_id
    host.feed_ws_text(id, "ping")
    let conn: AtlasWebSocketConnection = host.ws_manager.get(id)
    if conn.outbound_texts.length < 2 {
        panic("echo should append")
    }
    if conn.outbound_texts[1].equals("ping") == false {
        panic("echo payload")
    }
}

[test]
micro `unknown websocket route is 404`() {
    let mut routes: AtlasWebSocketRouteTable = AtlasWebSocketRouteTable::new()
    routes = routes.map("/ws/echo", "echo")
    let mut host: AtlasHost = AtlasHost::new()
    host = host.use_websocket(routes)

    let mut request: AtlasRequest = AtlasRequest::new("GET", "/ws/missing")
    request.set_header("Upgrade", "websocket")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 404 {
        panic("missing ws route")
    }
}
