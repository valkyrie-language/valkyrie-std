namespace std.collections;

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2")]
[jvm("java.util.TreeMap")]
class SortedMap<K, V> {
    _impl: BTreeMap<K, V>
}

imply SortedMap<K, V>: Map<K, V> {
    [host_contract]
    micro get(self, key: K): Option<V> {
        return self._impl.get(key)
    }

    [host_contract]
    micro insert(mut self, key: K, value: V): Option<V> {
        return self._impl.insert(key, value)
    }

    [host_contract]
    micro remove(mut self, key: K): Option<V> {
        return self._impl.remove(key)
    }

    [host_contract]
    micro contains_key(self, key: K): bool {
        return self._impl.contains_key(key)
    }

    [host_contract]
    micro keys(self): List<K> {
        return self._impl.keys()
    }

    [host_contract]
    micro values(self): List<V> {
        return self._impl.values()
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

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        let keys: List<K> = self.keys()
        loop key in keys {
            f(key, self.get(key).unwrap())
        }
    }
}

imply SortedMap<K, V> {
    [host_contract]
    micro new(capacity: usize): Self {
        return Self {
            _impl: BTreeMap::new(capacity),
        }
    }
}
