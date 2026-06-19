namespace std.iterator;

trait Iterator {
    type Item;

    micro has_next(self): bool
    micro next(mut self): Option<Item>

    micro map<U>(self, f: micro(Item) -> U) -> MapIterator<Item, U, Self> {
        return MapIterator<Item, U, Self> {
            _iter: self,
            _mapper: f,
        }
    }

    micro filter(self, pred: micro(Item) -> bool) -> FilterIterator<Item, Self> {
        return FilterIterator<Item, Self> {
            _iter: self,
            _predicate: pred,
        }
    }

    micro skip(self, count: usize) -> SkipIterator<Item, Self> {
        return SkipIterator<Item, Self> {
            _iter: self,
            _count: count,
            _skipped: 0,
        }
    }

    micro take(self, count: usize) -> TakeIterator<Item, Self> {
        return TakeIterator<Item, Self> {
            _iter: self,
            _count: count,
            _taken: 0,
        }
    }
}
