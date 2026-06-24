# std.collections: HashSet implementation

namespace std.collections;

[clr("System.Collections", "System.Collections.Generic.HashSet`1")]
[jvm("java.util.HashSet")]
class HashSet<T> {
    _impl: SwissSet<T>
}

imply HashSet<T>: Set<T> {
    [host_contract]
    micro insert(mut self, value: T): bool {
        return self._impl.insert(value)
    }

    [host_contract]
    micro remove(mut self, value: T): bool {
        return self._impl.remove(value)
    }

    [host_contract]
    micro contains(self, value: T): bool {
        return self._impl.contains(value)
    }

    [host_contract]
    micro length(self): usize {
        return self._impl.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self) -> unit {
        self._impl.clear()
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: List<T> = self.to_list()
        loop item in items {
            f(item)
        }
    }

    [host_contract]
    micro to_list(self): List<T> {
        return self._impl.to_list()
    }

    micro from_list(list: List<T>): Self {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply HashSet<T> {
    [host_contract]
    micro new(): Self {
        return Self { _impl: SwissSet::new(16) }
    }
}
