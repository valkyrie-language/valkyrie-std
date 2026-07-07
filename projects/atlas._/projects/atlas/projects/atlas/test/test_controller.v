# Controller + handler registry smoke tests

using atlas;
using atlas.core;
using atlas.wire;
using atlas.systems;

[test]
micro `health handler returns ok`() {
    let mut host: AtlasHost = builder()
    host = host.get_route("/api/health", "health")
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/health")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 200 {
        panic("health status")
    }
    if response.body.contains("status-ok") == false {
        panic("health body")
    }
}

[test]
micro `orders handler requires wired store`() {
    let mut host: AtlasHost = builder()
    host = host.get_route("/api/orders", "orders")
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/orders")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 400 {
        panic("orders without store should be 400")
    }
}

[test]
micro `orders handler works when store wired`() {
    let mut host: AtlasHost = builder()
    let mut container: AtlasWireContainer = host.container
    container = container.register_store("OrderStore", OrderStore::new("orders-db"))
    host = host.use_container(container)
    host = host.get_route("/api/orders", "orders")
    let request: AtlasRequest = AtlasRequest::new("GET", "/api/orders")
    let response: AtlasResponse = host.process(request)
    if response.status_code != 200 {
        panic("orders status")
    }
    if response.body.contains("orders-db") == false {
        panic("orders body")
    }
}
