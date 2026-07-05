# MiddlewarePipeline smoke tests

using atlas.core;
using atlas.http;

[test]
micro `pipeline runs request-log middleware`() {
    let mut host: AtlasHost = AtlasHost::new()
    host = host.use_middleware(AtlasMiddleware::new("request-log", 10))
    host = host.get_route("/api/health", "health")
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/health")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 200 {
        panic("health should return 200")
    }
}

[test]
micro `short circuit skips terminal`() {
    let mut ctx: AtlasRouteContext = AtlasRouteContext::from_request(AtlasRequest::new("GET", "/x"))
    ctx.short_circuit = true
    let mut host: AtlasHost = AtlasHost::new()
    host = host.get_route("/x", "health")
    let mut pipeline: MiddlewarePipeline = MiddlewarePipeline::new()
    pipeline.execute(ctx, host)
    if ctx.response.status_code == 200 {
        if ctx.response.body.contains("status-ok") {
            panic("terminal should not run when short_circuited")
        }
    }
}
