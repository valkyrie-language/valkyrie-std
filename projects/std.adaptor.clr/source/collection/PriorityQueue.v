namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::PriorityQueue::new)]
[inline(always)]
private micro priority_queue_new<T>(): PriorityQueue<T> {
    return __priority_queue_clr_new::<T>()
}

[host_provider(std::collections::PriorityQueue::push)]
[inline(always)]
private micro priority_queue_push<T>(queue: PriorityQueue<T>, value: T): unit {
    __priority_queue_clr_enqueue(queue, value, value)
}

[host_provider(std::collections::PriorityQueue::pop)]
[inline(always)]
private micro priority_queue_pop<T>(queue: PriorityQueue<T>): Option<T> {
    if __priority_queue_clr_length(queue) == 0 {
        return None
    }

    return Some(__priority_queue_clr_dequeue(queue))
}

[host_provider(std::collections::PriorityQueue::peek)]
[inline(always)]
private micro priority_queue_peek<T>(queue: PriorityQueue<T>): Option<T> {
    if __priority_queue_clr_length(queue) == 0 {
        return None
    }

    return Some(__priority_queue_clr_peek(queue))
}

[host_provider(std::collections::PriorityQueue::length)]
[inline(always)]
private micro priority_queue_length<T>(queue: PriorityQueue<T>): usize {
    return __priority_queue_clr_length(queue)
}

[host_provider(std::collections::PriorityQueue::clear)]
[inline(always)]
private micro priority_queue_clear<T>(queue: PriorityQueue<T>): unit {
    __priority_queue_clr_clear(queue)
}

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", ".ctor")]
private micro __priority_queue_clr_new<T>(): PriorityQueue<T> { }

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", "Enqueue")]
private micro __priority_queue_clr_enqueue<T>(queue: PriorityQueue<T>, element: T, priority: T): unit { }

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", "Dequeue")]
private micro __priority_queue_clr_dequeue<T>(queue: PriorityQueue<T>): T { }

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", "Peek"), pure]
private micro __priority_queue_clr_peek<T>(queue: PriorityQueue<T>): T { }

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", "get_Count"), pure]
private micro __priority_queue_clr_length<T>(queue: PriorityQueue<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2", "Clear")]
private micro __priority_queue_clr_clear<T>(queue: PriorityQueue<T>): unit { }
