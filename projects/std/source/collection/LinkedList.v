namespace std.collections;

class LinkedListNode<T> {
    value: T
    next: Option<LinkedListNode<T>>
    prev: Option<LinkedListNode<T>>
}

[clr("System.Collections", "System.Collections.Generic.LinkedList`1")]
[jvm("java.util.LinkedList")]
class LinkedList<T> {
    _head: Option<LinkedListNode<T>>
    _tail: Option<LinkedListNode<T>>
    _length: usize
}

imply LinkedList<T> {
    [host_contract]
    micro new() -> Self {
        return Self {
            _head: None,
            _tail: None,
            _length: 0,
        }
    }

    [host_contract]
    micro length(self) -> usize {
        return self._length
    }

    micro is_empty(self) -> bool {
        return self.length() == 0
    }

    [host_contract]
    micro push_front(mut self, value: T): unit {
        let node: LinkedListNode<T> = LinkedListNode {
            value: value,
            next: self._head,
            prev: None,
        }

        if self._head.is_some() {
            self._head.unwrap().prev = Some(node)
        }
        else {
            self._tail = Some(node)
        }

        self._head = Some(node)
        self._length = self._length + 1
    }

    [host_contract]
    micro push_back(mut self, value: T): unit {
        let node: LinkedListNode<T> = LinkedListNode {
            value: value,
            next: None,
            prev: self._tail,
        }

        if self._tail.is_some() {
            self._tail.unwrap().next = Some(node)
        }
        else {
            self._head = Some(node)
        }

        self._tail = Some(node)
        self._length = self._length + 1
    }

    [host_contract]
    micro pop_front(mut self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        let node: LinkedListNode<T> = self._head.unwrap()
        self._head = node.next

        if self._head.is_some() {
            self._head.unwrap().prev = None
        }
        else {
            self._tail = None
        }

        self._length = self._length - 1
        return Some(node.value)
    }

    [host_contract]
    micro pop_back(mut self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        let node: LinkedListNode<T> = self._tail.unwrap()
        self._tail = node.prev

        if self._tail.is_some() {
            self._tail.unwrap().next = None
        }
        else {
            self._head = None
        }

        self._length = self._length - 1
        return Some(node.value)
    }

    [host_contract]
    micro peek_front(self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        return Some(self._head.unwrap().value)
    }

    [host_contract]
    micro peek_back(self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        return Some(self._tail.unwrap().value)
    }

    micro first(self) -> Option<T> {
        return self.peek_front()
    }

    micro last(self) -> Option<T> {
        return self.peek_back()
    }

    [host_contract]
    micro clear(mut self): unit {
        self._head = None
        self._tail = None
        self._length = 0
    }

    [host_contract]
    micro contains(self, value: T) -> bool {
        let mut current: Option<LinkedListNode<T>> = self._head
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            if node.value == value {
                return true
            }

            current = node.next
        }

        return false
    }

    [host_contract]
    micro iter(self, f: micro(T) -> unit): unit {
        let mut current: Option<LinkedListNode<T>> = self._head
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            f(node.value)
            current = node.next
        }
    }

    [host_contract]
    micro iter_reverse(self, f: micro(T) -> unit): unit {
        let mut current: Option<LinkedListNode<T>> = self._tail
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            f(node.value)
            current = node.prev
        }
    }
}
