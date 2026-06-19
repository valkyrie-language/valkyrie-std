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

    micro for_each(mut self, f: micro(Item) -> unit): unit {
        while self.has_next() {
            f(self.next().unwrap())
        }
    }

    micro fold<U>(mut self, initial: U, f: micro(U, Item) -> U): U {
        let mut result: U = initial
        while self.has_next() {
            result = f(result, self.next().unwrap())
        }

        return result
    }

    micro reduce<U>(self, initial: U, f: micro(U, Item) -> U): U {
        return self.fold(initial, f)
    }

    micro any(mut self, pred: micro(Item) -> bool): bool {
        while self.has_next() {
            if pred(self.next().unwrap()) {
                return true
            }
        }

        return false
    }

    micro count(mut self): usize {
        let mut result: usize = 0
        while self.has_next() {
            self.next()
            result = result + 1
        }

        return result
    }

    micro collect_array(self): [Item] {
        let mut result: [Item] = []
        loop item in self {
            push(result, item)
        }

        return result
    }

    micro collect_array_list(self): std.collection.ArrayList<Item> {
        let mut result: std.collection.ArrayList<Item> = std.collection.ArrayList::new(0)
        loop item in self {
            result.push(item)
        }

        return result
    }
}

trait IntoIterator {
    type Item;
    type Iter: Iterator<Item=Self::Item>;

    micro into_iterator(self): Self::Iter
}

imply MapIterator<T, U, I>: Iterator {
    type Item = U;

    micro has_next(self): bool {
        return self._iter.has_next()
    }

    micro next(mut self): Option<U> {
        if !self._iter.has_next() {
            return None
        }

        let item: T = self._iter.next().unwrap()
        return Some(self._mapper(item))
    }
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
