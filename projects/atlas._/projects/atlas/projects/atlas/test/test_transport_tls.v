# Atlas transport + TLS integration tests

using atlas;
using atlas.core;
using atlas.http;
using std.network.tls;

[test]
micro `AtlasTransport idle listen uses stub queue`() {
    let mut transport: AtlasTransport = AtlasTransport::with_request("GET / HTTP/1.1\r\n\r\n")
    let listener: i32 = transport.listen_plain("127.0.0.1", 8080)
    if listener < 0 {
        panic("listen")
    }
    let fd: i32 = transport.accept(listener)
    if fd < 1 {
        panic("accept")
    }
}

[test]
micro `AtlasHost run_tls uses transport tls listen`() {
    let mut host: AtlasHost = create_default([])
    host = host.build()
    let raw: utf8 = "GET /health/live HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let mut io: AtlasTransport = AtlasTransport::with_request(raw)
    host = host.use_io(io)
    let config: TlsConfig = TlsConfig::server("certs/server.pem", "certs/server.key")
    host.run_tls(config)
    if host.io.writes.length < 1 {
        panic("tls run should write response")
    }
}

[test]
micro `AtlasHost stop rejects new accepts`() {
    let mut transport: AtlasTransport = AtlasTransport::idle()
    transport.active = true
    transport.listener_fd = 1
    transport.stop()
    let fd: i32 = transport.accept(1)
    if fd >= 0 {
        panic("stop should reject accept")
    }
}
