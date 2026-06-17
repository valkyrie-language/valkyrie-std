namespace std.collections;

micro fixed_array_len<T>(items: [T]) -> usize {
    return len(items)
}

micro fixed_array_length<T>(items: [T]) -> usize {
    return len(items)
}

micro fixed_array_is_empty<T>(items: [T]) -> bool {
    return len(items) == 0
}

micro fixed_array_get<T>(items: [T], index: usize): Option<T> {
    if index >= len(items) {
        return None
    }

    return Some(items[index])
}

micro fixed_array_first<T>(items: [T]): Option<T> {
    return fixed_array_get(items, 0)
}

micro fixed_array_last<T>(items: [T]): Option<T> {
    let item_count: usize = len(items)
    if item_count == 0 {
        return None
    }

    return Some(items[item_count - 1])
}

micro fixed_array_contains<T>(items: [T], value: T): bool {
    let mut i: usize = 0
    while i < len(items) {
        if items[i] == value {
            return true
        }

        i = i + 1
    }

    return false
}
