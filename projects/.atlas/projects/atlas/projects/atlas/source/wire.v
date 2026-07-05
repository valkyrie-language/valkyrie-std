# Atlas Wire DI — 容器与注入协议（对标 C# [Wire] + SystemScanner）

namespace atlas.wire;

using std.text;
using atlas.systems;

# --- OrderStore：Wire 示例用的 Store 端口 ---

class OrderStore {
    name: utf8
}

imply OrderStore {
    micro new(name: utf8): Self {
        return Self { name: name }
    }

    micro empty(): Self {
        return Self { name: "" }
    }

    micro is_ready(self): bool {
        return self.name.is_empty() == false
    }
}

# --- Wire 容器 ---

class AtlasWireContainer {
    keys: [utf8]
    logger: ConsoleAtlasSystemLogger
    cache: MemoryAtlasCache
    queue: MemoryAtlasQueue
    event_bus: InMemoryAtlasEventBus
    store_keys: [utf8]
    stores: [OrderStore]
}

# 无反射时的注入协议：wire 字段由编译器生成 apply_wire
trait AtlasWireable {
    micro apply_wire(mut self, container: AtlasWireContainer): unit
}

imply AtlasWireContainer {
    micro new(): Self {
        return Self {
            keys: [],
            logger: ConsoleAtlasSystemLogger::new("atlas"),
            cache: MemoryAtlasCache::new(),
            queue: MemoryAtlasQueue::new(),
            event_bus: InMemoryAtlasEventBus::new(),
            store_keys: [],
            stores: []
        }
    }

    micro register_key(mut self, type_name: utf8): unit {
        if self.contains(type_name) {
            return
        }
        push(self.keys, type_name)
    }

    micro contains(self, type_name: utf8): bool {
        let mut i: i32 = 0
        while i < self.keys.length {
            if self.keys[i].equals(type_name) {
                return true
            }
            i = i + 1
        }
        return false
    }

    micro use_logger(mut self, logger: ConsoleAtlasSystemLogger): Self {
        self.logger = logger
        self.register_key("ConsoleAtlasSystemLogger")
        return self
    }

    micro use_cache(mut self, cache: MemoryAtlasCache): Self {
        self.cache = cache
        self.register_key("MemoryAtlasCache")
        return self
    }

    micro use_queue(mut self, queue: MemoryAtlasQueue): Self {
        self.queue = queue
        self.register_key("MemoryAtlasQueue")
        return self
    }

    micro use_event_bus(mut self, event_bus: InMemoryAtlasEventBus): Self {
        self.event_bus = event_bus
        self.register_key("InMemoryAtlasEventBus")
        return self
    }

    micro register_store(mut self, type_name: utf8, store: OrderStore): Self {
        let mut i: i32 = 0
        while i < self.store_keys.length {
            if self.store_keys[i].equals(type_name) {
                self.stores[i] = store
                self.register_key(type_name)
                return self
            }
            i = i + 1
        }
        push(self.store_keys, type_name)
        push(self.stores, store)
        self.register_key(type_name)
        return self
    }

    micro require_store(self, type_name: utf8): OrderStore {
        let mut i: i32 = 0
        while i < self.store_keys.length {
            if self.store_keys[i].equals(type_name) {
                return self.stores[i]
            }
            i = i + 1
        }
        return OrderStore::empty()
    }

    micro fill_builtins(self, mut sys: AtlasSystem): unit {
        sys.logger = self.logger
        sys.cache = self.cache
        sys.queue = self.queue
        sys.event_bus = self.event_bus
    }
}

micro wire_system(mut sys: AtlasSystem, container: AtlasWireContainer): unit {
    container.fill_builtins(sys)
}
