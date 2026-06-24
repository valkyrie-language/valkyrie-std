namespace std.adaptor.clr.collections;

using std.collections;

[host_provider(std::collections::Queue::new)]
[inline(always)]
private micro queue_new<T>(): Queue<T> {
    return __queue_clr_new::<T>()
}

[host_provider(std::collections::Queue::enqueue)]
[inline(always)]
private micro queue_enqueue<T>(queue: Queue<T>, value: T): unit {
    __queue_clr_enqueue(queue, value)
}

[host_provider(std::collections::Queue::dequeue), inline(always)]
private micro queue_dequeue<T>(queue: Queue<T>): Option<T> {
    if __queue_clr_length(queue) == 0 {
        return None
    }

    return Some(__queue_clr_dequeue(queue))
}

[host_provider(std::collections::Queue::peek)]
[inline(always)]
private micro queue_peek<T>(queue: Queue<T>): Option<T> {
    if __queue_clr_length(queue) == 0 {
        return None
    }

    return Some(__queue_clr_peek(queue))
}

[host_provider(std::collections::Queue::length)]
[inline(always)]
private micro queue_length<T>(queue: Queue<T>): usize {
    return __queue_clr_length(queue)
}

[host_provider(std::collections::Queue::clear)]
[inline(always)]
private micro queue_clear<T>(queue: Queue<T>): unit {
    __queue_clr_clear(queue)
}

[clr("System.Collections", "System.Collections.Generic.Queue`1", ".ctor")]
private micro __queue_clr_new<T>(): Queue<T> { }

[clr("System.Collections", "System.Collections.Generic.Queue`1", "Enqueue")]
private micro __queue_clr_enqueue<T>(queue: Queue<T>, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.Queue`1", "Dequeue")]
private micro __queue_clr_dequeue<T>(queue: Queue<T>): T { }

[clr("System.Collections", "System.Collections.Generic.Queue`1", "Peek"), pure]
private micro __queue_clr_peek<T>(queue: Queue<T>): T { }

[clr("System.Collections", "System.Collections.Generic.Queue`1", "get_Count"), pure]
private micro __queue_clr_length<T>(queue: Queue<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.Queue`1", "Clear")]
private micro __queue_clr_clear<T>(queue: Queue<T>): unit { }
