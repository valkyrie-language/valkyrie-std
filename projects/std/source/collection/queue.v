namespace std.collections;

# std.collections: Queue - FIFO 队列

[clr("System.Collections", "System.Collections.Generic.Queue`1")]
[jvm("java.util.ArrayDeque")]
class Queue<T> {
    data: Deque<T>
}

imply Queue<T> {
    [host_contract]
    micro new(): Self {
        return Self { data: Deque::new() }
    }

    [host_contract]
    micro enqueue(mut self, value: T): unit {
        self.data.push(value)
    }

    [host_contract]
    micro dequeue(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.pop_front()
    }

    [host_contract]
    micro peek(self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.peek_front()
    }

    [host_contract]
    micro length(self): usize {
        return self.data.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self): unit {
        self.data.clear()
    }

    micro iter(mut self, f: micro(T) -> unit): unit {
        let length: usize = self.length()
        loop _ in 0..length {
            let value: T = self.dequeue().unwrap()
            f(value)
            self.enqueue(value)
        }
    }
}
