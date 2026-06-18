namespace std.collections;

# std.collections: Deque - 双端队列

[clr("System.Collections", "System.Collections.Generic.LinkedList`1")]
[jvm("java.util.ArrayDeque")]
class Deque<T> {
    data: List<T>
}

imply Deque<T> {
    micro new(): Self {
        <% match arch %>
            <% case "clr" %>
        return __deque_clr_new::<T>()
            <% case "jvm" %>
        return __deque_jvm_new::<T>()
            <% else %>
        return Self { data: ArrayList::new(0) }
        <% end match %>
    }

    micro push_front(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __deque_clr_add_first(self, value)
            <% case "jvm" %>
        __deque_jvm_add_first(self, value)
            <% else %>
        self.data.insert(0, value)
        <% end match %>
    }

    micro push_back(mut self, value: T): unit {
        <% match arch %>
            <% case "clr" %>
        __deque_clr_add_last(self, value)
            <% case "jvm" %>
        __deque_jvm_add_last(self, value)
            <% else %>
        self.data.push(value)
        <% end match %>
    }

    micro pop_front(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        let node: any = __deque_clr_first_node::<T>(self)
        let value: T = __deque_clr_node_value::<T>(node)
        __deque_clr_remove_first(self)
        return Some(value)
            <% case "jvm" %>
        return Some(__deque_jvm_remove_first(self))
            <% else %>
        return self.data.remove(0)
        <% end match %>
    }

    micro pop_back(mut self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        let node: any = __deque_clr_last_node::<T>(self)
        let value: T = __deque_clr_node_value::<T>(node)
        __deque_clr_remove_last(self)
        return Some(value)
            <% case "jvm" %>
        return Some(__deque_jvm_remove_last(self))
            <% else %>
        return self.data.pop()
        <% end match %>
    }

    micro peek_front(self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__deque_clr_node_value::<T>(__deque_clr_first_node::<T>(self)))
            <% case "jvm" %>
        return Some(__deque_jvm_peek_first(self))
            <% else %>
        return self.data.first()
        <% end match %>
    }

    micro peek_back(self): Option<T> {
        if self.is_empty() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
        return Some(__deque_clr_node_value::<T>(__deque_clr_last_node::<T>(self)))
            <% case "jvm" %>
        return Some(__deque_jvm_peek_last(self))
            <% else %>
        return self.data.last()
        <% end match %>
    }

    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
        return __deque_clr_length(self)
            <% case "jvm" %>
        return __deque_jvm_length(self)
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
        __deque_clr_clear(self)
            <% case "jvm" %>
        __deque_jvm_clear(self)
            <% else %>
        self.data.clear()
        <% end match %>
    }

    micro iter(mut self, f: micro(T) -> unit): unit {
        let length: usize = self.length()
        let mut cursor: usize = 0
        while cursor < length {
            let value: T = self.pop_front().unwrap()
            f(value)
            self.push_back(value)
            cursor = cursor + 1
        }
    }
}

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", ".ctor")]
private micro __deque_clr_new<T>(): Deque<T> { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddFirst")]
private micro __deque_clr_add_first<T>(deque: Deque<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "AddLast")]
private micro __deque_clr_add_last<T>(deque: Deque<T>, value: T): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveFirst")]
private micro __deque_clr_remove_first<T>(deque: Deque<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "RemoveLast")]
private micro __deque_clr_remove_last<T>(deque: Deque<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_First"), pure]
private micro __deque_clr_first_node<T>(deque: Deque<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Last"), pure]
private micro __deque_clr_last_node<T>(deque: Deque<T>): any { }

[clr("System.Collections", "System.Collections.Generic.LinkedListNode`1", "get_Value"), pure]
private micro __deque_clr_node_value<T>(node: any): T { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "get_Count"), pure]
private micro __deque_clr_length<T>(deque: Deque<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.LinkedList`1", "Clear")]
private micro __deque_clr_clear<T>(deque: Deque<T>): unit { }

[jvm("java.util.ArrayDeque", "<init>")]
private micro __deque_jvm_new<T>(): Deque<T> { }

[jvm("java.util.ArrayDeque", "addFirst")]
private micro __deque_jvm_add_first<T>(deque: Deque<T>, value: T): unit { }

[jvm("java.util.ArrayDeque", "addLast")]
private micro __deque_jvm_add_last<T>(deque: Deque<T>, value: T): unit { }

[jvm("java.util.ArrayDeque", "removeFirst")]
private micro __deque_jvm_remove_first<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "removeLast")]
private micro __deque_jvm_remove_last<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "peekFirst"), pure]
private micro __deque_jvm_peek_first<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "peekLast"), pure]
private micro __deque_jvm_peek_last<T>(deque: Deque<T>): T { }

[jvm("java.util.ArrayDeque", "size"), pure]
private micro __deque_jvm_length<T>(deque: Deque<T>): usize { }

[jvm("java.util.ArrayDeque", "clear")]
private micro __deque_jvm_clear<T>(deque: Deque<T>): unit { }


