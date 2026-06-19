namespace std.iterator;

trait IntoIterator {
    type Item;
    type Iter: Iterator<Item=Self::Item>;

    micro into_iterator(self): Self::Iter
}
