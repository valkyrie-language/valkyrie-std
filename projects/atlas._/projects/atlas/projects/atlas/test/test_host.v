# AtlasHost / AtlasApp smoke tests

using atlas;
using atlas.core;
using atlas.http;

[test]
micro `create_default parses port`() {
    let args: [utf8] = ["--port", "9090"]
    let host: AtlasHost = create_default(args)
    if host.port != 9090 {
        panic("port from args")
    }
}

[test]
micro `builder default port`() {
    let host: AtlasHost = builder()
    if host.port != 8080 {
        panic("default port")
    }
}

[test]
micro `host dispatch finds route`() {
    let mut host: AtlasHost = builder()
    host = host.get_route("/api/health", "health")
    host = host.build()
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/health")
    let matched: AtlasRouteMatch = host.dispatch(request)
    if matched.found == false {
        panic("dispatch should find route")
    }
}

[test]
micro `host handle applies result`() {
    let host: AtlasHost = builder()
    let request: AtlasRequest = AtlasRequest::new("GET", "/")
    let result: AtlasResult = AtlasResult::ok_json("ok-true")
    let response: AtlasResponse = host.handle(request, result)
    if response.status_code != 200 {
        panic("handle status")
    }
}
