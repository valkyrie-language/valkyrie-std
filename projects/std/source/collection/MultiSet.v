namespace std.collections;

class MultiSet<T> {
    _impl: HashMultiSet<T>
}

imply MultiSet<T> {
    micro new(): Self {
        return Self {
            _impl: HashMultiSet::new(16),
        }
    }

    micro with_capacity(capacity: usize): Self {
        return Self {
            _impl: HashMultiSet::new(capacity),
        }
    }

    micro insert(mut self, value: T): usize {
        return self._impl.insert(value)
    }

    micro remove(mut self, value: T): bool {
        return self._impl.remove(value)
    }

    micro remove_all(mut self, value: T): usize {
        return self._impl.remove_all(value)
    }

    micro count(self, value: T): usize {
        return self._impl.count(value)
    }

    micro contains(self, value: T): bool {
        return self._impl.contains(value)
    }

    micro length(self): usize {
        return self._impl.length()
    }

    micro distinct_length(self): usize {
        return self._impl.distinct_length()
    }

    micro is_empty(self): bool {
        return self._impl.is_empty()
    }

    micro clear(mut self) -> unit {
        self._impl.clear()
    }

    micro distinct_elements(self): List<T> {
        return self._impl.distinct_elements()
    }

    micro to_list(self): List<T> {
        return self._impl.to_list()
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        self._impl.iter(f)
    }

    micro iterator(self, f: micro(T, usize) -> unit) -> unit {
        self._impl.iterator(f)
    }

    micro from_list(values: List<T>): Self {
        return Self {
            _impl: HashMultiSet::from_list(values),
        }
    }
}
