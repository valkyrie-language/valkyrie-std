namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::HashMap::get)]
[inline(always)]
private micro hash_map_get<K, V>(map: HashMap<K, V>, key: K): Option<V> {
    if !__hash_map_clr_contains_key(map, key) {
        return None
    }

    return Some(__hash_map_clr_get(map, key))
}

[host_provider(std::collections::HashMap::insert)]
[inline(always)]
private micro hash_map_insert<K, V>(map: HashMap<K, V>, key: K, value: V): Option<V> {
    if __hash_map_clr_contains_key(map, key) {
        let old: V = __hash_map_clr_get(map, key)
        __hash_map_clr_set(map, key, value)
        return Some(old)
    }

    __hash_map_clr_set(map, key, value)
    return None
}

[host_provider(std::collections::HashMap::remove)]
[inline(always)]
private micro hash_map_remove<K, V>(map: HashMap<K, V>, key: K): Option<V> {
    if !__hash_map_clr_contains_key(map, key) {
        return None
    }

    let old: V = __hash_map_clr_get(map, key)
    __hash_map_clr_remove(map, key)
    return Some(old)
}

[host_provider(std::collections::HashMap::contains_key)]
[inline(always)]
private micro hash_map_contains_key<K, V>(map: HashMap<K, V>, key: K): bool {
    return __hash_map_clr_contains_key(map, key)
}

[host_provider(std::collections::HashMap::keys)]
[inline(always)]
private micro hash_map_keys<K, V>(map: HashMap<K, V>): List<K> {
    return __hash_map_clr_list_from_any::<K>(__hash_map_clr_keys(map))
}

[host_provider(std::collections::HashMap::values)]
[inline(always)]
private micro hash_map_values<K, V>(map: HashMap<K, V>): List<V> {
    return __hash_map_clr_list_from_any::<V>(__hash_map_clr_values(map))
}

[host_provider(std::collections::HashMap::length)]
[inline(always)]
private micro hash_map_length<K, V>(map: HashMap<K, V>): usize {
    return __hash_map_clr_length(map)
}

[host_provider(std::collections::HashMap::clear), inline(always)]
private micro hash_map_clear<K, V>(map: HashMap<K, V>): unit {
    __hash_map_clr_clear(map)
}

[host_provider(std::collections::HashMap::new)]
[inline(always)]
private micro hash_map_new<K, V>(capacity: usize): HashMap<K, V> {
    return __hash_map_clr_new::<K, V>(capacity)
}

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", ".ctor")]
private micro __hash_map_clr_new<K, V>(capacity: usize): HashMap<K, V> { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "ContainsKey"), pure]
private micro __hash_map_clr_contains_key<K, V>(map: HashMap<K, V>, key: K): bool { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "get_Item"), pure]
private micro __hash_map_clr_get<K, V>(map: HashMap<K, V>, key: K): V { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "set_Item")]
private micro __hash_map_clr_set<K, V>(map: HashMap<K, V>, key: K, value: V): unit { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "Remove")]
private micro __hash_map_clr_remove<K, V>(map: HashMap<K, V>, key: K): bool { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "get_Count"), pure]
private micro __hash_map_clr_length<K, V>(map: HashMap<K, V>): usize { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "Clear")]
private micro __hash_map_clr_clear<K, V>(map: HashMap<K, V>): unit { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "get_Keys"), pure]
private micro __hash_map_clr_keys<K, V>(map: HashMap<K, V>): any { }

[clr("System.Collections", "System.Collections.Generic.Dictionary`2", "get_Values"), pure]
private micro __hash_map_clr_values<K, V>(map: HashMap<K, V>): any { }

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __hash_map_clr_list_from_any<T>(items: any): ArrayList<T> { }
