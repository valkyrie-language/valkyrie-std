<% match arch %>
<% case "clr" %>
namespace std.iterator;
# CLR: function-valued iterator adapters deferred (field call → DynamicInvoke).
<% else %>
namespace std.iterator;

structure SkipWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _skipped: bool
}

imply SkipWhileIterator<T, I>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._iter.has_next()
    }

    micro next(mut self): Option<T> {
        if !self._skipped {
            while self._iter.has_next() {
                let item: T = self._iter.next().unwrap()
                if !self._predicate(item) {
                    self._skipped = true
                    return Some(item)
                }
            }

            self._skipped = true
            return option_none::<Item>()
        }

        return self._iter.next()
    }
}

<% end %>