# Azure 部署入口测试

using atlas.adaptor.azure;
using atlas.core;
using atlas.http;

[test]
micro `azure handle health`() {
    let mut host: AtlasHost = build_host()
    let raw: utf8 = "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let resp: AtlasResponse = handle_http(host, raw)
    if resp.status_code != 200 {
        panic("azure health status")
    }
    if resp.body.contains("status-ok") == false {
        panic("azure health body")
    }
}

[test]
micro `azure handle request`() {
    let mut host: AtlasHost = build_host()
    let req: AtlasRequest = AtlasRequest::new("GET", "/api/users")
    let resp: AtlasResponse = handle_request(host, req)
    if resp.body.equals("users-list") == false {
        panic("azure users body")
    }
}
