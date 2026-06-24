namespace std.adaptor.jvm.collections;

using std.collections;

[host_provider(std::collections::PriorityQueue::new)]
[inline(always)]
private micro priority_queue_new<T>(): PriorityQueue<T> {
    return __priority_queue_jvm_new::<T>()
}

[host_provider(std::collections::PriorityQueue::push)]
[inline(always)]
private micro priority_queue_push<T>(queue: PriorityQueue<T>, value: T): unit {
    __priority_queue_jvm_add(queue, value)
}

[host_provider(std::collections::PriorityQueue::pop)]
[inline(always)]
private micro priority_queue_pop<T>(queue: PriorityQueue<T>): Option<T> {
    if __priority_queue_jvm_length(queue) == 0 {
        return None
    }

    return Some(__priority_queue_jvm_poll(queue))
}

[host_provider(std::collections::PriorityQueue::peek)]
[inline(always)]
private micro priority_queue_peek<T>(queue: PriorityQueue<T>): Option<T> {
    if __priority_queue_jvm_length(queue) == 0 {
        return None
    }

    return Some(__priority_queue_jvm_peek(queue))
}

[host_provider(std::collections::PriorityQueue::length)]
[inline(always)]
private micro priority_queue_length<T>(queue: PriorityQueue<T>): usize {
    return __priority_queue_jvm_length(queue)
}

[host_provider(std::collections::PriorityQueue::clear)]
[inline(always)]
private micro priority_queue_clear<T>(queue: PriorityQueue<T>): unit {
    __priority_queue_jvm_clear(queue)
}

[jvm("java.util.PriorityQueue", "<init>")]
private micro __priority_queue_jvm_new<T>(): PriorityQueue<T> { }

[jvm("java.util.PriorityQueue", "add")]
private micro __priority_queue_jvm_add<T>(queue: PriorityQueue<T>, value: T): bool { }

[jvm("java.util.PriorityQueue", "poll")]
private micro __priority_queue_jvm_poll<T>(queue: PriorityQueue<T>): T { }

[jvm("java.util.PriorityQueue", "peek"), pure]
private micro __priority_queue_jvm_peek<T>(queue: PriorityQueue<T>): T { }

[jvm("java.util.PriorityQueue", "size"), pure]
private micro __priority_queue_jvm_length<T>(queue: PriorityQueue<T>): usize { }

[jvm("java.util.PriorityQueue", "clear")]
private micro __priority_queue_jvm_clear<T>(queue: PriorityQueue<T>): unit { }
