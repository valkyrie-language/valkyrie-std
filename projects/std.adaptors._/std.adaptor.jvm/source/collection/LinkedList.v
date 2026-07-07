namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::LinkedList::new)]
[inline(always)]
private micro linked_list_new<T>(): LinkedList<T> {
    return __linked_list_jvm_new::<T>()
}

[host_provider(std::collections::LinkedList::length)]
[inline(always)]
private micro linked_list_length<T>(list: LinkedList<T>): usize {
    return __linked_list_jvm_length(list)
}

[host_provider(std::collections::LinkedList::push_front)]
[inline(always)]
private micro linked_list_push_front<T>(list: LinkedList<T>, value: T): unit {
    __linked_list_jvm_add_first(list, value)
}

[host_provider(std::collections::LinkedList::push_back)]
[inline(always)]
private micro linked_list_push_back<T>(list: LinkedList<T>, value: T): unit {
    __linked_list_jvm_add_last(list, value)
}

[host_provider(std::collections::LinkedList::pop_front)]
[inline(always)]
private micro linked_list_pop_front<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_jvm_length(list) == 0 {
        return None
    }

    return Some(__linked_list_jvm_remove_first(list))
}

[host_provider(std::collections::LinkedList::pop_back)]
[inline(always)]
private micro linked_list_pop_back<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_jvm_length(list) == 0 {
        return None
    }

    return Some(__linked_list_jvm_remove_last(list))
}

[host_provider(std::collections::LinkedList::peek_front)]
[inline(always)]
private micro linked_list_peek_front<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_jvm_length(list) == 0 {
        return None
    }

    return Some(__linked_list_jvm_get_first(list))
}

[host_provider(std::collections::LinkedList::peek_back)]
[inline(always)]
private micro linked_list_peek_back<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_jvm_length(list) == 0 {
        return None
    }

    return Some(__linked_list_jvm_get_last(list))
}

[host_provider(std::collections::LinkedList::clear)]
[inline(always)]
private micro linked_list_clear<T>(list: LinkedList<T>): unit {
    __linked_list_jvm_clear(list)
}

[host_provider(std::collections::LinkedList::contains)]
[inline(always)]
private micro linked_list_contains<T>(list: LinkedList<T>, value: T): bool {
    return __linked_list_jvm_contains(list, value)
}

[host_provider(std::collections::LinkedList::iter)]
[inline(always)]
private micro linked_list_iter<T>(list: LinkedList<T>, f: micro(T) -> unit): unit {
    let length: usize = __linked_list_jvm_length(list)
    let mut cursor: usize = 0
    while cursor < length {
        f(__linked_list_jvm_get(list, cursor))
        cursor = cursor + 1
    }
}

[host_provider(std::collections::LinkedList::iter_reverse)]
[inline(always)]
private micro linked_list_iter_reverse<T>(list: LinkedList<T>, f: micro(T) -> unit): unit {
    let length: usize = __linked_list_jvm_length(list)
    let mut cursor: usize = length
    while cursor > 0 {
        cursor = cursor - 1
        f(__linked_list_jvm_get(list, cursor))
    }
}

[jvm("java.util.LinkedList", "<init>")]
private micro __linked_list_jvm_new<T>(): LinkedList<T> { }

[jvm("java.util.LinkedList", "addFirst")]
private micro __linked_list_jvm_add_first<T>(list: LinkedList<T>, value: T): unit { }

[jvm("java.util.LinkedList", "addLast")]
private micro __linked_list_jvm_add_last<T>(list: LinkedList<T>, value: T): unit { }

[jvm("java.util.LinkedList", "removeFirst")]
private micro __linked_list_jvm_remove_first<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "removeLast")]
private micro __linked_list_jvm_remove_last<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "getFirst"), pure]
private micro __linked_list_jvm_get_first<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "getLast"), pure]
private micro __linked_list_jvm_get_last<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "contains"), pure]
private micro __linked_list_jvm_contains<T>(list: LinkedList<T>, value: T): bool { }

[jvm("java.util.LinkedList", "size"), pure]
private micro __linked_list_jvm_length<T>(list: LinkedList<T>): usize { }

[jvm("java.util.LinkedList", "clear")]
private micro __linked_list_jvm_clear<T>(list: LinkedList<T>): unit { }

[jvm("java.util.LinkedList", "get"), pure]
private micro __linked_list_jvm_get<T>(list: LinkedList<T>, index: usize): T { }
