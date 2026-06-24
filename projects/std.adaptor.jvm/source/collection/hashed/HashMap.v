namespace std.adaptor.jvm.collections;

[host_provider(std::collections::HashMap::get)]
[inline(always)]
private micro hash_map_get<K, V>(map: std.collections.HashMap<K, V>, key: K): Option<V> {
    if !__hash_map_jvm_contains_key(map, key) {
        return None
    }

    return Some(__hash_map_jvm_get(map, key))
}

[host_provider(std::collections::HashMap::insert)]
[inline(always)]
private micro hash_map_insert<K, V>(map: std.collections.HashMap<K, V>, key: K, value: V): Option<V> {
    if __hash_map_jvm_contains_key(map, key) {
        let old: V = __hash_map_jvm_get(map, key)
        __hash_map_jvm_put(map, key, value)
        return Some(old)
    }

    __hash_map_jvm_put(map, key, value)
    return None
}

[host_provider(std::collections::HashMap::remove)]
[inline(always)]
private micro hash_map_remove<K, V>(map: std.collections.HashMap<K, V>, key: K): Option<V> {
    if !__hash_map_jvm_contains_key(map, key) {
        return None
    }

    let old: V = __hash_map_jvm_get(map, key)
    __hash_map_jvm_remove(map, key)
    return Some(old)
}

[host_provider(std::collections::HashMap::contains_key)]
[inline(always)]
private micro hash_map_contains_key<K, V>(map: std.collections.HashMap<K, V>, key: K): bool {
    return __hash_map_jvm_contains_key(map, key)
}

[host_provider(std::collections::HashMap::keys)]
[inline(always)]
private micro hash_map_keys<K, V>(map: std.collections.HashMap<K, V>): std.collections.List<K> {
    return __hash_map_jvm_list_from_any::<K>(__hash_map_jvm_keys(map))
}

[host_provider(std::collections::HashMap::values)]
[inline(always)]
private micro hash_map_values<K, V>(map: std.collections.HashMap<K, V>): std.collections.List<V> {
    return __hash_map_jvm_list_from_any::<V>(__hash_map_jvm_values(map))
}

[host_provider(std::collections::HashMap::length)]
[inline(always)]
private micro hash_map_length<K, V>(map: std.collections.HashMap<K, V>): usize {
    return __hash_map_jvm_length(map)
}

[host_provider(std::collections::HashMap::clear)]
[inline(always)]
private micro hash_map_clear<K, V>(map: std.collections.HashMap<K, V>): unit {
    __hash_map_jvm_clear(map)
}

[host_provider(std::collections::HashMap::new)]
[inline(always)]
private micro hash_map_new<K, V>(capacity: usize): std.collections.HashMap<K, V> {
    return __hash_map_jvm_new::<K, V>(capacity)
}

[jvm("java.util.HashMap", "<init>")]
private micro __hash_map_jvm_new<K, V>(capacity: usize): std.collections.HashMap<K, V> { }

[jvm("java.util.HashMap", "containsKey"), pure]
private micro __hash_map_jvm_contains_key<K, V>(map: std.collections.HashMap<K, V>, key: K): bool { }

[jvm("java.util.HashMap", "get"), pure]
private micro __hash_map_jvm_get<K, V>(map: std.collections.HashMap<K, V>, key: K): V { }

[jvm("java.util.HashMap", "put")]
private micro __hash_map_jvm_put<K, V>(map: std.collections.HashMap<K, V>, key: K, value: V): any { }

[jvm("java.util.HashMap", "remove")]
private micro __hash_map_jvm_remove<K, V>(map: std.collections.HashMap<K, V>, key: K): any { }

[jvm("java.util.HashMap", "size"), pure]
private micro __hash_map_jvm_length<K, V>(map: std.collections.HashMap<K, V>): usize { }

[jvm("java.util.HashMap", "clear")]
private micro __hash_map_jvm_clear<K, V>(map: std.collections.HashMap<K, V>): unit { }

[jvm("java.util.HashMap", "keySet"), pure]
private micro __hash_map_jvm_keys<K, V>(map: std.collections.HashMap<K, V>): any { }

[jvm("java.util.HashMap", "values"), pure]
private micro __hash_map_jvm_values<K, V>(map: std.collections.HashMap<K, V>): any { }

[jvm("java.util.ArrayList", "<init>")]
private micro __hash_map_jvm_list_from_any<T>(items: any): std.collections.ArrayList<T> { }
