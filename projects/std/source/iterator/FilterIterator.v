namespace std.iterator;

structure FilterIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
}

imply FilterIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        let mut iter: I = self._iter
        while iter.has_next() {
            let item: T = iter.next().unwrap()
            if self._predicate(item) {
                return true
            }
        }

        return false
    }

    micro next(mut self): Option<T> {
        while self._iter.has_next() {
            let item: T = self._iter.next().unwrap()
            if self._predicate(item) {
                return Some(item)
            }
        }

        return None
    }
}
