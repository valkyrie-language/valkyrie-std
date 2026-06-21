namespace std.iterator;

structure TakeWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _done: bool
}

imply TakeWhileIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        if self._done {
            return false
        }
        return self._iter.has_next()
    }

    micro next(mut self): Option<T> {
        if self._done {
            return None
        }

        if !self._iter.has_next() {
            return None
        }

        let item: T = self._iter.next().unwrap()
        if self._predicate(item) {
            return Some(item)
        }

        self._done = true
        return None
    }
}
