namespace std.collections;

[clr("System.Collections", "System.Collections.Generic.SortedSet`1")]
[jvm("java.util.TreeSet")]
class SortedSet<T> {
    _impl: BTreeSet<T>
}

imply SortedSet<T>: Set<T> {
    micro insert(mut self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_add(self, value)
            <% case "jvm" %>
        return __sorted_set_jvm_add(self, value)
            <% else %>
        return self._impl.insert(value)
        <% end match %>
    }

    micro remove(mut self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_remove(self, value)
            <% case "jvm" %>
        return __sorted_set_jvm_remove(self, value)
            <% else %>
        return self._impl.remove(value)
        <% end match %>
    }

    micro contains(self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_contains(self, value)
            <% case "jvm" %>
        return __sorted_set_jvm_contains(self, value)
            <% else %>
        return self._impl.contains(value)
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_length(self)
            <% case "jvm" %>
        return __sorted_set_jvm_length(self)
            <% else %>
        return self._impl.length()
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self) -> unit {
        <% match arch %>
            <% case "clr" %>
        __sorted_set_clr_clear(self)
            <% case "jvm" %>
        __sorted_set_jvm_clear(self)
            <% else %>
        self._impl.clear()
        <% end match %>
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: List<T> = self.to_list()
        loop item in items {
            f(item)
        }
    }

    micro to_list(self): List<T> {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_list_from_any::<T>(self)
            <% case "jvm" %>
        return __sorted_set_jvm_list_from_any::<T>(self)
            <% else %>
        return self._impl.to_list()
        <% end match %>
    }

    micro from_list(list: List<T>): Self {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply SortedSet<T> {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
        return __sorted_set_clr_new::<T>()
            <% case "jvm" %>
        return __sorted_set_jvm_new::<T>()
            <% else %>
        return Self { _impl: BTreeSet::new() }
        <% end match %>
    }
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
