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
    micro get(self, key: K): Option<V> {
        <% match arch %>
            <% case "jvm" %>
        if !__ordered_map_jvm_contains_key(self, key) {
            return None
        }

        return Some(__ordered_map_jvm_get(self, key))
            <% else %>
        let slot_option: Option<usize> = self.find_slot(key)
        if slot_option.is_none() {
            return None
        }

        let entry: OrderedMapEntry<K, V> = self._entries.get(slot_option.unwrap()).unwrap()
        if !entry.active {
            return None
        }

        return Some(entry.value)
        <% end match %>
    }

    micro insert(mut self, key: K, value: V): Option<V> {
        <% match arch %>
            <% case "jvm" %>
        if __ordered_map_jvm_contains_key(self, key) {
            let old: V = __ordered_map_jvm_get(self, key)
            __ordered_map_jvm_put(self, key, value)
            return Some(old)
        }

        __ordered_map_jvm_put(self, key, value)
        return None
            <% else %>
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
        <% end match %>
    }

    micro remove(mut self, key: K): Option<V> {
        <% match arch %>
            <% case "jvm" %>
        if !__ordered_map_jvm_contains_key(self, key) {
            return None
        }

        let old: V = __ordered_map_jvm_get(self, key)
        __ordered_map_jvm_remove(self, key)
        return Some(old)
            <% else %>
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
        <% end match %>
    }

    micro contains_key(self, key: K): bool {
        <% match arch %>
            <% case "jvm" %>
        return __ordered_map_jvm_contains_key(self, key)
            <% else %>
        return self.find_slot(key).is_some()
        <% end match %>
    }

    micro keys(self): List<K> {
        <% match arch %>
            <% case "jvm" %>
        return __ordered_map_jvm_list_from_any::<K>(__ordered_map_jvm_keys(self))
            <% else %>
        let mut result: List<K> = ArrayList::new(self._count)
        let mut cursor: usize = 0
        while cursor < self._entries.length() {
            let entry: OrderedMapEntry<K, V> = self._entries.get(cursor).unwrap()
            if entry.active {
                result.push(entry.key)
            }

            cursor = cursor + 1
        }

        return result
        <% end match %>
    }

    micro values(self): List<V> {
        <% match arch %>
            <% case "jvm" %>
        return __ordered_map_jvm_list_from_any::<V>(__ordered_map_jvm_values(self))
            <% else %>
        let mut result: List<V> = ArrayList::new(self._count)
        let mut cursor: usize = 0
        while cursor < self._entries.length() {
            let entry: OrderedMapEntry<K, V> = self._entries.get(cursor).unwrap()
            if entry.active {
                result.push(entry.value)
            }

            cursor = cursor + 1
        }

        return result
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "jvm" %>
        return __ordered_map_jvm_length(self)
            <% else %>
        return self._count
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self) -> unit {
        <% match arch %>
            <% case "jvm" %>
        __ordered_map_jvm_clear(self)
            <% else %>
        self._indices.clear()
        self._entries.clear()
        self._count = 0
        <% end match %>
    }

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        <% match arch %>
            <% case "jvm" %>
        let keys: List<K> = self.keys()
        let mut i: usize = 0
        while i < keys.length() {
            let key: K = keys.get(i).unwrap()
            f(key, self.get(key).unwrap())
            i = i + 1
        }
            <% else %>
        let mut cursor: usize = 0
        while cursor < self._entries.length() {
            let entry: OrderedMapEntry<K, V> = self._entries.get(cursor).unwrap()
            if entry.active {
                f(entry.key, entry.value)
            }

            cursor = cursor + 1
        }
        <% end match %>
    }
}

imply OrderedMap<K, V> {
    micro new(capacity: usize): Self {
        <% match arch %>
            <% case "jvm" %>
        return __ordered_map_jvm_new::<K, V>(capacity)
            <% else %>
        return Self {
            _indices: HashMap::new(capacity),
            _entries: ArrayList::new(capacity),
            _count: 0,
        }
        <% end match %>
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

[jvm("java.util.LinkedHashMap", "<init>")]
private micro __ordered_map_jvm_new<K, V>(capacity: usize): OrderedMap<K, V> { }

[jvm("java.util.LinkedHashMap", "containsKey"), pure]
private micro __ordered_map_jvm_contains_key<K, V>(map: OrderedMap<K, V>, key: K): bool { }

[jvm("java.util.LinkedHashMap", "get"), pure]
private micro __ordered_map_jvm_get<K, V>(map: OrderedMap<K, V>, key: K): V { }

[jvm("java.util.LinkedHashMap", "put")]
private micro __ordered_map_jvm_put<K, V>(map: OrderedMap<K, V>, key: K, value: V): any { }

[jvm("java.util.LinkedHashMap", "remove")]
private micro __ordered_map_jvm_remove<K, V>(map: OrderedMap<K, V>, key: K): any { }

[jvm("java.util.LinkedHashMap", "keySet"), pure]
private micro __ordered_map_jvm_keys<K, V>(map: OrderedMap<K, V>): any { }

[jvm("java.util.LinkedHashMap", "values"), pure]
private micro __ordered_map_jvm_values<K, V>(map: OrderedMap<K, V>): any { }

[jvm("java.util.LinkedHashMap", "size"), pure]
private micro __ordered_map_jvm_length<K, V>(map: OrderedMap<K, V>): usize { }

[jvm("java.util.LinkedHashMap", "clear")]
private micro __ordered_map_jvm_clear<K, V>(map: OrderedMap<K, V>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __ordered_map_jvm_list_from_any<T>(items: any): ArrayList<T> { }
