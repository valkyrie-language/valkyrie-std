namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::OrderedSet::insert)]
[inline(always)]
private micro ordered_set_insert<T>(set: OrderedSet<T>, value: T): bool {
    return __ordered_set_jvm_add(set, value)
}

[host_provider(std::collections::OrderedSet::remove)]
[inline(always)]
private micro ordered_set_remove<T>(set: OrderedSet<T>, value: T): bool {
    return __ordered_set_jvm_remove(set, value)
}

[host_provider(std::collections::OrderedSet::contains)]
[inline(always)]
private micro ordered_set_contains<T>(set: OrderedSet<T>, value: T): bool {
    return __ordered_set_jvm_contains(set, value)
}

[host_provider(std::collections::OrderedSet::length)]
[inline(always)]
private micro ordered_set_length<T>(set: OrderedSet<T>): usize {
    return __ordered_set_jvm_length(set)
}

[host_provider(std::collections::OrderedSet::clear)]
[inline(always)]
private micro ordered_set_clear<T>(set: OrderedSet<T>): unit {
    __ordered_set_jvm_clear(set)
}

[host_provider(std::collections::OrderedSet::to_list)]
[inline(always)]
private micro ordered_set_to_list<T>(set: OrderedSet<T>): List<T> {
    return __ordered_set_jvm_list_from_any::<T>(set)
}

[host_provider(std::collections::OrderedSet::new)]
[inline(always)]
private micro ordered_set_new<T>(): OrderedSet<T> {
    return __ordered_set_jvm_new::<T>()
}

[jvm("java.util.LinkedHashSet", "<init>")]
private micro __ordered_set_jvm_new<T>(): OrderedSet<T> { }

[jvm("java.util.LinkedHashSet", "add")]
private micro __ordered_set_jvm_add<T>(set: OrderedSet<T>, value: T): bool { }

[jvm("java.util.LinkedHashSet", "remove")]
private micro __ordered_set_jvm_remove<T>(set: OrderedSet<T>, value: T): bool { }

[jvm("java.util.LinkedHashSet", "contains"), pure]
private micro __ordered_set_jvm_contains<T>(set: OrderedSet<T>, value: T): bool { }

[jvm("java.util.LinkedHashSet", "size"), pure]
private micro __ordered_set_jvm_length<T>(set: OrderedSet<T>): usize { }

[jvm("java.util.LinkedHashSet", "clear")]
private micro __ordered_set_jvm_clear<T>(set: OrderedSet<T>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __ordered_set_jvm_list_from_any<T>(items: any): ArrayList<T> { }
