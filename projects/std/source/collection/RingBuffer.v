# std.collections: RingBuffer
namespace std.collections;

structure RingBuffer<T> {
    data: List<T>
    capacity: usize
    head: usize
    tail: usize
    count: usize
}

imply RingBuffer<T> {
    micro new(capacity: usize): Self {
        let mut data: List<T> = ArrayList::new(capacity)
        let mut i: usize = 0
        while i < capacity {
            data.push(T.default)
            i = i + 1
        }
        return Self { data: data, capacity: capacity, head: 0, tail: 0, count: 0 }
    }
    micro enqueue(mut self, value: T): bool {
        if self.count == self.capacity {
            return false
        }
        self.data.set(self.tail, value)
        self.tail = (self.tail + 1) % self.capacity
        self.count = self.count + 1
        return true
    }
    micro dequeue(mut self): Option<T> {
        if self.count == 0 {
            return None
        }
        let value: T = self.data.get(self.head).unwrap()
        self.head = (self.head + 1) % self.capacity
        self.count = self.count - 1
        return Some(value)
    }
    micro peek(self): Option<T> {
        if self.count == 0 {
            return None
        }
        return self.data.get(self.head)
    }
    micro length(self): usize {
        return self.count
    }
    micro is_empty(self): bool {
        return self.count == 0
    }
    micro is_full(self): bool {
        return self.count == self.capacity
    }
    micro clear(mut self) -> unit {
        self.head = 0
        self.tail = 0
        self.count = 0
    }
}
