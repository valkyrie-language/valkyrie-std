namespace std.collections;

# std.collections: PriorityQueue - 优先队列（最小堆）

[clr("System.Collections", "System.Collections.Generic.PriorityQueue`2")]
[jvm("java.util.PriorityQueue")]
class PriorityQueue<T> {
    _impl: BinaryHeap<T>
}

imply PriorityQueue<T> {
    [host_contract]
    micro new(): Self {
        return Self {
            _impl: BinaryHeap::new(),
        }
    }

    [host_contract]
    micro push(mut self, value: T): unit {
        self._impl.push(value)
    }

    [host_contract]
    micro pop(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self._impl.pop()
    }

    [host_contract]
    micro peek(self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self._impl.peek()
    }

    [host_contract]
    micro length(self): usize {
        return self._impl.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self): unit {
        self._impl.clear()
    }
}
