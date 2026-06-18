namespace std.collections;

[jvm("java.util.LinkedHashSet")]
class OrderedSet<T> {
    map: OrderedMap<T, bool>
}

imply OrderedSet<T>: Set<T> {
    micro insert(mut self, value: T): bool {
        <% match arch %>
            <% case "jvm" %>
            return __ordered_set_jvm_add(self, value)
            <% else %>
        if self.map.contains_key(value) {
            return false
        }

        self.map.insert(value, true)
        return true
        <% end match %>
    }

    micro remove(mut self, value: T): bool {
        <% match arch %>
            <% case "jvm" %>
            return __ordered_set_jvm_remove(self, value)
            <% else %>
        return self.map.remove(value).is_some()
        <% end match %>
    }

    micro contains(self, value: T): bool {
        <% match arch %>
            <% case "jvm" %>
            return __ordered_set_jvm_contains(self, value)
            <% else %>
        return self.map.contains_key(value)
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "jvm" %>
            return __ordered_set_jvm_length(self)
            <% else %>
        return self.map.length()
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self) -> unit {
        <% match arch %>
            <% case "jvm" %>
            __ordered_set_jvm_clear(self)
            <% else %>
        self.map.clear()
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
            <% case "jvm" %>
            return __ordered_set_jvm_list_from_any::<T>(self)
            <% else %>
        return self.map.keys()
        <% end match %>
    }

    micro from_list(list: List<T>): Self {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply OrderedSet<T> {
    micro new(): Self {
        <% match arch %>
            <% case "jvm" %>
            return __ordered_set_jvm_new::<T>()
            <% else %>
        return Self { map: OrderedMap::new(16) }
        <% end match %>
    }
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
