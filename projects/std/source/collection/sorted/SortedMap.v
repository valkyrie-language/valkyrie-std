namespace std.collections;

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2")]
[jvm("java.util.TreeMap")]
class SortedMap<K, V> {
    _impl: BTreeMap<K, V>
}

imply SortedMap<K, V>: Map<K, V> {
    micro get(self, key: K): Option<V> {
        <% match arch %>
            <% case "clr" %>
        if !__sorted_map_clr_contains_key(self, key) {
            return None
        }

        return Some(__sorted_map_clr_get(self, key))
            <% case "jvm" %>
        if !__sorted_map_jvm_contains_key(self, key) {
            return None
        }

        return Some(__sorted_map_jvm_get(self, key))
            <% else %>
        return self._impl.get(key)
        <% end match %>
    }

    micro insert(mut self, key: K, value: V): Option<V> {
        <% match arch %>
            <% case "clr" %>
        if __sorted_map_clr_contains_key(self, key) {
            let old: V = __sorted_map_clr_get(self, key)
            __sorted_map_clr_set(self, key, value)
            return Some(old)
        }

        __sorted_map_clr_set(self, key, value)
        return None
            <% case "jvm" %>
        if __sorted_map_jvm_contains_key(self, key) {
            let old: V = __sorted_map_jvm_get(self, key)
            __sorted_map_jvm_put(self, key, value)
            return Some(old)
        }

        __sorted_map_jvm_put(self, key, value)
        return None
            <% else %>
        return self._impl.insert(key, value)
        <% end match %>
    }

    micro remove(mut self, key: K): Option<V> {
        <% match arch %>
            <% case "clr" %>
        if !__sorted_map_clr_contains_key(self, key) {
            return None
        }

        let old: V = __sorted_map_clr_get(self, key)
        __sorted_map_clr_remove(self, key)
        return Some(old)
            <% case "jvm" %>
        if !__sorted_map_jvm_contains_key(self, key) {
            return None
        }

        let old: V = __sorted_map_jvm_get(self, key)
        __sorted_map_jvm_remove(self, key)
        return Some(old)
            <% else %>
        return self._impl.remove(key)
        <% end match %>
    }

    micro contains_key(self, key: K): bool {
        <% match arch %>
            <% case "clr" %>
        return __sorted_map_clr_contains_key(self, key)
            <% case "jvm" %>
        return __sorted_map_jvm_contains_key(self, key)
            <% else %>
        return self._impl.contains_key(key)
        <% end match %>
    }

    micro keys(self): List<K> {
        <% match arch %>
            <% case "clr" %>
        return __sorted_map_clr_list_from_any::<K>(__sorted_map_clr_keys(self))
            <% case "jvm" %>
        return __sorted_map_jvm_list_from_any::<K>(__sorted_map_jvm_keys(self))
            <% else %>
        return self._impl.keys()
        <% end match %>
    }

    micro values(self): List<V> {
        <% match arch %>
            <% case "clr" %>
        return __sorted_map_clr_list_from_any::<V>(__sorted_map_clr_values(self))
            <% case "jvm" %>
        return __sorted_map_jvm_list_from_any::<V>(__sorted_map_jvm_values(self))
            <% else %>
        return self._impl.values()
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
        return __sorted_map_clr_length(self)
            <% case "jvm" %>
        return __sorted_map_jvm_length(self)
            <% else %>
        return self._impl.length()
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self) -> unit {
        <% match arch %>
            <% case "clr" %>
        __sorted_map_clr_clear(self)
            <% case "jvm" %>
        __sorted_map_jvm_clear(self)
            <% else %>
        self._impl.clear()
        <% end match %>
    }

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        let keys: List<K> = self.keys()
        loop key in keys {
            f(key, self.get(key).unwrap())
        }
    }
}

imply SortedMap<K, V> {
    micro new(capacity: usize): Self {
        <% match arch %>
            <% case "clr" %>
        return __sorted_map_clr_new::<K, V>()
            <% case "jvm" %>
        return __sorted_map_jvm_new::<K, V>()
            <% else %>
        return Self {
            _impl: BTreeMap::new(capacity),
        }
        <% end match %>
    }
}

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", ".ctor")]
private micro __sorted_map_clr_new<K, V>(): SortedMap<K, V> { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "ContainsKey"), pure]
private micro __sorted_map_clr_contains_key<K, V>(map: SortedMap<K, V>, key: K): bool { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "get_Item"), pure]
private micro __sorted_map_clr_get<K, V>(map: SortedMap<K, V>, key: K): V { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "set_Item")]
private micro __sorted_map_clr_set<K, V>(map: SortedMap<K, V>, key: K, value: V): unit { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "Remove")]
private micro __sorted_map_clr_remove<K, V>(map: SortedMap<K, V>, key: K): bool { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "get_Count"), pure]
private micro __sorted_map_clr_length<K, V>(map: SortedMap<K, V>): usize { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "Clear")]
private micro __sorted_map_clr_clear<K, V>(map: SortedMap<K, V>): unit { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "get_Keys"), pure]
private micro __sorted_map_clr_keys<K, V>(map: SortedMap<K, V>): any { }

[clr("System.Collections", "System.Collections.Generic.SortedDictionary`2", "get_Values"), pure]
private micro __sorted_map_clr_values<K, V>(map: SortedMap<K, V>): any { }

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __sorted_map_clr_list_from_any<T>(items: any): ArrayList<T> { }

[jvm("java.util.TreeMap", "<init>")]
private micro __sorted_map_jvm_new<K, V>(): SortedMap<K, V> { }

[jvm("java.util.TreeMap", "containsKey"), pure]
private micro __sorted_map_jvm_contains_key<K, V>(map: SortedMap<K, V>, key: K): bool { }

[jvm("java.util.TreeMap", "get"), pure]
private micro __sorted_map_jvm_get<K, V>(map: SortedMap<K, V>, key: K): V { }

[jvm("java.util.TreeMap", "put")]
private micro __sorted_map_jvm_put<K, V>(map: SortedMap<K, V>, key: K, value: V): any { }

[jvm("java.util.TreeMap", "remove")]
private micro __sorted_map_jvm_remove<K, V>(map: SortedMap<K, V>, key: K): any { }

[jvm("java.util.TreeMap", "size"), pure]
private micro __sorted_map_jvm_length<K, V>(map: SortedMap<K, V>): usize { }

[jvm("java.util.TreeMap", "clear")]
private micro __sorted_map_jvm_clear<K, V>(map: SortedMap<K, V>): unit { }

[jvm("java.util.TreeMap", "keySet"), pure]
private micro __sorted_map_jvm_keys<K, V>(map: SortedMap<K, V>): any { }

[jvm("java.util.TreeMap", "values"), pure]
private micro __sorted_map_jvm_values<K, V>(map: SortedMap<K, V>): any { }

[jvm("java.util.ArrayList", "<init>")]
private micro __sorted_map_jvm_list_from_any<T>(items: any): ArrayList<T> { }
