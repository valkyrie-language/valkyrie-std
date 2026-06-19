namespace std.iterator;

micro for_each<I, T>(self: I, f: micro(T) -> unit): unit
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while iter.has_next() {
        f(iter.next().unwrap())
    }
}

micro fold<I, T, U>(self: I, initial: U, f: micro(U, T) -> U): U
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: U = initial
    while iter.has_next() {
        result = f(result, iter.next().unwrap())
    }

    return result
}

micro reduce<I, T, U>(self: I, initial: U, f: micro(U, T) -> U): U
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: U = initial
    while iter.has_next() {
        result = f(result, iter.next().unwrap())
    }

    return result
}

micro any<I, T>(self: I, pred: micro(T) -> bool): bool
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while iter.has_next() {
        if pred(iter.next().unwrap()) {
            return true
        }
    }

    return false
}

micro all<I, T>(self: I, pred: micro(T) -> bool): bool
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while iter.has_next() {
        if !pred(iter.next().unwrap()) {
            return false
        }
    }

    return true
}

micro find<I, T>(self: I, pred: micro(T) -> bool): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while iter.has_next() {
        let item: T = iter.next().unwrap()
        if pred(item) {
            return Some(item)
        }
    }

    return None
}

micro first<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    if !iter.has_next() {
        return None
    }

    return iter.next()
}

micro last<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: Option<T> = None
    while iter.has_next() {
        result = iter.next()
    }

    return result
}

micro nth<I, T>(self: I, index: usize): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut current: usize = 0
    while iter.has_next() {
        let item: T = iter.next().unwrap()
        if current == index {
            return Some(item)
        }

        current = current + 1
    }

    return None
}

micro position<I, T>(self: I, pred: micro(T) -> bool): Option<usize>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut index: usize = 0
    while iter.has_next() {
        if pred(iter.next().unwrap()) {
            return Some(index)
        }

        index = index + 1
    }

    return None
}

micro contains<I, T>(self: I, value: T): bool
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while iter.has_next() {
        if iter.next().unwrap() == value {
            return true
        }
    }

    return false
}

micro count<I, T>(self: I): usize
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: usize = 0
    while iter.has_next() {
        iter.next()
        result = result + 1
    }

    return result
}
