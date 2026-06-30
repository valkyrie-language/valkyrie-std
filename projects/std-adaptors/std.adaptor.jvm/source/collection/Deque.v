namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::Deque::new)]
[inline(always)]
private micro deque_new<T>(): Deque<T> {
    return __deque_jvm_new::<T>()
}

[host_provider(std::collections::Deque::push_front)]
[inline(always)]
private micro deque_push_front<T>(deque: Deque<T>, value: T): unit {
    __deque_jvm_add_first(deque, value)
}

[host_provider(std::collections::Deque::push_back)]
[inline(always)]
private micro deque_push_back<T>(deque: Deque<T>, value: T): unit {
    __deque_jvm_add_last(deque, value)
}

[host_provider(std::collections::Deque::pop_front)]
[inline(always)]
private micro deque_pop_front<T>(deque: Deque<T>): Option<T> {
    if __deque_jvm_length(deque) == 0 {
        return None
    }

    return Some(__deque_jvm_remove_first(deque))
}

[host_provider(std::collections::Deque::pop_back)]
[inline(always)]
private micro deque_pop_back<T>(deque: Deque<T>): Option<T> {
    if __deque_jvm_length(deque) == 0 {
        return None
    }

    return Some(__deque_jvm_remove_last(deque))
}

[host_provider(std::collections::Deque::peek_front)]
[inline(always)]
private micro deque_peek_front<T>(deque: Deque<T>): Option<T> {
    if __deque_jvm_length(deque) == 0 {
        return None
    }

    return Some(__deque_jvm_peek_first(deque))
}

[host_provider(std::collections::Deque::peek_back)]
[inline(always)]
private micro deque_peek_back<T>(deque: Deque<T>): Option<T> {
    if __deque_jvm_length(deque) == 0 {
        return None
    }

    return Some(__deque_jvm_peek_last(deque))
}

[host_provider(std::collections::Deque::length)]
[inline(always)]
private micro deque_length<T>(deque: Deque<T>): usize {
    return __deque_jvm_length(deque)
}

[host_provider(std::collections::Deque::clear)]
[inline(always)]
private micro deque_clear<T>(deque: Deque<T>): unit {
    __deque_jvm_clear(deque)
}

[jvm("java.util.ArrayDeque", "<init>")]
private micro __deque_jvm_new<T>(): Deque<T> { }

[jvm("java.util.ArrayDeque", "addFirst")]
private micro __deque_jvm_add_first<T>(deque: Deque<T>, value: T): unit { }

[jvm("java.util.ArrayDeque", "addLast")]
private micro __deque_jvm_add_last<T>(deque: Deque<T>, value: T): unit { }

[jvm("java.util.ArrayDeque", "removeFirst")]
private micro __deque_jvm_remove_first<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "removeLast")]
private micro __deque_jvm_remove_last<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "peekFirst"), pure]
private micro __deque_jvm_peek_first<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "peekLast"), pure]
private micro __deque_jvm_peek_last<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "size"), pure]
private micro __deque_jvm_length<T>(deque: Deque<T>): usize { }

[jvm("java.util.ArrayDeque", "clear")]
private micro __deque_jvm_clear<T>(deque: Deque<T>): unit { }
