# Atlas 部署入口桥接测试

using atlas.adaptor;
using atlas;
using atlas.core;
using atlas.http;

micro build_test_host(): AtlasHost {
    let mut host: AtlasHost = create_default([])
    host = host.get_route("/api/health", "health")
    host = host.get_route("/api/orders", "orders")
    host = host.get_route("/api/users", "users")
    host = host.build()
    return host
}

[test]
micro `entry bridge health`() {
    let mut host: AtlasHost = build_test_host()
    let req: AtlasRequest = AtlasRequest::new("GET", "/api/health")
    let resp: AtlasResponse = process_request(host, req)
    if resp.status_code != 200 {
        panic("health status")
    }
    if resp.body.contains("status-ok") == false {
        panic("health body")
    }
}

[test]
micro `entry bridge users`() {
    let mut host: AtlasHost = build_test_host()
    let req: AtlasRequest = AtlasRequest::new("GET", "/api/users")
    let resp: AtlasResponse = process_request(host, req)
    if resp.status_code != 200 {
        panic("users status")
    }
    if resp.body.equals("users-list") == false {
        panic("users body")
    }
}

[test]
micro `entry bridge http raw`() {
    let mut host: AtlasHost = build_test_host()
    let raw: utf8 = "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let resp: AtlasResponse = process_http(host, raw)
    if resp.status_code != 200 {
        panic("http raw status")
    }
}
