# std.collections: HashSet implementation

namespace std.collections;

class HashSet<T> {
    map: Map<T, bool>
}

imply HashSet<T>: Set<T> {
    micro insert(mut self, value: T): bool {
        if self.map.contains_key(value) {
            return false
        }
        self.map.insert(value, true)
        return true
    }
    micro remove(mut self, value: T): bool {
        return self.map.remove(value).is_some()
    }
    micro contains(self, value: T): bool {
        return self.map.contains_key(value)
    }
    micro len(self): usize {
        return self.map.length()
    }
    micro is_empty(self): bool {
        return self.map.is_empty()
    }
    micro clear(mut self) -> unit {
        self.map.clear()
    }
    micro iter(self, f: micro(T) -> unit) -> unit {
        self.map.iterator(micro(key: T, _: bool) -> unit { f(key) })
    }
    micro to_list(self): List<T> {
        return self.map.keys()
    }
    micro from_list(list: List<T>): Self {
        let mut result: Self = Self.new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply HashSet<T> {
    micro new(): Self {
        return Self { map: HashMap.new(16) }
    }
}
