# AtlasRouter smoke tests

using atlas.core;
using atlas.http;

[test]
micro `static route matches`() {
    let mut router: AtlasRouter = AtlasRouter::new()
    router.get("/api/health", "health")
    let matched: AtlasRouteMatch = router.match_route("GET", "/api/health")
    if !matched.found {
        panic("static route should match")
    }
    if !matched.handler_id.equals("health") {
        panic("handler_id")
    }
}

[test]
micro `param route extracts id`() {
    let mut router: AtlasRouter = AtlasRouter::new()
    router.get("/api/users/:id", "user-get")
    let matched: AtlasRouteMatch = router.match_route("GET", "/api/users/42")
    if !matched.found {
        panic("param route should match")
    }
    if matched.params.length != 1 {
        panic("expected one param")
    }
    if !matched.params[0].key.equals("id") {
        panic("param name")
    }
    if !matched.params[0].value.equals("42") {
        panic("param value")
    }
}

[test]
micro `method mismatch fails`() {
    let mut router: AtlasRouter = AtlasRouter::new()
    router.get("/api/health", "health")
    let matched: AtlasRouteMatch = router.match_route("POST", "/api/health")
    if matched.found {
        panic("method mismatch should not match")
    }
}

[test]
micro `unknown path fails`() {
    let mut router: AtlasRouter = AtlasRouter::new()
    router.get("/api/health", "health")
    let matched: AtlasRouteMatch = router.match_route("GET", "/missing")
    if matched.found {
        panic("unknown path should not match")
    }
}
