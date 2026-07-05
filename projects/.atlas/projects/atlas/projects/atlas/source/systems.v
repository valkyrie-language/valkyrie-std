# Atlas 横切服务：日志 / 缓存 / 队列 / 事件总线 / System 基类

namespace atlas.systems;

using std.text;

# --- Logger ---

class ConsoleAtlasSystemLogger {
    system_name: utf8
}

imply ConsoleAtlasSystemLogger {
    micro new(system_name: utf8): Self {
        return Self { system_name: system_name }
    }

    micro log(self, action: utf8, detail: utf8): unit {
        std.io.print_line(format_log(self.system_name, action, "INFO", detail))
    }

    micro log_warning(self, action: utf8, detail: utf8): unit {
        std.io.print_line(format_log(self.system_name, action, "WARN", detail))
    }

    micro log_error(self, action: utf8, detail: utf8): unit {
        std.io.print_line(format_log(self.system_name, action, "ERROR", detail))
    }
}

class NullAtlasSystemLogger {
    _pad: i32
}

imply NullAtlasSystemLogger {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro log(self, action: utf8, detail: utf8): unit {
        let _a: utf8 = action
        let _d: utf8 = detail
    }

    micro log_warning(self, action: utf8, detail: utf8): unit {
        let _a: utf8 = action
        let _d: utf8 = detail
    }

    micro log_error(self, action: utf8, detail: utf8): unit {
        let _a: utf8 = action
        let _d: utf8 = detail
    }
}

micro format_log(system_name: utf8, action: utf8, level: utf8, detail: utf8): utf8 {
    let mut line: utf8 = "["
    line = line.concat(system_name)
    line = line.concat(":")
    line = line.concat(action)
    line = line.concat(":").concat(level).concat("]")
    if !detail.is_empty() {
        line = line.concat(" ").concat(detail)
    }
    return line
}

# --- Cache ---

class MemoryAtlasCache {
    keys: [utf8]
    values: [utf8]
}

imply MemoryAtlasCache {
    micro new(): Self {
        return Self { keys: [], values: [] }
    }

    micro get(self, key: utf8): utf8 {
        let mut i: i32 = 0
        while i < self.keys.length {
            if self.keys[i].equals(key) {
                return self.values[i]
            }
            i = i + 1
        }
        return ""
    }

    micro set(mut self, key: utf8, value: utf8): unit {
        let mut i: i32 = 0
        while i < self.keys.length {
            if self.keys[i].equals(key) {
                self.values[i] = value
                return
            }
            i = i + 1
        }
        push(self.keys, key)
        push(self.values, value)
    }

    micro remove(mut self, key: utf8): unit {
        let mut new_keys: [utf8] = []
        let mut new_values: [utf8] = []
        let mut i: i32 = 0
        while i < self.keys.length {
            if !self.keys[i].equals(key) {
                push(new_keys, self.keys[i])
                push(new_values, self.values[i])
            }
            i = i + 1
        }
        self.keys = new_keys
        self.values = new_values
    }

    micro contains(self, key: utf8): bool {
        let mut i: i32 = 0
        while i < self.keys.length {
            if self.keys[i].equals(key) {
                return true
            }
            i = i + 1
        }
        return false
    }
}

# --- Queue ---

class MemoryAtlasQueue {
    names: [utf8]
    payloads: [utf8]
}

imply MemoryAtlasQueue {
    micro new(): Self {
        return Self { names: [], payloads: [] }
    }

    micro enqueue(mut self, queue_name: utf8, payload: utf8): unit {
        push(self.names, queue_name)
        push(self.payloads, payload)
    }

    micro dequeue(mut self, queue_name: utf8): utf8 {
        let mut i: i32 = 0
        while i < self.names.length {
            if self.names[i].equals(queue_name) {
                let payload: utf8 = self.payloads[i]
                self.names = remove_utf8_at(self.names, i)
                self.payloads = remove_utf8_at(self.payloads, i)
                return payload
            }
            i = i + 1
        }
        return ""
    }

    micro length(self): i32 {
        return self.names.length
    }
}

# --- Event bus ---

class InMemoryAtlasEventBus {
    event_names: [utf8]
    payloads: [utf8]
}

imply InMemoryAtlasEventBus {
    micro new(): Self {
        return Self { event_names: [], payloads: [] }
    }

    micro publish(mut self, name: utf8, payload: utf8): unit {
        push(self.event_names, name)
        push(self.payloads, payload)
    }

    micro count(self): i32 {
        return self.event_names.length
    }

    micro last_payload(self): utf8 {
        if self.payloads.length == 0 {
            return ""
        }
        return self.payloads[self.payloads.length - 1]
    }
}

# --- AtlasSystem ---

class AtlasSystem {
    system_name: utf8
    logger: ConsoleAtlasSystemLogger
    cache: MemoryAtlasCache
    queue: MemoryAtlasQueue
    event_bus: InMemoryAtlasEventBus
}

imply AtlasSystem {
    micro new(system_name: utf8): Self {
        return Self {
            system_name: system_name,
            logger: ConsoleAtlasSystemLogger::new(system_name),
            cache: MemoryAtlasCache::new(),
            queue: MemoryAtlasQueue::new(),
            event_bus: InMemoryAtlasEventBus::new()
        }
    }
}

micro remove_utf8_at(items: [utf8], index: i32): [utf8] {
    let mut out: [utf8] = []
    let mut i: i32 = 0
    while i < items.length {
        if i != index {
            push(out, items[i])
        }
        i = i + 1
    }
    return out
}
