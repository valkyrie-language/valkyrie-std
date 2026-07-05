namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::OrderedMap::get)]
[inline(always)]
private micro ordered_map_get<K, V>(map: OrderedMap<K, V>, key: K): Option<V> {
    if !__ordered_map_jvm_contains_key(map, key) {
        return None
    }

    return Some(__ordered_map_jvm_get(map, key))
}

[host_provider(std::collections::OrderedMap::insert)]
[inline(always)]
private micro ordered_map_insert<K, V>(map: OrderedMap<K, V>, key: K, value: V): Option<V> {
    if __ordered_map_jvm_contains_key(map, key) {
        let old: V = __ordered_map_jvm_get(map, key)
        __ordered_map_jvm_put(map, key, value)
        return Some(old)
    }

    __ordered_map_jvm_put(map, key, value)
    return None
}

[host_provider(std::collections::OrderedMap::remove)]
[inline(always)]
private micro ordered_map_remove<K, V>(map: OrderedMap<K, V>, key: K): Option<V> {
    if !__ordered_map_jvm_contains_key(map, key) {
        return None
    }

    let old: V = __ordered_map_jvm_get(map, key)
    __ordered_map_jvm_remove(map, key)
    return Some(old)
}

[host_provider(std::collections::OrderedMap::contains_key)]
[inline(always)]
private micro ordered_map_contains_key<K, V>(map: OrderedMap<K, V>, key: K): bool {
    return __ordered_map_jvm_contains_key(map, key)
}

[host_provider(std::collections::OrderedMap::keys)]
[inline(always)]
private micro ordered_map_keys<K, V>(map: OrderedMap<K, V>): List<K> {
    return __ordered_map_jvm_list_from_any::<K>(__ordered_map_jvm_keys(map))
}

[host_provider(std::collections::OrderedMap::values)]
[inline(always)]
private micro ordered_map_values<K, V>(map: OrderedMap<K, V>): List<V> {
    return __ordered_map_jvm_list_from_any::<V>(__ordered_map_jvm_values(map))
}

[host_provider(std::collections::OrderedMap::length)]
[inline(always)]
private micro ordered_map_length<K, V>(map: OrderedMap<K, V>): usize {
    return __ordered_map_jvm_length(map)
}

[host_provider(std::collections::OrderedMap::clear)]
[inline(always)]
private micro ordered_map_clear<K, V>(map: OrderedMap<K, V>): unit {
    __ordered_map_jvm_clear(map)
}

[host_provider(std::collections::OrderedMap::new)]
[inline(always)]
private micro ordered_map_new<K, V>(capacity: usize): OrderedMap<K, V> {
    return __ordered_map_jvm_new::<K, V>(capacity)
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
