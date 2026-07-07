namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::Queue::new)]
[inline(always)]
private micro queue_new<T>(): Queue<T> {
    return __queue_jvm_new::<T>()
}

[host_provider(std::collections::Queue::enqueue)]
[inline(always)]
private micro queue_enqueue<T>(queue: Queue<T>, value: T): unit {
    __queue_jvm_enqueue(queue, value)
}

[host_provider(std::collections::Queue::dequeue)]
[inline(always)]
private micro queue_dequeue<T>(queue: Queue<T>): Option<T> {
    if __queue_jvm_length(queue) == 0 {
        return None
    }

    return Some(__queue_jvm_dequeue(queue))
}

[host_provider(std::collections::Queue::peek)]
[inline(always)]
private micro queue_peek<T>(queue: Queue<T>): Option<T> {
    if __queue_jvm_length(queue) == 0 {
        return None
    }

    return Some(__queue_jvm_peek(queue))
}

[host_provider(std::collections::Queue::length)]
[inline(always)]
private micro queue_length<T>(queue: Queue<T>): usize {
    return __queue_jvm_length(queue)
}

[host_provider(std::collections::Queue::clear)]
[inline(always)]
private micro queue_clear<T>(queue: Queue<T>): unit {
    __queue_jvm_clear(queue)
}

[jvm("java.util.ArrayDeque", "<init>")]
private micro __queue_jvm_new<T>(): Queue<T> { }

[jvm("java.util.ArrayDeque", "addLast")]
private micro __queue_jvm_enqueue<T>(queue: Queue<T>, value: T): unit { }

[jvm("java.util.ArrayDeque", "removeFirst")]
private micro __queue_jvm_dequeue<T>(queue: Queue<T>): T { }

[jvm("java.util.ArrayDeque", "peekFirst"), pure]
private micro __queue_jvm_peek<T>(queue: Queue<T>): T { }

[jvm("java.util.ArrayDeque", "size"), pure]
private micro __queue_jvm_length<T>(queue: Queue<T>): usize { }

[jvm("java.util.ArrayDeque", "clear")]
private micro __queue_jvm_clear<T>(queue: Queue<T>): unit { }
