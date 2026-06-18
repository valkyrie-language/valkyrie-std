namespace std.collections;

# std.collections: Queue - FIFO 队列

[clr("System.Collections", "System.Collections.Generic.Queue`1")]
[jvm("java.util.ArrayDeque")]
class Queue<T> {
    data: Deque<T>
}

imply Queue<T> {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
        return __queue_clr_new::<T>()
            <% case "jvm" %>
        return __queue_jvm_new::<T>()
            <% else %>
        return Self { data: Deque::new() }
        <% end match %>
    }

    micro enqueue(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __queue_clr_enqueue(self, value)
            <% case "jvm" %>
        __queue_jvm_enqueue(self, value)
            <% else %>
        self.data.push(value)
        <% end match %>
    }

    micro dequeue(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__queue_clr_dequeue(self))
            <% case "jvm" %>
        return Some(__queue_jvm_dequeue(self))
            <% else %>
        return self.data.pop_front()
        <% end match %>
    }

    micro peek(self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__queue_clr_peek(self))
            <% case "jvm" %>
        return Some(__queue_jvm_peek(self))
            <% else %>
        return self.data.peek_front()
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
        return __queue_clr_length(self)
            <% case "jvm" %>
        return __queue_jvm_length(self)
            <% else %>
        return self.data.length()
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self): unit {
        <% match arch %>
            <% case "clr" %>
        __queue_clr_clear(self)
            <% case "jvm" %>
        __queue_jvm_clear(self)
            <% else %>
        self.data.clear()
        <% end match %>
    }

    micro iter(mut self, f: micro(T) -> unit): unit {
        let length: usize = self.length()
        let mut cursor: usize = 0
        while cursor < length {
            let value: T = self.dequeue().unwrap()
            f(value)
            self.enqueue(value)
            cursor = cursor + 1
        }
    }
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


