namespace std.collection;

[clr("System.Collections", "System.Collections.Generic.List`1")]
[jvm("java.util.ArrayList")]
class ArrayList<T> {
    _items: [T]
    _capacity: usize
}

imply ArrayList<T> {
    [host_contract]
    micro new(capacity: usize): Self {
        return ArrayList { _items: [], _capacity: capacity }
    }

    [host_contract]
    micro capacity(self): usize {
        return self._items.length
    }

    [host_contract]
    micro push(mut self, value: T): unit {
        push(self._items, value)
    }

    micro pop(mut self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.remove(size)
    }

    [host_contract]
    micro insert(mut self, ordinal: usize, value: T): unit {
        if ordinal == 0 || ordinal > self.length() + 1 {
            return
        }

        insert(self._items, ordinal - 1, value)
    }

    [host_contract]
    micro remove(mut self, ordinal: usize): Option<T> {
        if ordinal == 0 || ordinal > self.length() {
            return None
        }

        return Some(remove(self._items, ordinal - 1))
    }

    [host_contract]
    micro clear(mut self): unit {
        self._items = []
    }

    [host_contract]
    micro length(self): usize {
        return self._items.length
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.get(size)
    }

    [host_contract]
    micro get(self, ordinal: usize): Option<T> {
        if ordinal == 0 || ordinal > self.length() {
            return None
        }

        return Some(self._items::[ordinal - 1])
    }

    [host_contract]
    micro set(mut self, ordinal: usize, value: T): unit {
        if ordinal == 0 || ordinal > self.length() {
            return
        }

        self._items::[ordinal - 1] = value
    }

    [host_contract]
    micro contains(self, value: T): bool {
        loop item in self._items {
            if item == value {
                return true
            }
        }

        return false
    }
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

        let value: T = self._list.get(self._index + 1).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
