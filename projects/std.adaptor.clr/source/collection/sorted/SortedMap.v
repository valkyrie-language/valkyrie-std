namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::SortedMap::get)]
[inline(always)]
private micro sorted_map_get<K, V>(map: SortedMap<K, V>, key: K): Option<V> {
    if !__sorted_map_clr_contains_key(map, key) {
        return None
    }

    return Some(__sorted_map_clr_get(map, key))
}

[host_provider(std::collections::SortedMap::insert)]
[inline(always)]
private micro sorted_map_insert<K, V>(map: SortedMap<K, V>, key: K, value: V): Option<V> {
    if __sorted_map_clr_contains_key(map, key) {
        let old: V = __sorted_map_clr_get(map, key)
        __sorted_map_clr_set(map, key, value)
        return Some(old)
    }

    __sorted_map_clr_set(map, key, value)
    return None
}

[host_provider(std::collections::SortedMap::remove)]
[inline(always)]
private micro sorted_map_remove<K, V>(map: SortedMap<K, V>, key: K): Option<V> {
    if !__sorted_map_clr_contains_key(map, key) {
        return None
    }

    let old: V = __sorted_map_clr_get(map, key)
    __sorted_map_clr_remove(map, key)
    return Some(old)
}

[host_provider(std::collections::SortedMap::contains_key)]
[inline(always)]
private micro sorted_map_contains_key<K, V>(map: SortedMap<K, V>, key: K): bool {
    return __sorted_map_clr_contains_key(map, key)
}

[host_provider(std::collections::SortedMap::keys)]
[inline(always)]
private micro sorted_map_keys<K, V>(map: SortedMap<K, V>): List<K> {
    return __sorted_map_clr_list_from_any::<K>(__sorted_map_clr_keys(map))
}

[host_provider(std::collections::SortedMap::values)]
[inline(always)]
private micro sorted_map_values<K, V>(map: SortedMap<K, V>): List<V> {
    return __sorted_map_clr_list_from_any::<V>(__sorted_map_clr_values(map))
}

[host_provider(std::collections::SortedMap::length)]
[inline(always)]
private micro sorted_map_length<K, V>(map: SortedMap<K, V>): usize {
    return __sorted_map_clr_length(map)
}

[host_provider(std::collections::SortedMap::clear)]
[inline(always)]
private micro sorted_map_clear<K, V>(map: SortedMap<K, V>): unit {
    __sorted_map_clr_clear(map)
}

[host_provider(std::collections::SortedMap::new)]
[inline(always)]
private micro sorted_map_new<K, V>(_capacity: usize): SortedMap<K, V> {
    return __sorted_map_clr_new::<K, V>()
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
