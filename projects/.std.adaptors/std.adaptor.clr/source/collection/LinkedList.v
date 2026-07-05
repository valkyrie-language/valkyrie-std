namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::LinkedList::new)]
[inline(always)]
private micro linked_list_new<T>(): LinkedList<T> {
    return __linked_list_clr_new::<T>()
}

[host_provider(std::collections::LinkedList::length)]
[inline(always)]
private micro linked_list_length<T>(list: LinkedList<T>): usize {
    return __linked_list_clr_length(list)
}

[host_provider(std::collections::LinkedList::push_front)]
[inline(always)]
private micro linked_list_push_front<T>(list: LinkedList<T>, value: T): unit {
    __linked_list_clr_add_first(list, value)
}

[host_provider(std::collections::LinkedList::push_back)]
[inline(always)]
private micro linked_list_push_back<T>(list: LinkedList<T>, value: T): unit {
    __linked_list_clr_add_last(list, value)
}

[host_provider(std::collections::LinkedList::pop_front)]
[inline(always)]
private micro linked_list_pop_front<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_clr_length(list) == 0 {
        return None
    }

    let node: any = __linked_list_clr_first_node::<T>(list)
    let value: T = __linked_list_clr_node_value::<T>(node)
    __linked_list_clr_remove_first(list)
    return Some(value)
}

[host_provider(std::collections::LinkedList::pop_back)]
[inline(always)]
private micro linked_list_pop_back<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_clr_length(list) == 0 {
        return None
    }

    let node: any = __linked_list_clr_last_node::<T>(list)
    let value: T = __linked_list_clr_node_value::<T>(node)
    __linked_list_clr_remove_last(list)
    return Some(value)
}

[host_provider(std::collections::LinkedList::peek_front)]
[inline(always)]
private micro linked_list_peek_front<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_clr_length(list) == 0 {
        return None
    }

    return Some(__linked_list_clr_node_value::<T>(__linked_list_clr_first_node::<T>(list)))
}

[host_provider(std::collections::LinkedList::peek_back)]
[inline(always)]
private micro linked_list_peek_back<T>(list: LinkedList<T>): Option<T> {
    if __linked_list_clr_length(list) == 0 {
        return None
    }

    return Some(__linked_list_clr_node_value::<T>(__linked_list_clr_last_node::<T>(list)))
}

[host_provider(std::collections::LinkedList::clear)]
[inline(always)]
private micro linked_list_clear<T>(list: LinkedList<T>): unit {
    __linked_list_clr_clear(list)
}

[host_provider(std::collections::LinkedList::contains)]
[inline(always)]
private micro linked_list_contains<T>(list: LinkedList<T>, value: T): bool {
    return __linked_list_clr_contains(list, value)
}

[host_provider(std::collections::LinkedList::iter)]
[inline(always)]
private micro linked_list_iter<T>(list: LinkedList<T>, f: micro(T) -> unit): unit {
    let length: usize = __linked_list_clr_length(list)
    if length == 0 {
        return
    }

    let mut node: any = __linked_list_clr_first_node::<T>(list)
    let mut cursor: usize = 0
    while cursor < length {
        f(__linked_list_clr_node_value::<T>(node))
        node = __linked_list_clr_node_next(node)
        cursor = cursor + 1
    }
}

[host_provider(std::collections::LinkedList::iter_reverse)]
[inline(always)]
private micro linked_list_iter_reverse<T>(list: LinkedList<T>, f: micro(T) -> unit): unit {
    let length: usize = __linked_list_clr_length(list)
    if length == 0 {
        return
    }

    let mut node: any = __linked_list_clr_last_node::<T>(list)
    let mut cursor: usize = 0
    while cursor < length {
        f(__linked_list_clr_node_value::<T>(node))
        node = __linked_list_clr_node_prev(node)
        cursor = cursor + 1
    }
}

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", ".ctor")]
private micro __linked_list_clr_new<T>(): LinkedList<T> { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddFirst")]
private micro __linked_list_clr_add_first<T>(list: LinkedList<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddLast")]
private micro __linked_list_clr_add_last<T>(list: LinkedList<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveFirst")]
private micro __linked_list_clr_remove_first<T>(list: LinkedList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveLast")]
private micro __linked_list_clr_remove_last<T>(list: LinkedList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_First"), pure]
private micro __linked_list_clr_first_node<T>(list: LinkedList<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Last"), pure]
private micro __linked_list_clr_last_node<T>(list: LinkedList<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Value"), pure]
private micro __linked_list_clr_node_value<T>(node: any): T { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Next"), pure]
private micro __linked_list_clr_node_next(node: any): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Previous"), pure]
private micro __linked_list_clr_node_prev(node: any): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Contains"), pure]
private micro __linked_list_clr_contains<T>(list: LinkedList<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Count"), pure]
private micro __linked_list_clr_length<T>(list: LinkedList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Clear")]
private micro __linked_list_clr_clear<T>(list: LinkedList<T>): unit { }
