namespace std.iterator;

structure TakeIterator<T, I> {
    _iter: I
    _count: usize
    _taken: usize
}

imply TakeIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        if self._taken >= self._count {
            return false
        }

        return self._iter.has_next()
    }

    micro next(mut self): Option<T> {
        if self._taken >= self._count {
            return option_none::<Item>()
        }

        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return option_none::<Item>()
        }

        self._taken = self._taken + 1
        return item
    }
}
