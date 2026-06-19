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
}
