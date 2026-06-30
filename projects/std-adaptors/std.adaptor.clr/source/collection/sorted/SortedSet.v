namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::SortedSet::insert)]
[inline(always)]
private micro sorted_set_insert<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_clr_add(set, value)
}

[host_provider(std::collections::SortedSet::remove)]
[inline(always)]
private micro sorted_set_remove<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_clr_remove(set, value)
}

[host_provider(std::collections::SortedSet::contains)]
[inline(always)]
private micro sorted_set_contains<T>(set: SortedSet<T>, value: T): bool {
    return __sorted_set_clr_contains(set, value)
}

[host_provider(std::collections::SortedSet::length)]
[inline(always)]
private micro sorted_set_length<T>(set: SortedSet<T>): usize {
    return __sorted_set_clr_length(set)
}

[host_provider(std::collections::SortedSet::clear)]
[inline(always)]
private micro sorted_set_clear<T>(set: SortedSet<T>): unit {
    __sorted_set_clr_clear(set)
}

[host_provider(std::collections::SortedSet::to_list)]
[inline(always)]
private micro sorted_set_to_list<T>(set: SortedSet<T>): List<T> {
    return __sorted_set_clr_list_from_any::<T>(set)
}

[host_provider(std::collections::SortedSet::new)]
[inline(always)]
private micro sorted_set_new<T>(): SortedSet<T> {
    return __sorted_set_clr_new::<T>()
}

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", ".ctor")]
private micro __sorted_set_clr_new<T>(): SortedSet<T> { }

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", "Add")]
private micro __sorted_set_clr_add<T>(set: SortedSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", "Remove")]
private micro __sorted_set_clr_remove<T>(set: SortedSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", "Contains"), pure]
private micro __sorted_set_clr_contains<T>(set: SortedSet<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", "get_Count"), pure]
private micro __sorted_set_clr_length<T>(set: SortedSet<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.SortedSet`1", "Clear")]
private micro __sorted_set_clr_clear<T>(set: SortedSet<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __sorted_set_clr_list_from_any<T>(items: any): ArrayList<T> { }
