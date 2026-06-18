namespace std.collections;

# std.collections: PriorityQueue - 优先队列（最小堆）

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2")]
[jvm("java.util.PriorityQueue")]
class PriorityQueue<T> {
    _impl: BinaryHeap<T>
}

imply PriorityQueue<T> {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
        return __priority_queue_clr_new::<T>()
            <% case "jvm" %>
        return __priority_queue_jvm_new::<T>()
            <% else %>
        return Self {
            _impl: BinaryHeap::new(),
        }
        <% end match %>
    }

    micro push(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __priority_queue_clr_enqueue(self, value, value)
            <% case "jvm" %>
        __priority_queue_jvm_add(self, value)
            <% else %>
        self._impl.push(value)
        <% end match %>
    }

    micro pop(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__priority_queue_clr_dequeue(self))
            <% case "jvm" %>
        return Some(__priority_queue_jvm_poll(self))
            <% else %>
        return self._impl.pop()
        <% end match %>
    }

    micro peek(self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__priority_queue_clr_peek(self))
            <% case "jvm" %>
        return Some(__priority_queue_jvm_peek(self))
            <% else %>
        return self._impl.peek()
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
        return __priority_queue_clr_length(self)
            <% case "jvm" %>
        return __priority_queue_jvm_length(self)
            <% else %>
        return self._impl.length()
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self): unit {
        <% match arch %>
            <% case "clr" %>
        __priority_queue_clr_clear(self)
            <% case "jvm" %>
        __priority_queue_jvm_clear(self)
            <% else %>
        self._impl.clear()
        <% end match %>
    }
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



