# Health probe route tests

using atlas;
using atlas.core;
using atlas.http;

[test]
micro `health live returns 200`() {
    let mut host: AtlasHost = create_default([])
    host = host.build()
    let raw: utf8 = "GET /health/live HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let response: AtlasResponse = host.serve_once(raw)
    if response.status_code != 200 {
        panic("live status")
    }
    if response.body.contains("alive") == false {
        panic("live body")
    }
}

[test]
micro `health ready returns 200`() {
    let mut host: AtlasHost = create_default([])
    host = host.build()
    let raw: utf8 = "GET /health/ready HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let response: AtlasResponse = host.serve_once(raw)
    if response.status_code != 200 {
        panic("ready status")
    }
    if response.body.contains("ready") == false {
        panic("ready body")
    }
}
