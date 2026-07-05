# WebSocket 升级中间件

namespace atlas.core;

using std.text;
using atlas.http;
using atlas.ws;

micro websocket_middleware_step(
    middleware: AtlasMiddleware,
    mut ctx: AtlasRouteContext,
    next_index: i32,
    mut pipeline: MiddlewarePipeline,
    mut host: AtlasHost
): unit {
    let _mw: AtlasMiddleware = middleware
    if is_websocket_upgrade(ctx.request) == false {
        pipeline.execute_at(next_index, ctx, host)
        return
    }

    let handler_id: utf8 = host.ws_routes.match_path(ctx.request.path)
    if handler_id.is_empty() {
        ctx.response = AtlasResponse::with_body(404, "ws-route-not-found", "text/plain")
        ctx.short_circuit = true
        return
    }

    let connection_id: utf8 = host.ws_manager.allocate_id()
    host.ws_manager.register(connection_id, ctx.request.path, handler_id)

    let key: utf8 = ctx.request.get_header("Sec-WebSocket-Key")
    let accept: utf8 = compute_accept_key(key)

    let mut response: AtlasResponse = AtlasResponse::empty(status_switching_protocols())
    response.set_header("Upgrade", "websocket")
    response.set_header("Connection", "Upgrade")
    response.set_header("Sec-WebSocket-Accept", accept)
    ctx.response = response

    ctx.is_hijacked = true
    ctx.connection_id = connection_id
    ctx.ws_handler_id = handler_id
    ctx.request.is_hijacked = true
    ctx.request.connection_id = connection_id
    ctx.short_circuit = true

    let mut ws_ctx: AtlasWebSocketContext = AtlasWebSocketContext::new(connection_id, ctx.request.path, handler_id)
    invoke_ws_handler(handler_id, "connected", ws_ctx, "")
    flush_ws_outbound(host, connection_id, ws_ctx)
}

micro flush_ws_outbound(mut host: AtlasHost, connection_id: utf8, ctx: AtlasWebSocketContext): unit {
    let mut i: i32 = 0
    while i < ctx.outbound_texts.length {
        host.ws_manager.append_outbound(connection_id, ctx.outbound_texts[i])
        i = i + 1
    }
    if ctx.is_open == false {
        host.ws_manager.close_connection(connection_id)
    }
}
