namespace std.iterator;

⍝ 迭代器 trait
⍝ 定义按顺序产出元素的统一接口。
trait Iterator {
    type Item;

    ⍝ 判断当前迭代器是否还有下一个元素。
    micro has_next(self): bool
    ⍝ 返回下一个元素。
    ⍝ 当迭代结束时返回 `None`，否则返回 `Some(Item)`。
    ⍝ 这里不能设计成 `Item?`，因为当 `Item` 自身允许为 `null` 时，
    ⍝ `Item?` 无法区分“产出了一个 `null`”与“迭代已经结束”这两种语义。
    micro next(mut self): Option<Item>

    micro map<U>(self, f: micro(Item) -> U) -> MapIterator<Item, U, Self> {
        return MapIterator::<Item, U, Self> {
            _iter: self,
            _mapper: f,
        }
    }

    micro filter(self, pred: micro(Item) -> bool) -> FilterIterator<Item, Self> {
        return FilterIterator::<Item, Self> {
            _iter: self,
            _predicate: pred,
        }
    }

    micro filter_map<U>(self, f: micro(Item) -> Option<U>) -> FilterMapIterator<Item, U, Self> {
        return FilterMapIterator::<Item, U, Self> {
            _iter: self,
            _mapper: f,
        }
    }

    micro enumerate(self) -> EnumerateIterator<Item, Self> {
        return EnumerateIterator::<Item, Self> {
            _iter: self,
            _ordinal: 1,
        }
    }

    micro skip(self, count: usize) -> SkipIterator<Item, Self> {
        return SkipIterator::<Item, Self> {
            _iter: self,
            _count: count,
            _skipped: 0,
        }
    }

    micro skip_while(self, pred: micro(Item) -> bool) -> SkipWhileIterator<Item, Self> {
        return SkipWhileIterator::<Item, Self> {
            _iter: self,
            _predicate: pred,
            _skipped: false,
        }
    }

    micro take(self, count: usize) -> TakeIterator<Item, Self> {
        return TakeIterator::<Item, Self> {
            _iter: self,
            _count: count,
            _taken: 0,
        }
    }

    micro take_while(self, pred: micro(Item) -> bool) -> TakeWhileIterator<Item, Self> {
        return TakeWhileIterator::<Item, Self> {
            _iter: self,
            _predicate: pred,
            _done: false,
        }
    }
}
