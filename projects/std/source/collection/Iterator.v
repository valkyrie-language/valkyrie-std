namespace std.collection;

trait Iterator {
    type Item;

    micro has_next(self): bool
    micro next(mut self): Option<Item>

    micro map<U>(self, f: micro(Item) -> U) -> Iterator<Item=U> {
        loop item in self {
            yield f(item)
        }
    }

    micro filter(self, pred: micro(Item) -> bool) -> Iterator<Item=Item> {
        loop item in self {
            if pred(item) {
                yield item
            }
        }
    }

    micro skip(self, count: usize) -> Iterator<Item=Item> {
        let mut skipped: usize = 0
        loop item in self {
            if skipped < count {
                skipped = skipped + 1
                continue
            }

            yield item
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

    micro collect_array_list(self): ArrayList<Item> {
        let mut result: ArrayList<Item> = ArrayList::new(0)
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
