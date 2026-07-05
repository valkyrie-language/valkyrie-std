# End-to-end pipeline smoke test

using atlas;
using atlas.core;
using atlas.http;
using atlas.wire;
using atlas.systems;

[test]
micro `full pipeline health route`() {
    let mut host: AtlasHost = create_default([])
    host = host.get_route("/api/health", "health")
    host = host.build()
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/health")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 200 {
        panic("pipeline status")
    }
}

[test]
micro `full pipeline unknown route 404`() {
    let host: AtlasHost = create_default([])
    let request: AtlasRequest = AtlasRequest::new("GET", "/missing")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 404 {
        panic("unknown route should 404")
    }
}

[test]
micro `create_system has logger from container`() {
    let host: AtlasHost = builder()
    let sys: AtlasSystem = host.create_system("Demo")
    if sys.logger.system_name.equals("atlas") == false {
        panic("logger should come from container")
    }
}
