# std.collections: HashSet implementation

namespace std.collections;

[clr("System.Collections", "System.Collections.Generic.HashSet`1")]
[jvm("java.util.HashSet")]
class HashSet<T> {
    _impl: SwissSet<T>
}

imply HashSet<T>: Set<T> {
    micro insert(mut self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_add(self, value)
            <% case "jvm" %>
            return __hash_set_jvm_add(self, value)
            <% else %>
        return self._impl.insert(value)
        <% end match %>
    }

    micro remove(mut self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_remove(self, value)
            <% case "jvm" %>
            return __hash_set_jvm_remove(self, value)
            <% else %>
        return self._impl.remove(value)
        <% end match %>
    }

    micro contains(self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_contains(self, value)
            <% case "jvm" %>
            return __hash_set_jvm_contains(self, value)
            <% else %>
        return self._impl.contains(value)
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_length(self)
            <% case "jvm" %>
            return __hash_set_jvm_length(self)
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
            __hash_set_clr_clear(self)
            <% case "jvm" %>
            __hash_set_jvm_clear(self)
            <% else %>
        self._impl.clear()
        <% end match %>
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: List<T> = self.to_list()
        let mut i: usize = 0
        while i < items.length() {
            f(items.get(i).unwrap())
            i = i + 1
        }
    }

    micro to_list(self): List<T> {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_list_from_any::<T>(self)
            <% case "jvm" %>
            return __hash_set_jvm_list_from_any::<T>(self)
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

imply HashSet<T> {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
            return __hash_set_clr_new::<T>()
            <% case "jvm" %>
            return __hash_set_jvm_new::<T>()
            <% else %>
        return Self { _impl: SwissSet::new(16) }
        <% end match %>
    }
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

[jvm("java.util.HashSet", "<init>")]
private micro __hash_set_jvm_new<T>(): HashSet<T> { }

[jvm("java.util.HashSet", "add")]
private micro __hash_set_jvm_add<T>(set: HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "remove")]
private micro __hash_set_jvm_remove<T>(set: HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "contains"), pure]
private micro __hash_set_jvm_contains<T>(set: HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "size"), pure]
private micro __hash_set_jvm_length<T>(set: HashSet<T>): usize { }

[jvm("java.util.HashSet", "clear")]
private micro __hash_set_jvm_clear<T>(set: HashSet<T>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __hash_set_jvm_list_from_any<T>(items: any): ArrayList<T> { }
