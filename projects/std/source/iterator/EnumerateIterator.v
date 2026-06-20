namespace std.iterator;

structure EnumerateIterator<T, I> {
    _iter: I
    _ordinal: usize
}

imply EnumerateIterator<T, I>: Iterator {
    type Item = (ordinal: usize, value: T);

    micro has_next(self): bool {
        return self._iter.has_next()
    }

    micro next(mut self): Option<(ordinal: usize, value: T)> {
        if !self._iter.has_next() {
            return None
        }

        let ordinal: usize = self._ordinal
        let value: T = self._iter.next().unwrap()
        self._ordinal = self._ordinal + 1
        return Some((ordinal, value))
    }
}
