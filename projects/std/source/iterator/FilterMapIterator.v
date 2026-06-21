namespace std.iterator;

structure FilterMapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> Option<U>
}

imply FilterMapIterator<T, U, I>: Iterator {
    type Item = U;

    micro has_next(self): bool {
        return self._iter.has_next()
    }

    micro next(mut self): Option<U> {
        while self._iter.has_next() {
            let item: T = self._iter.next().unwrap()
            let mapped: Option<U> = self._mapper(item)
            if mapped.is_some() {
                return mapped
            }
        }

        return None
    }
}
