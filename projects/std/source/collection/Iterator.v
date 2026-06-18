namespace std.collection;

trait Iterator {
    type Item;

    micro has_next(self): bool
    micro next(mut self): Option<Item>
}

trait IntoIterator {
    type Item;

    micro into_iterator(self): any
}
