namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::SortedMap::get)]
[inline(always)]
private micro sorted_map_get<K, V>(map: SortedMap<K, V>, key: K): Option<V> {
    if !__sorted_map_jvm_contains_key(map, key) {
        return None
    }

    return Some(__sorted_map_jvm_get(map, key))
}

[host_provider(std::collections::SortedMap::insert)]
[inline(always)]
private micro sorted_map_insert<K, V>(map: SortedMap<K, V>, key: K, value: V): Option<V> {
    if __sorted_map_jvm_contains_key(map, key) {
        let old: V = __sorted_map_jvm_get(map, key)
        __sorted_map_jvm_put(map, key, value)
        return Some(old)
    }

    __sorted_map_jvm_put(map, key, value)
    return None
}

[host_provider(std::collections::SortedMap::remove)]
[inline(always)]
private micro sorted_map_remove<K, V>(map: SortedMap<K, V>, key: K): Option<V> {
    if !__sorted_map_jvm_contains_key(map, key) {
        return None
    }

    let old: V = __sorted_map_jvm_get(map, key)
    __sorted_map_jvm_remove(map, key)
    return Some(old)
}

[host_provider(std::collections::SortedMap::contains_key)]
[inline(always)]
private micro sorted_map_contains_key<K, V>(map: SortedMap<K, V>, key: K): bool {
    return __sorted_map_jvm_contains_key(map, key)
}

[host_provider(std::collections::SortedMap::keys)]
[inline(always)]
private micro sorted_map_keys<K, V>(map: SortedMap<K, V>): List<K> {
    return __sorted_map_jvm_list_from_any::<K>(__sorted_map_jvm_keys(map))
}

[host_provider(std::collections::SortedMap::values)]
[inline(always)]
private micro sorted_map_values<K, V>(map: SortedMap<K, V>): List<V> {
    return __sorted_map_jvm_list_from_any::<V>(__sorted_map_jvm_values(map))
}

[host_provider(std::collections::SortedMap::length)]
[inline(always)]
private micro sorted_map_length<K, V>(map: SortedMap<K, V>): usize {
    return __sorted_map_jvm_length(map)
}

[host_provider(std::collections::SortedMap::clear)]
[inline(always)]
private micro sorted_map_clear<K, V>(map: SortedMap<K, V>): unit {
    __sorted_map_jvm_clear(map)
}

[host_provider(std::collections::SortedMap::new)]
[inline(always)]
private micro sorted_map_new<K, V>(_capacity: usize): SortedMap<K, V> {
    return __sorted_map_jvm_new::<K, V>()
}

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
