namespace std.collection;

[clr("System.Runtime", "System.Array")]
[jvm("java.lang.Object[]")]
class Array<T> {}

imply Array<T> {
    [host_contract]
    micro length(self): usize {
        return self.length
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro get(self, ordinal: usize): Option<T>

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let item_count: usize = self.length()
        if item_count == 0 {
            return None
        }

        return self.get(item_count)
    }

    micro contains(self, value: T): bool {
        let mut i: usize = 1
        while i <= self.length() {
            if self.get(i).unwrap() == value {
                return true
            }

            i = i + 1
        }

        return false
    }
}

structure ArrayIterator<T> {
    _array: Array<T>
    _index: usize
}

imply Array<T>: std.iterator.IntoIterator {
    type Item = T;
    type Iter = ArrayIterator<T>;

    micro into_iterator(self): ArrayIterator<T> {
        return ArrayIterator::<T> {
            _array: self,
            _index: 0,
        }
    }
}

imply Array<T>: std.iterator.FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std.iterator.Iterator<Item = T>
    {
        let mut result: [T] = []
        loop item in iter {
            push(result, item)
        }

        return result
    }
}

imply ArrayIterator<T>: std.iterator.Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index < self._array.length()
    }

    micro next(mut self): Option<T> {
        if !self.has_next() {
            return None
        }

        let value: T = self._array.get(self._index + 1).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
