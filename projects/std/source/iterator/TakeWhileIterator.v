<% match arch %>
<% case "clr" %>
namespace std.iterator;
# CLR: function-valued iterator adapters deferred (field call → DynamicInvoke).
<% else %>
namespace std.iterator;

structure TakeWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _done: bool
}

imply TakeWhileIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        if self._done {
            return false
        }
        return self._iter.has_next()
    }

    micro next(mut self): Option<T> {
        if self._done {
            return option_none::<Item>()
        }

        if !self._iter.has_next() {
            return option_none::<Item>()
        }

        let item: T = self._iter.next().unwrap()
        if self._predicate(item) {
            return Some(item)
        }

        self._done = true
        return option_none::<Item>()
    }
}

<% end %>