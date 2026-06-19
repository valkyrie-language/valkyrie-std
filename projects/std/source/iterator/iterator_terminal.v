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
