namespace std.collections;

# std.collections: Deque - 双端队列

[clr("System.Collections", "System.Collections.Generic.LinkedList`1")]
[jvm("java.util.ArrayDeque")]
class Deque<T> {
    data: List<T>
}

imply Deque<T> {
    [host_contract]
    micro new(): Self {
        return Self { data: ArrayList::new(0) }
    }

    [host_contract]
    micro push_front(mut self, value: T): unit {
        self.data.insert(1, value)
    }

    [host_contract]
    micro push_back(mut self, value: T): unit {
        self.data.push(value)
    }

    [host_contract]
    micro pop_front(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.remove(1)
    }

    [host_contract]
    micro pop_back(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.pop()
    }

    [host_contract]
    micro peek_front(self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.first()
    }

    [host_contract]
    micro peek_back(self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self.data.last()
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
            let value: T = self.pop_front().unwrap()
            f(value)
            self.push_back(value)
        }
    }
}
