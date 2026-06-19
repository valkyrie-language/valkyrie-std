namespace std.iterator;

trait FromIterator {
    type Item;

    micro from_iterator<I>(iter: I) -> Self
        where I: Iterator<Item = Self::Item>
}
