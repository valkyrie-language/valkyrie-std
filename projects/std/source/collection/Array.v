namespace std.collection;

[clr("System.Runtime", "System.Array")]
[jvm("java.lang.Object[]")]
class Array<T> {
    _address: usize,
    _length: usize,
    _typing: Phantom<T>
}

imply Array<T> {
    [host_contract]
    micro length(self): usize {
        return __array_len(self)
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro get(self, ordinal: usize): Option<T> {

    }

    [host_contract]
    micro set(mut self, ordinal: usize, value: T): unit {

    }

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

    # Names must match HIR sugar (`suffix []` / `suffix ⁅⁆`) with no interior spaces.
    suffix `[]`(self, ordinal: usize): Option<T> {
        return self.get(ordinal)
    }

    suffix `[]=`(mut self, ordinal: usize, value: T): unit {
        self.set(ordinal, value)
    }

    suffix `⁅⁆`(self, cardinal: usize): Option<T> {
        return self.get(cardinal + 1)
    }

    suffix `⁅⁆=`(mut self, cardinal: usize, value: T): unit {
        self.set(cardinal + 1, value)
    }
}

[intrinsic("array.len")]
private micro __array_len<T>(self: Array<T>): usize { }

# Functional append: `result = push(result, item)`. Backends expand `[intrinsic("array.push")]`.
[intrinsic("array.push")]
micro push<T>(array: Array<T>, value: T): Array<T> { }

structure ArrayIterator<T> {
    _array: Array<T>
    _index: usize
}

imply Array<T>: std::iterator::IntoIterator {
    type Item = T;
    type Iter = ArrayIterator<T>;

    micro into_iterator(self): ArrayIterator<T> {
        return ArrayIterator::<T> {
            _array: self,
            _index: 0,
        }
    }
}

imply Array<T>: std::iterator::FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std::iterator::Iterator<Item = T>
    {
        let mut result: [T] = []
        loop item in iter {
            push(result, item)
        }

        return result
    }
}

imply ArrayIterator<T>: std::iterator::Iterator {
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
