namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::Deque::new)]
[inline(always)]
private micro deque_new<T>(): Deque<T> {
    return __deque_clr_new::<T>()
}

[host_provider(std::collections::Deque::push_front)]
[inline(always)]
private micro deque_push_front<T>(deque: Deque<T>, value: T): unit {
    __deque_clr_add_first(deque, value)
}

[host_provider(std::collections::Deque::push_back)]
[inline(always)]
private micro deque_push_back<T>(deque: Deque<T>, value: T): unit {
    __deque_clr_add_last(deque, value)
}

[host_provider(std::collections::Deque::pop_front)]
[inline(always)]
private micro deque_pop_front<T>(deque: Deque<T>): Option<T> {
    if __deque_clr_length(deque) == 0 {
        return None
    }

    let node: any = __deque_clr_first_node::<T>(deque)
    let value: T = __deque_clr_node_value::<T>(node)
    __deque_clr_remove_first(deque)
    return Some(value)
}

[host_provider(std::collections::Deque::pop_back)]
[inline(always)]
private micro deque_pop_back<T>(deque: Deque<T>): Option<T> {
    if __deque_clr_length(deque) == 0 {
        return None
    }

    let node: any = __deque_clr_last_node::<T>(deque)
    let value: T = __deque_clr_node_value::<T>(node)
    __deque_clr_remove_last(deque)
    return Some(value)
}

[host_provider(std::collections::Deque::peek_front)]
[inline(always)]
private micro deque_peek_front<T>(deque: Deque<T>): Option<T> {
    if __deque_clr_length(deque) == 0 {
        return None
    }

    return Some(__deque_clr_node_value::<T>(__deque_clr_first_node::<T>(deque)))
}

[host_provider(std::collections::Deque::peek_back)]
[inline(always)]
private micro deque_peek_back<T>(deque: Deque<T>): Option<T> {
    if __deque_clr_length(deque) == 0 {
        return None
    }

    return Some(__deque_clr_node_value::<T>(__deque_clr_last_node::<T>(deque)))
}

[host_provider(std::collections::Deque::length)]
[inline(always)]
private micro deque_length<T>(deque: Deque<T>): usize {
    return __deque_clr_length(deque)
}

[host_provider(std::collections::Deque::clear)]
[inline(always)]
private micro deque_clear<T>(deque: Deque<T>): unit {
    __deque_clr_clear(deque)
}

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", ".ctor")]
private micro __deque_clr_new<T>(): Deque<T> { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddFirst")]
private micro __deque_clr_add_first<T>(deque: Deque<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddLast")]
private micro __deque_clr_add_last<T>(deque: Deque<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveFirst")]
private micro __deque_clr_remove_first<T>(deque: Deque<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveLast")]
private micro __deque_clr_remove_last<T>(deque: Deque<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_First"), pure]
private micro __deque_clr_first_node<T>(deque: Deque<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Last"), pure]
private micro __deque_clr_last_node<T>(deque: Deque<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Value"), pure]
private micro __deque_clr_node_value<T>(node: any): T { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Count"), pure]
private micro __deque_clr_length<T>(deque: Deque<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Clear")]
private micro __deque_clr_clear<T>(deque: Deque<T>): unit { }
