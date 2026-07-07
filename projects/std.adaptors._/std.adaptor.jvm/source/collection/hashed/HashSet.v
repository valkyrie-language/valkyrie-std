namespace std.adaptor.jvm.collections;

[host_provider(std::collections::HashSet::insert)]
[inline(always)]
private micro hash_set_insert<T>(set: std.collections.HashSet<T>, value: T): bool {
    return __hash_set_jvm_add(set, value)
}

[host_provider(std::collections::HashSet::remove)]
[inline(always)]
private micro hash_set_remove<T>(set: std.collections.HashSet<T>, value: T): bool {
    return __hash_set_jvm_remove(set, value)
}

[host_provider(std::collections::HashSet::contains)]
[inline(always)]
private micro hash_set_contains<T>(set: std.collections.HashSet<T>, value: T): bool {
    return __hash_set_jvm_contains(set, value)
}

[host_provider(std::collections::HashSet::length)]
[inline(always)]
private micro hash_set_length<T>(set: std.collections.HashSet<T>): usize {
    return __hash_set_jvm_length(set)
}

[host_provider(std::collections::HashSet::clear)]
[inline(always)]
private micro hash_set_clear<T>(set: std.collections.HashSet<T>): unit {
    __hash_set_jvm_clear(set)
}

[host_provider(std::collections::HashSet::to_list)]
[inline(always)]
private micro hash_set_to_list<T>(set: std.collections.HashSet<T>): std.collections.List<T> {
    return __hash_set_jvm_list_from_any::<T>(set)
}

[host_provider(std::collections::HashSet::new)]
[inline(always)]
private micro hash_set_new<T>(): std.collections.HashSet<T> {
    return __hash_set_jvm_new::<T>()
}

[jvm("java.util.HashSet", "<init>")]
private micro __hash_set_jvm_new<T>(): std.collections.HashSet<T> { }

[jvm("java.util.HashSet", "add")]
private micro __hash_set_jvm_add<T>(set: std.collections.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "remove")]
private micro __hash_set_jvm_remove<T>(set: std.collections.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "contains"), pure]
private micro __hash_set_jvm_contains<T>(set: std.collections.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "size"), pure]
private micro __hash_set_jvm_length<T>(set: std.collections.HashSet<T>): usize { }

[jvm("java.util.HashSet", "clear")]
private micro __hash_set_jvm_clear<T>(set: std.collections.HashSet<T>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __hash_set_jvm_list_from_any<T>(items: any): std.collections.ArrayList<T> { }
