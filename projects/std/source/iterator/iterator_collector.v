namespace std.iterator;

micro collect_array<I, T>(self: I) -> [T]
    where I: Iterator<Item = T>
{
    let mut result: [T] = []
    loop item in self {
        push(result, item)
    }

    return result
}

micro collect_array_list<I, T>(self: I) -> std.collection.ArrayList<T>
    where I: Iterator<Item = T>
{
    let mut result: std.collection.ArrayList<T> = std.collection.ArrayList::new(0)
    loop item in self {
        result.push(item)
    }

    return result
}
