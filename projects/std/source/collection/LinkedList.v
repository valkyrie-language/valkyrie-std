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
    micro new() -> Self {
        <% match arch %>
            <% case "clr" %>
        return __linked_list_clr_new::<T>()
            <% case "jvm" %>
        return __linked_list_jvm_new::<T>()
            <% else %>
        return Self {
            _head: None,
            _tail: None,
            _length: 0,
        }
        <% end match %>
    }

    micro length(self) -> usize {
        <% match arch %>
            <% case "clr" %>
        return __linked_list_clr_length(self)
            <% case "jvm" %>
        return __linked_list_jvm_length(self)
            <% else %>
        return self._length
        <% end match %>
    }

    micro is_empty(self) -> bool {
        return self.length() == 0
    }

    micro push_front(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __linked_list_clr_add_first(self, value)
            <% case "jvm" %>
        __linked_list_jvm_add_first(self, value)
            <% else %>
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
        <% end match %>
    }

    micro push_back(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __linked_list_clr_add_last(self, value)
            <% case "jvm" %>
        __linked_list_jvm_add_last(self, value)
            <% else %>
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
        <% end match %>
    }

    micro pop_front(mut self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        let node: any = __linked_list_clr_first_node::<T>(self)
        let value: T = __linked_list_clr_node_value::<T>(node)
        __linked_list_clr_remove_first(self)
        return Some(value)
            <% case "jvm" %>
        return Some(__linked_list_jvm_remove_first(self))
            <% else %>
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
        <% end match %>
    }

    micro pop_back(mut self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        let node: any = __linked_list_clr_last_node::<T>(self)
        let value: T = __linked_list_clr_node_value::<T>(node)
        __linked_list_clr_remove_last(self)
        return Some(value)
            <% case "jvm" %>
        return Some(__linked_list_jvm_remove_last(self))
            <% else %>
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
        <% end match %>
    }

    micro peek_front(self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__linked_list_clr_node_value::<T>(__linked_list_clr_first_node::<T>(self)))
            <% case "jvm" %>
        return Some(__linked_list_jvm_get_first(self))
            <% else %>
        return Some(self._head.unwrap().value)
        <% end match %>
    }

    micro peek_back(self) -> Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__linked_list_clr_node_value::<T>(__linked_list_clr_last_node::<T>(self)))
            <% case "jvm" %>
        return Some(__linked_list_jvm_get_last(self))
            <% else %>
        return Some(self._tail.unwrap().value)
        <% end match %>
    }

    micro first(self) -> Option<T> {
        return self.peek_front()
    }

    micro last(self) -> Option<T> {
        return self.peek_back()
    }

    micro clear(mut self): unit {
        <% match arch %>
            <% case "clr" %>
        __linked_list_clr_clear(self)
            <% case "jvm" %>
        __linked_list_jvm_clear(self)
            <% else %>
        self._head = None
        self._tail = None
        self._length = 0
        <% end match %>
    }

    micro contains(self, value: T) -> bool {
        <% match arch %>
            <% case "clr" %>
        return __linked_list_clr_contains(self, value)
            <% case "jvm" %>
        return __linked_list_jvm_contains(self, value)
            <% else %>
        let mut current: Option<LinkedListNode<T>> = self._head
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            if node.value == value {
                return true
            }

            current = node.next
        }

        return false
        <% end match %>
    }

    micro iter(self, f: micro(T) -> unit): unit {
        <% match arch %>
            <% case "clr" %>
        let length: usize = self.length()
        if length == 0 {
            return
        }

        let mut node: any = __linked_list_clr_first_node::<T>(self)
        let mut cursor: usize = 0
        while cursor < length {
            f(__linked_list_clr_node_value::<T>(node))
            node = __linked_list_clr_node_next(node)
            cursor = cursor + 1
        }
            <% case "jvm" %>
        let length: usize = self.length()
        let mut cursor: usize = 0
        while cursor < length {
            f(__linked_list_jvm_get(self, cursor))
            cursor = cursor + 1
        }
            <% else %>
        let mut current: Option<LinkedListNode<T>> = self._head
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            f(node.value)
            current = node.next
        }
        <% end match %>
    }

    micro iter_reverse(self, f: micro(T) -> unit): unit {
        <% match arch %>
            <% case "clr" %>
        let length: usize = self.length()
        if length == 0 {
            return
        }

        let mut node: any = __linked_list_clr_last_node::<T>(self)
        let mut cursor: usize = 0
        while cursor < length {
            f(__linked_list_clr_node_value::<T>(node))
            node = __linked_list_clr_node_prev(node)
            cursor = cursor + 1
        }
            <% case "jvm" %>
        let length: usize = self.length()
        let mut cursor: usize = length
        while cursor > 0 {
            cursor = cursor - 1
            f(__linked_list_jvm_get(self, cursor))
        }
            <% else %>
        let mut current: Option<LinkedListNode<T>> = self._tail
        while current.is_some() {
            let node: LinkedListNode<T> = current.unwrap()
            f(node.value)
            current = node.prev
        }
        <% end match %>
    }
}

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", ".ctor")]
private micro __linked_list_clr_new<T>(): LinkedList<T> { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddFirst")]
private micro __linked_list_clr_add_first<T>(list: LinkedList<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddLast")]
private micro __linked_list_clr_add_last<T>(list: LinkedList<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveFirst")]
private micro __linked_list_clr_remove_first<T>(list: LinkedList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveLast")]
private micro __linked_list_clr_remove_last<T>(list: LinkedList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_First"), pure]
private micro __linked_list_clr_first_node<T>(list: LinkedList<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Last"), pure]
private micro __linked_list_clr_last_node<T>(list: LinkedList<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Value"), pure]
private micro __linked_list_clr_node_value<T>(node: any): T { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Next"), pure]
private micro __linked_list_clr_node_next(node: any): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Previous"), pure]
private micro __linked_list_clr_node_prev(node: any): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Contains"), pure]
private micro __linked_list_clr_contains<T>(list: LinkedList<T>, value: T): bool { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Count"), pure]
private micro __linked_list_clr_length<T>(list: LinkedList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Clear")]
private micro __linked_list_clr_clear<T>(list: LinkedList<T>): unit { }

[jvm("java.util.LinkedList", "<init>")]
private micro __linked_list_jvm_new<T>(): LinkedList<T> { }

[jvm("java.util.LinkedList", "addFirst")]
private micro __linked_list_jvm_add_first<T>(list: LinkedList<T>, value: T): unit { }

[jvm("java.util.LinkedList", "addLast")]
private micro __linked_list_jvm_add_last<T>(list: LinkedList<T>, value: T): unit { }

[jvm("java.util.LinkedList", "removeFirst")]
private micro __linked_list_jvm_remove_first<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "removeLast")]
private micro __linked_list_jvm_remove_last<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "getFirst"), pure]
private micro __linked_list_jvm_get_first<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "getLast"), pure]
private micro __linked_list_jvm_get_last<T>(list: LinkedList<T>): T { }

[jvm("java.util.LinkedList", "contains"), pure]
private micro __linked_list_jvm_contains<T>(list: LinkedList<T>, value: T): bool { }

[jvm("java.util.LinkedList", "size"), pure]
private micro __linked_list_jvm_length<T>(list: LinkedList<T>): usize { }

[jvm("java.util.LinkedList", "clear")]
private micro __linked_list_jvm_clear<T>(list: LinkedList<T>): unit { }

[jvm("java.util.LinkedList", "get"), pure]
private micro __linked_list_jvm_get<T>(list: LinkedList<T>, index: usize): T { }
