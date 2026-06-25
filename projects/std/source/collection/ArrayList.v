namespace std.collection;

[clr("System.Collections", "System.Collections.Generic.List`1")]
[jvm("java.util.ArrayList")]
class ArrayList<T> {
    _items: [T]
    _capacity: usize
}

imply ArrayList<T> {
    micro new(capacity: usize): Self {
        return __array_list_host_new::<T>(capacity)
    }

    micro capacity(self): usize {
        return __array_list_host_capacity(self)
    }

    micro push(mut self, value: T): unit {
        __array_list_host_push(self, value)
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

        __array_list_host_insert(self, index, value)
    }

    micro remove(mut self, index: usize): Option<T> {
        if index >= self.length() {
            return None
        }

        return Some(__array_list_host_remove(self, index))
    }

    micro clear(mut self): unit {
        __array_list_host_clear(self)
    }

    micro length(self): usize {
        return __array_list_host_length(self)
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

        return Some(__array_list_host_get(self, index))
    }

    micro set(mut self, index: usize, value: T): unit {
        if index >= self.length() {
            return
        }

        __array_list_host_set(self, index, value)
    }

    micro contains(self, value: T): bool {
        return __array_list_host_contains(self, value)
    }
}

[host_contract]
private micro __array_list_host_new<T>(capacity: usize): ArrayList<T> {
    return ArrayList { _items: [], _capacity: capacity }
}

[host_contract]
private micro __array_list_host_capacity<T>(list: ArrayList<T>): usize {
    return list._items.length
}

[host_contract]
private micro __array_list_host_push<T>(list: ArrayList<T>, value: T): unit {
    push(list._items, value)
}

[host_contract]
private micro __array_list_host_insert<T>(list: ArrayList<T>, index: usize, value: T): unit {
    insert(list._items, index, value)
}

[host_contract]
private micro __array_list_host_remove<T>(list: ArrayList<T>, index: usize): T {
    return remove(list._items, index)
}

[host_contract]
private micro __array_list_host_clear<T>(list: ArrayList<T>): unit {
    list._items = []
}

[host_contract]
private micro __array_list_host_length<T>(list: ArrayList<T>): usize {
    return list._items.length
}

[host_contract]
private micro __array_list_host_get<T>(list: ArrayList<T>, index: usize): T {
    return list._items[index]
}

[host_contract]
private micro __array_list_host_set<T>(list: ArrayList<T>, index: usize, value: T): unit {
    list._items[index] = value
}

[host_contract]
private micro __array_list_host_contains<T>(list: ArrayList<T>, value: T): bool {
    loop item in list._items {
        if item == value {
            return true
        }
    }

    return false
}

structure ArrayListIterator<T> {
    _list: ArrayList<T>
    _index: usize
}

imply ArrayList<T>: std.iterator.IntoIterator {
    type Item = T;
    type Iter = ArrayListIterator<T>;

    micro into_iterator(self): ArrayListIterator<T> {
        return ArrayListIterator {
            _list: self,
            _index: 0,
        }
    }
}

imply ArrayList<T>: std.iterator.FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std.iterator.Iterator<Item = T>
    {
        let mut result: Self = Self::new(0)
        loop item in iter {
            result.push(item)
        }

        return result
    }
}

imply ArrayListIterator<T>: std.iterator.Iterator {
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
