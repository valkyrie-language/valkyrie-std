namespace! std.iterator;

structure MapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> U
}

structure FilterIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
}

structure SkipIterator<T, I> {
    _iter: I
    _count: usize
    _skipped: usize
}
