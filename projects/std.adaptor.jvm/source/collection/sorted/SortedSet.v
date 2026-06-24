namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::SortedSet::insert)]
[inline(always)]
private micro sorted_set_insert<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_jvm_add(set, value)
}

[host_provider(std::collections::SortedSet::remove)]
[inline(always)]
private micro sorted_set_remove<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_jvm_remove(set, value)
}

[host_provider(std::collections::SortedSet::contains)]
[inline(always)]
private micro sorted_set_contains<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_jvm_contains(set, value)
}

[host_provider(std::collections::SortedSet::length)]
[inline(always)]
private micro sorted_set_length<T>(set: SortedSet<T>): usize {
    return __sorted_set_jvm_length(set)
}

[host_provider(std::collections::SortedSet::clear)]
[inline(always)]
private micro sorted_set_clear<T>(set: SortedSet<T>): unit {
    __sorted_set_jvm_clear(set)
}

[host_provider(std::collections::SortedSet::to_list)]
[inline(always)]
private micro sorted_set_to_list<T>(set: SortedSet<T>): List<T> {
    return __sorted_set_jvm_list_from_any::<T>(set)
}

[host_provider(std::collections::SortedSet::new)]
[inline(always)]
private micro sorted_set_new<T>(): SortedSet<T> {
    return __sorted_set_jvm_new::<T>()
}

[jvm("java.util.TreeSet", "<init>")]
private micro __sorted_set_jvm_new<T>(): SortedSet<T> { }

[jvm("java.util.TreeSet", "add")]
private micro __sorted_set_jvm_add<T>(set: SortedSet<T>, value: T): bool { }

[jvm("java.util.TreeSet", "remove")]
private micro __sorted_set_jvm_remove<T>(set: SortedSet<T>, value: T): bool { }

[jvm("java.util.TreeSet", "contains"), pure]
private micro __sorted_set_jvm_contains<T>(set: SortedSet<T>, value: T): bool { }

[jvm("java.util.TreeSet", "size"), pure]
private micro __sorted_set_jvm_length<T>(set: SortedSet<T>): usize { }

[jvm("java.util.TreeSet", "clear")]
private micro __sorted_set_jvm_clear<T>(set: SortedSet<T>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __sorted_set_jvm_list_from_any<T>(items: any): ArrayList<T> { }
