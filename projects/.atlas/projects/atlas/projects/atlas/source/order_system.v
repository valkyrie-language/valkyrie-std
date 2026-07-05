# OrderSystem — Wire DI 示例（apply_wire 由编译器从 wire 字段生成）

namespace atlas.systems;

using std.text;
using atlas.wire;

class OrderSystem {
    system_name: utf8
    cache: MemoryAtlasCache
    queue: MemoryAtlasQueue
    event_bus: InMemoryAtlasEventBus
    logger: ConsoleAtlasSystemLogger
    wire store: OrderStore
}

imply OrderSystem {
    micro new(system_name: utf8): Self {
        return Self {
            system_name: system_name,
            cache: MemoryAtlasCache::new(),
            queue: MemoryAtlasQueue::new(),
            event_bus: InMemoryAtlasEventBus::new(),
            logger: ConsoleAtlasSystemLogger::new(system_name),
            store: OrderStore::empty()
        }
    }

    micro wire_from(mut self, container: AtlasWireContainer): Self {
        self.apply_wire(container)
        self.cache = container.cache
        self.queue = container.queue
        self.event_bus = container.event_bus
        self.logger = container.logger
        return self
    }
}
