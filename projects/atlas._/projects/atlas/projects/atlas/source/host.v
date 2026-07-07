# AtlasHost — 应用宿主构建器（对标 C# AtlasHost）

namespace atlas.core;

using std.text;
using atlas.http;
using atlas.wire;
using atlas.systems;
using atlas.ws;

class AtlasHost {
    host: utf8
    port: i32
    router: AtlasRouter
    pipeline: MiddlewarePipeline
    handlers: AtlasHandlerRegistry
    container: AtlasWireContainer
    built: bool
    ws_routes: AtlasWebSocketRouteTable
    ws_manager: AtlasWebSocketManager
    last_hijacked: bool
    last_connection_id: utf8
    last_ws_handler_id: utf8
    io: AtlasTransport
}

imply AtlasHost {
    micro new(): Self {
        return Self {
            host: "127.0.0.1",
            port: 8080,
            router: AtlasRouter::new(),
            pipeline: MiddlewarePipeline::new(),
            handlers: AtlasHandlerRegistry::new(),
            container: AtlasWireContainer::new(),
            built: false,
            ws_routes: AtlasWebSocketRouteTable::new(),
            ws_manager: AtlasWebSocketManager::new(),
            last_hijacked: false,
            last_connection_id: "",
            last_ws_handler_id: "",
            io: AtlasTransport::idle()
        }
    }

    micro use_port(mut self, port: i32): Self {
        self.port = port
        return self
    }

    micro use_host(mut self, host: utf8): Self {
        self.host = host
        return self
    }

    micro use_middleware(mut self, middleware: AtlasMiddleware): Self {
        self.pipeline.add(middleware)
        return self
    }

    micro use_container(mut self, container: AtlasWireContainer): Self {
        self.container = container
        return self
    }

    micro use_io(mut self, io: AtlasTransport): Self {
        self.io = io
        return self
    }

    micro use_websocket(mut self, routes: AtlasWebSocketRouteTable): Self {
        self.ws_routes = routes
        self.pipeline.add(AtlasMiddleware::new("websocket", 50))
        return self
    }

    micro map(mut self, method: utf8, path: utf8, handler_id: utf8): Self {
        self.router.map(method, path, handler_id)
        self.handlers.register(handler_id)
        return self
    }

    micro get_route(mut self, path: utf8, handler_id: utf8): Self {
        self.router.get(path, handler_id)
        self.handlers.register(handler_id)
        return self
    }

    micro post(mut self, path: utf8, handler_id: utf8): Self {
        self.router.post(path, handler_id)
        self.handlers.register(handler_id)
        return self
    }

    micro build(mut self): Self {
        self.built = true
        return self
    }

    micro dispatch(self, request: AtlasRequest): AtlasRouteMatch {
        return self.router.match_route(request.method, request.path)
    }

    micro handle(self, request: AtlasRequest, result: AtlasResult): AtlasResponse {
        let mut context: AtlasRouteContext = AtlasRouteContext::from_request(request)
        result.apply_to(context)
        return context.response
    }

    micro process(mut self, request: AtlasRequest): AtlasResponse {
        let mut ctx: AtlasRouteContext = AtlasRouteContext::from_request(request)
        self.pipeline.execute(ctx, self)
        self.last_hijacked = ctx.is_hijacked
        self.last_connection_id = ctx.connection_id
        self.last_ws_handler_id = ctx.ws_handler_id
        return ctx.response
    }

    micro serve_once(mut self, raw: utf8): AtlasResponse {
        let request: AtlasRequest = parse_http_request(raw)
        return self.process(request)
    }

    micro run(mut self): unit {
        let listener: i32 = self.io.listen_plain(self.host, self.port)
        if listener < 0 {
            return
        }
        while self.io.active && self.io.stopping == false {
            let fd: i32 = self.io.accept(listener)
            if fd < 0 {
                break
            }
            self.serve_connection(fd)
        }
    }

    micro run_tls(mut self, config: std.network.tls.TlsConfig): unit {
        let listener: i32 = self.io.listen_tls(self.host, self.port, config)
        if listener < 0 {
            return
        }
        while self.io.active && self.io.stopping == false {
            let fd: i32 = self.io.accept(listener)
            if fd < 0 {
                break
            }
            self.serve_connection(fd)
        }
    }

    micro stop(mut self): unit {
        self.io.stop()
    }

    micro serve_connection(mut self, fd: i32): unit {
        let raw: utf8 = self.io.read(fd, 8192)
        if raw.is_empty() {
            self.io.close(fd)
            return
        }
        let response: AtlasResponse = self.serve_once(raw)
        let bytes: utf8 = format_http_response(response)
        self.io.write(fd, bytes)
        if self.last_hijacked {
            self.run_ws_loop(fd, self.last_connection_id, self.last_ws_handler_id)
        } else {
            self.io.close(fd)
        }
    }

    micro run_ws_loop(mut self, fd: i32, connection_id: utf8, handler_id: utf8): unit {
        let mut open: bool = true
        while open {
            let chunk: utf8 = self.io.read(fd, 8192)
            if chunk.is_empty() {
                open = false
            } else {
                open = self.feed_ws_bytes(connection_id, handler_id, utf8_to_bytes(chunk))
                let conn: AtlasWebSocketConnection = self.ws_manager.get(connection_id)
                let mut i: i32 = 0
                while i < conn.outbound_texts.length {
                    let frame: [i32] = WebSocketEnframer::text().enframe_text(conn.outbound_texts[i])
                    self.io.write(fd, bytes_to_utf8(frame))
                    i = i + 1
                }
            }
        }
        let mut ws_ctx: AtlasWebSocketContext = AtlasWebSocketContext::new(connection_id, "", handler_id)
        invoke_ws_handler(handler_id, "disconnected", ws_ctx, "")
        self.ws_manager.close_connection(connection_id)
        self.io.close(fd)
    }

    micro feed_ws_text(mut self, connection_id: utf8, message: utf8): unit {
        let conn: AtlasWebSocketConnection = self.ws_manager.get(connection_id)
        if conn.connection_id.is_empty() {
            return
        }
        let mut ws_ctx: AtlasWebSocketContext = AtlasWebSocketContext::new(connection_id, conn.path, conn.handler_id)
        invoke_ws_handler(conn.handler_id, "text", ws_ctx, message)
        let mut i: i32 = 0
        while i < ws_ctx.outbound_texts.length {
            self.ws_manager.append_outbound(connection_id, ws_ctx.outbound_texts[i])
            i = i + 1
        }
        if ws_ctx.is_open == false {
            self.ws_manager.close_connection(connection_id)
        }
    }

    micro feed_ws_bytes(mut self, connection_id: utf8, handler_id: utf8, data: [i32]): bool {
        let mut deframer: WebSocketDeframer = WebSocketDeframer::server()
        deframer.feed(data)
        let mut open: bool = true
        while deframer.try_get_next_frame() {
            if deframer.current_opcode == opcode_text() {
                let message: utf8 = deframer.current_text()
                self.feed_ws_text(connection_id, message)
            } else if deframer.current_opcode == opcode_close() {
                open = false
            } else if deframer.current_opcode == opcode_ping() {
                let conn: AtlasWebSocketConnection = self.ws_manager.get(connection_id)
                let _handler: utf8 = handler_id
                let _path: utf8 = conn.path
            }
        }
        let conn: AtlasWebSocketConnection = self.ws_manager.get(connection_id)
        if conn.is_open == false {
            open = false
        }
        return open
    }

    micro run_terminal(mut self, mut ctx: AtlasRouteContext): unit {
        let matched: AtlasRouteMatch = self.dispatch(ctx.request)
        if matched.found == false {
            let result: AtlasResult = AtlasResult::not_found()
            result.apply_to(ctx)
            return
        }
        let result: AtlasResult = self.handlers.invoke(matched.handler_id, ctx, self.container)
        result.apply_to(ctx)
    }

    micro not_found_response(self): AtlasResponse {
        let result: AtlasResult = AtlasResult::not_found()
        return AtlasResponse::with_body(result.status_code, result.body, result.content_type)
    }

    micro create_system(self, system_name: utf8): AtlasSystem {
        let mut sys: AtlasSystem = AtlasSystem::new(system_name)
        wire_system(sys, self.container)
        return sys
    }
}
