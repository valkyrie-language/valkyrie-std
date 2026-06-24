namespace std.collections;

structure OrderedMapEntry<K, V> {
    key: K
    value: V
    active: bool
}

[jvm("java.util.LinkedHashMap")]
class OrderedMap<K, V> {
    _indices: HashMap<K, usize>
    _entries: ArrayList<OrderedMapEntry<K, V>>
    _count: usize
}

imply OrderedMap<K, V>: Map<K, V> {
    [host_contract]
    micro get(self, key: K): Option<V> {
        let slot_option: Option<usize> = self.find_slot(key)
        if slot_option.is_none() {
            return None
        }

        let entry: OrderedMapEntry<K, V> = self._entries.get(slot_option.unwrap()).unwrap()
        if !entry.active {
            return None
        }

        return Some(entry.value)
    }

    [host_contract]
    micro insert(mut self, key: K, value: V): Option<V> {
        let slot_option: Option<usize> = self.find_slot(key)
        if slot_option.is_some() {
            let slot: usize = slot_option.unwrap()
            let entry: OrderedMapEntry<K, V> = self._entries.get(slot).unwrap()
            self._entries.set(slot, OrderedMapEntry {
                key: key,
                value: value,
                active: true,
            })
            return Some(entry.value)
        }

        let slot: usize = self._entries.length()
        self._entries.push(OrderedMapEntry {
            key: key,
            value: value,
            active: true,
        })
        self._indices.insert(key, slot)
        self._count = self._count + 1
        return None
    }

    [host_contract]
    micro remove(mut self, key: K): Option<V> {
        let slot_option: Option<usize> = self.find_slot(key)
        if slot_option.is_none() {
            return None
        }

        let slot: usize = slot_option.unwrap()
        let entry: OrderedMapEntry<K, V> = self._entries.get(slot).unwrap()
        if !entry.active {
            return None
        }

        self._entries.set(slot, OrderedMapEntry {
            key: entry.key,
            value: entry.value,
            active: false,
        })
        self._count = self._count - 1
        return Some(entry.value)
    }

    [host_contract]
    micro contains_key(self, key: K): bool {
        return self.find_slot(key).is_some()
    }

    [host_contract]
    micro keys(self): List<K> {
        return self._entries
            .into_iterator()
            .filter(micro(entry: OrderedMapEntry<K, V>) -> bool {
                return entry.active
            })
            .map(micro(entry: OrderedMapEntry<K, V>) -> K {
                return entry.key
            })
            .collect_array_list()
    }

    [host_contract]
    micro values(self): List<V> {
        return self._entries
            .into_iterator()
            .filter(micro(entry: OrderedMapEntry<K, V>) -> bool {
                return entry.active
            })
            .map(micro(entry: OrderedMapEntry<K, V>) -> V {
                return entry.value
            })
            .collect_array_list()
    }

    [host_contract]
    micro length(self): usize {
        return self._count
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self) -> unit {
        self._indices.clear()
        self._entries.clear()
        self._count = 0
    }

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        let keys: List<K> = self.keys()
        let mut i: usize = 0
        while i < keys.length() {
            let key: K = keys.get(i).unwrap()
            f(key, self.get(key).unwrap())
            i = i + 1
        }
    }
}

imply OrderedMap<K, V> {
    [host_contract]
    micro new(capacity: usize): Self {
        return Self {
            _indices: HashMap::new(capacity),
            _entries: ArrayList::new(capacity),
            _count: 0,
        }
    }

    micro find_slot(self, key: K): Option<usize> {
        let mut cursor: usize = 0
        while cursor < self._entries.length() {
            let entry: OrderedMapEntry<K, V> = self._entries.get(cursor).unwrap()
            if entry.active && entry.key == key {
                return Some(cursor)
            }

            cursor = cursor + 1
        }

        return None
    }
}
