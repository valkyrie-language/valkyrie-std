namespace std.collections;

[jvm("java.util.LinkedHashSet")]
class OrderedSet<T> {
    map: OrderedMap<T, bool>
}

imply OrderedSet<T>: Set<T> {
    [host_contract]
    micro insert(mut self, value: T): bool {
        if self.map.contains_key(value) {
            return false
        }

        self.map.insert(value, true)
        return true
    }

    [host_contract]
    micro remove(mut self, value: T): bool {
        return self.map.remove(value).is_some()
    }

    [host_contract]
    micro contains(self, value: T): bool {
        return self.map.contains_key(value)
    }

    [host_contract]
    micro length(self): usize {
        return self.map.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self) -> unit {
        self.map.clear()
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: List<T> = self.to_list()
        loop item in items {
            f(item)
        }
    }

    [host_contract]
    micro to_list(self): List<T> {
        return self.map.keys()
    }

    micro from_list(list: List<T>): Self {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply OrderedSet<T> {
    [host_contract]
    micro new(): Self {
        return Self { map: OrderedMap::new(16) }
    }
}
