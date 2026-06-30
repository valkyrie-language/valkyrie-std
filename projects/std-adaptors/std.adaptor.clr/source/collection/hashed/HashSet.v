namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::HashSet::insert)]
[inline(always)]
private micro hash_set_insert<T>(set: HashSet<T>, value: T): bool {
    return __hash_set_clr_add(set, value)
}

[host_provider(std::collections::HashSet::remove)]
[inline(always)]
private micro hash_set_remove<T>(set: HashSet<T>, value: T): bool {
    return __hash_set_clr_remove(set, value)
}

[inline(always), pure]
[host_provider(std::collections::HashSet::contains)]
[inline(always)]
private micro hash_set_contains<T>(set: HashSet<T>, value: T): bool {
    return __hash_set_clr_contains(set, value)
}

[host_provider(std::collections::HashSet::length)]
[inline(always)]
private micro hash_set_length<T>(set: HashSet<T>): usize {
    return __hash_set_clr_length(set)
}

[host_provider(std::collections::HashSet::clear)]
[inline(always)]
private micro hash_set_clear<T>(set: HashSet<T>): unit {
    __hash_set_clr_clear(set)
}

[host_provider(std::collections::HashSet::to_list)]
[inline(always)]
private micro hash_set_to_list<T>(set: HashSet<T>): List<T> {
    return __hash_set_clr_list_from_any::<T>(set)
}

[host_provider(std::collections::HashSet::new)]
[inline(always)]
private micro hash_set_new<T>(): HashSet<T> {
    return __hash_set_clr_new::<T>()
}

[clr("System.Collections", "System.Collections.Generic.HashSet`1", ".ctor")]
private micro __hash_set_clr_new<T>(): HashSet<T> { }

[clr("System.Collections", "System.Collections.Generic.HashSet`1", "Add")]
private micro __hash_set_clr_add<T>(set: HashSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.HashSet`1", "Remove")]
private micro __hash_set_clr_remove<T>(set: HashSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.HashSet`1", "Contains"), pure]
private micro __hash_set_clr_contains<T>(set: HashSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.HashSet`1", "get_Count"), pure]
private micro __hash_set_clr_length<T>(set: HashSet<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.HashSet`1", "Clear")]
private micro __hash_set_clr_clear<T>(set: HashSet<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __hash_set_clr_list_from_any<T>(items: any): ArrayList<T> { }
