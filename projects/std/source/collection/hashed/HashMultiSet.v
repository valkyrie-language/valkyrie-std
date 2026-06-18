namespace std.collections;

class HashMultiSet<T> {
    _counts: HashMap<T, usize>
    _length: usize
}

imply HashMultiSet<T> {
    micro new(capacity: usize): Self {
        return Self {
            _counts: HashMap::new(capacity),
            _length: 0,
        }
    }

    micro insert(mut self, value: T): usize {
        let current: usize = self.count(value)
        let next: usize = current + 1
        self._counts.insert(value, next)
        self._length = self._length + 1
        return next
    }

    micro remove(mut self, value: T): bool {
        let current: usize = self.count(value)
        if current == 0 {
            return false
        }

        if current == 1 {
            self._counts.remove(value)
        }
        else {
            self._counts.insert(value, current - 1)
        }

        self._length = self._length - 1
        return true
    }

    micro remove_all(mut self, value: T): usize {
        let current: usize = self.count(value)
        if current == 0 {
            return 0
        }

        self._counts.remove(value)
        self._length = self._length - current
        return current
    }

    micro count(self, value: T): usize {
        let mut result: usize = 0
        self._counts.iterator(micro(entry_value: T, copies: usize) -> unit {
            if entry_value == value {
                result = copies
            }
        })
        return result
    }

    micro contains(self, value: T): bool {
        return self.count(value) > 0
    }

    micro length(self): usize {
        return self._length
    }

    micro distinct_length(self): usize {
        return self._counts.length()
    }

    micro is_empty(self): bool {
        return self._length == 0
    }

    micro clear(mut self) -> unit {
        self._counts.clear()
        self._length = 0
    }

    micro distinct_elements(self): List<T> {
        return self._counts.keys()
    }

    micro to_list(self): List<T> {
        let keys: List<T> = self._counts.keys()
        let mut result: List<T> = ArrayList::new(self._length)
        let mut i: usize = 0
        while i < keys.length() {
            let value: T = keys.get(i).unwrap()
            let mut copies: usize = self.count(value)
            while copies > 0 {
                result.push(value)
                copies = copies - 1
            }

            i = i + 1
        }

        return result
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let keys: List<T> = self._counts.keys()
        let mut i: usize = 0
        while i < keys.length() {
            let value: T = keys.get(i).unwrap()
            let mut copies: usize = self.count(value)
            while copies > 0 {
                f(value)
                copies = copies - 1
            }

            i = i + 1
        }
    }

    micro iterator(self, f: micro(T, usize) -> unit) -> unit {
        let keys: List<T> = self._counts.keys()
        let mut i: usize = 0
        while i < keys.length() {
            let value: T = keys.get(i).unwrap()
            f(value, self.count(value))
            i = i + 1
        }
    }

    micro from_list(values: List<T>): Self {
        let mut result: Self = Self::new(values.length())
        let mut i: usize = 0
        while i < values.length() {
            result.insert(values.get(i).unwrap())
            i = i + 1
        }

        return result
    }
}
