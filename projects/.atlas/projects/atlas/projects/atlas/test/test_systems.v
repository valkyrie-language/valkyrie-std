# MemoryAtlasCache / Queue / EventBus smoke tests

using atlas.systems;

[test]
micro `cache set get remove`() {
    let mut cache: MemoryAtlasCache = MemoryAtlasCache::new()
    cache.set("k", "v")
    if !cache.get("k").equals("v") {
        panic("cache get")
    }
    if !cache.contains("k") {
        panic("cache contains")
    }
    cache.remove("k")
    if cache.contains("k") {
        panic("cache remove")
    }
}

[test]
micro `queue enqueue dequeue`() {
    let mut queue: MemoryAtlasQueue = MemoryAtlasQueue::new()
    queue.enqueue("mail", "payload-1")
    if queue.length() != 1 {
        panic("queue length")
    }
    let payload: utf8 = queue.dequeue("mail")
    if !payload.equals("payload-1") {
        panic("queue payload")
    }
    if queue.length() != 0 {
        panic("queue empty after dequeue")
    }
}

[test]
micro `event bus publish`() {
    let mut bus: InMemoryAtlasEventBus = InMemoryAtlasEventBus::new()
    bus.publish("OrderPlaced", "id:1")
    if bus.count() != 1 {
        panic("event count")
    }
    if !bus.last_payload().equals("id:1") {
        panic("event payload")
    }
}

[test]
micro `system has built-in services`() {
    let sys: AtlasSystem = AtlasSystem::new("OrderSystem")
    if !sys.system_name.equals("OrderSystem") {
        panic("system name")
    }
}
