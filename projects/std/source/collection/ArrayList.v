namespace std.collection;

[clr("System.Collections", "System.Collections.Generic.List`1")]
[jvm("java.util.ArrayList")]
class ArrayList<T> {
    _items: [T]
    _capacity: usize
}

imply ArrayList<T> {
    micro new(capacity: usize): Self {
        <% match arch %>
            <% case "clr" %>
            return __array_list_clr_new::<T>(capacity)
            <% case "jvm" %>
            return __array_list_jvm_new::<T>(capacity)
            <% else %>
            return Self { _items: [], _capacity: capacity }
        <% end match %>
    }

    micro capacity(self): usize {
        <% match arch %>
            <% case "clr" %>
            return __array_list_clr_capacity(self)
            <% case "jvm" %>
            return __array_list_jvm_length(self)
            <% else %>
            return self._items.length
        <% end match %>
    }

    micro push(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
            __array_list_clr_add(self, value)
            <% case "jvm" %>
            __array_list_jvm_add(self, value)
            <% else %>
            push(self._items, value)
        <% end match %>
    }

    micro pop(mut self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.remove(size - 1)
    }

    micro insert(mut self, index: usize, value: T): unit {
        if index > self.length() {
            return
        }

        <% match arch %>
            <% case "clr" %>
            __array_list_clr_insert(self, index, value)
            <% case "jvm" %>
            __array_list_jvm_insert(self, index, value)
            <% else %>
            insert(self._items, index, value)
        <% end match %>
    }

    micro remove(mut self, index: usize): Option<T> {
        if index >= self.length() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
            let value: T = __array_list_clr_get(self, index)
            __array_list_clr_remove_at(self, index)
            return Some(value)
            <% case "jvm" %>
            let value: T = __array_list_jvm_remove_at(self, index)
            return Some(value)
            <% else %>
            return Some(remove(self._items, index))
        <% end match %>
    }

    micro clear(mut self): unit {
        <% match arch %>
            <% case "clr" %>
            __array_list_clr_clear(self)
            <% case "jvm" %>
            __array_list_jvm_clear(self)
            <% else %>
            self._items = []
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
            return __array_list_clr_length(self)
            <% case "jvm" %>
            return __array_list_jvm_length(self)
            <% else %>
            return self._items.length
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro first(self): Option<T> {
        return self.get(0)
    }

    micro last(self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.get(size - 1)
    }

    micro get(self, index: usize): Option<T> {
        if index >= self.length() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
            return Some(__array_list_clr_get(self, index))
            <% case "jvm" %>
            return Some(__array_list_jvm_get(self, index))
            <% else %>
            return Some(self._items[index])
        <% end match %>
    }

    micro set(mut self, index: usize, value: T): unit {
        if index >= self.length() {
            return
        }

        <% match arch %>
            <% case "clr" %>
            __array_list_clr_set(self, index, value)
            <% case "jvm" %>
            __array_list_jvm_set(self, index, value)
            <% else %>
            self._items[index] = value
        <% end match %>
    }

    micro contains(self, value: T): bool {
        <% match arch %>
            <% case "clr" %>
            return __array_list_clr_contains(self, value)
            <% case "jvm" %>
            return __array_list_jvm_contains(self, value)
            <% else %>
            loop item in self._items {
                if item == value {
                    return true
                }
            }

            return false
        <% end match %>
    }
}

structure ArrayListIterator<T> {
    _list: ArrayList<T>
    _index: usize
}

imply ArrayList<T>: IntoIterator {
    type Item = T;
    type Iter = ArrayListIterator<T>;

    micro into_iterator(self): ArrayListIterator<T> {
        return ArrayListIterator<T> {
            _list: self,
            _index: 0,
        }
    }
}

imply ArrayListIterator<T>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index < self._list.length()
    }

    micro next(mut self): Option<T> {
        if !self.has_next() {
            return None
        }

        let value: T = self._list.get(self._index).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __array_list_clr_new<T>(capacity: usize): ArrayList<T> { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Count"), pure]
private micro __array_list_clr_length<T>(list: ArrayList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Capacity"), pure]
private micro __array_list_clr_capacity<T>(list: ArrayList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Add")]
private micro __array_list_clr_add<T>(list: ArrayList<T>, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Insert")]
private micro __array_list_clr_insert<T>(list: ArrayList<T>, index: usize, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Item"), pure]
private micro __array_list_clr_get<T>(list: ArrayList<T>, index: usize): T { }

[clr("System.Collections", "System.Collections.Generic.List`1", "set_Item")]
private micro __array_list_clr_set<T>(list: ArrayList<T>, index: usize, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "RemoveAt")]
private micro __array_list_clr_remove_at<T>(list: ArrayList<T>, index: usize): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Clear")]
private micro __array_list_clr_clear<T>(list: ArrayList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Contains"), pure]
private micro __array_list_clr_contains<T>(list: ArrayList<T>, value: T): bool { }

[jvm("java.util.ArrayList", "<init>")]
private micro __array_list_jvm_new<T>(capacity: usize): ArrayList<T> { }

[jvm("java.util.ArrayList", "size"), pure]
private micro __array_list_jvm_length<T>(list: ArrayList<T>): usize { }

[jvm("java.util.ArrayList", "add")]
private micro __array_list_jvm_add<T>(list: ArrayList<T>, value: T): bool { }

[jvm("java.util.ArrayList", "add")]
private micro __array_list_jvm_insert<T>(list: ArrayList<T>, index: usize, value: T): unit { }

[jvm("java.util.ArrayList", "get"), pure]
private micro __array_list_jvm_get<T>(list: ArrayList<T>, index: usize): T { }

[jvm("java.util.ArrayList", "set")]
private micro __array_list_jvm_set<T>(list: ArrayList<T>, index: usize, value: T): T { }

[jvm("java.util.ArrayList", "remove")]
private micro __array_list_jvm_remove_at<T>(list: ArrayList<T>, index: usize): T { }

[jvm("java.util.ArrayList", "clear")]
private micro __array_list_jvm_clear<T>(list: ArrayList<T>): unit { }

[jvm("java.util.ArrayList", "contains"), pure]
private micro __array_list_jvm_contains<T>(list: ArrayList<T>, value: T): bool { }

