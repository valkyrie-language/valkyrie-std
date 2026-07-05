# Atlas Wire DI smoke tests

using atlas;
using atlas.core;
using atlas.wire;
using atlas.systems;

[test]
micro `wire container registers store`() {
    let mut container: AtlasWireContainer = AtlasWireContainer::new()
    container = container.register_store("OrderStore", OrderStore::new("orders"))
    if container.contains("OrderStore") == false {
        panic("OrderStore should be registered")
    }
    let store: OrderStore = container.require_store("OrderStore")
    if store.is_ready() == false {
        panic("store should be ready")
    }
    if store.name.equals("orders") == false {
        panic("store name")
    }
}

[test]
micro `order system wire injects store`() {
    let mut container: AtlasWireContainer = AtlasWireContainer::new()
    container = container.register_store("OrderStore", OrderStore::new("orders"))
    let mut sys: OrderSystem = OrderSystem::new("OrderSystem")
    sys = sys.wire_from(container)
    if sys.store.is_ready() == false {
        panic("wire store not injected")
    }
    if sys.store.name.equals("orders") == false {
        panic("wired store name")
    }
}

[test]
micro `builtins available when unregistered custom store`() {
    let host: AtlasHost = builder()
    let sys: AtlasSystem = host.create_system("Demo")
    if sys.system_name.equals("Demo") == false {
        panic("system name")
    }
    # cache from container defaults should work
    sys.cache.set("k", "v")
    if sys.cache.get("k").equals("v") == false {
        panic("builtin cache")
    }
}
