namespace std.iterator;

structure SkipIterator<T, I> {
    _iter: I
    _count: usize
    _skipped: usize
}

imply SkipIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        let mut iter: I = self._iter
        let mut skipped: usize = self._skipped
        while skipped < self._count {
            if !iter.has_next() {
                return false
            }

            iter.next()
            skipped = skipped + 1
        }

        return iter.has_next()
    }

    micro next(mut self): Option<T> {
        while self._skipped < self._count {
            if !self._iter.has_next() {
                return None
            }

            self._iter.next()
            self._skipped = self._skipped + 1
        }

        return self._iter.next()
    }
}
