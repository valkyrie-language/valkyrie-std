namespace std.collection;

[clr("System.Runtime", "System.Array")]
[jvm("java.lang.Object[]")]
class Array<T> {}

imply Array<T> {
    micro length(self): usize {
        <% match arch %>
            <% case "clr" %>
            return __array_clr_length::<T>(self)
            <% case "jvm" %>
            return __array_jvm_length::<T>(self)
            <% else %>
            return __array_nyar_length::<T>(self)
        <% end match %>
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro get(self, index: usize): Option<T> {
        if index >= self.length() {
            return None
        }

        <% match arch %>
            <% case "clr" %>
            return Some(__array_clr_get::<T>(self, index))
            <% case "jvm" %>
            return Some(__array_jvm_get::<T>(self, index))
            <% else %>
            return Some(self[index])
        <% end match %>
    }

    micro first(self): Option<T> {
        return self.get(0)
    }

    micro last(self): Option<T> {
        let item_count: usize = self.length()
        if item_count == 0 {
            return None
        }

        return self.get(item_count - 1)
    }

    micro contains(self, value: T): bool {
        let mut i: usize = 0
        while i < self.length() {
            if self.get(i).unwrap() == value {
                return true
            }

            i = i + 1
        }

        return false
    }
}

structure ArrayIterator<T> {
    _array: Array<T>
    _index: usize
}

imply Array<T>: std.iterator.IntoIterator {
    type Item = T;
    type Iter = ArrayIterator<T>;

    micro into_iterator(self): ArrayIterator<T> {
        return ArrayIterator<T> {
            _array: self,
            _index: 0,
        }
    }
}

imply Array<T>: std.iterator.FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std.iterator.Iterator<Item = T>
    {
        let mut result: [T] = []
        loop item in iter {
            push(result, item)
        }

        return result
    }
}

imply ArrayIterator<T>: std.iterator.Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index < self._array.length()
    }

    micro next(mut self): Option<T> {
        if !self.has_next() {
            return None
        }

        let value: T = self._array.get(self._index).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}

[clr("System.Runtime", "System.Array", "get_Length"), pure]
private micro __array_clr_length<T>(array: Array<T>): usize { }

[clr("System.Runtime", "System.Array", "GetValue"), pure]
private micro __array_clr_get<T>(array: Array<T>, index: usize): T { }

[jvm("java.lang.reflect.Array", "getLength"), pure]
private micro __array_jvm_length<T>(array: Array<T>): usize { }

[jvm("java.lang.reflect.Array", "get"), pure]
private micro __array_jvm_get<T>(array: Array<T>, index: usize): T { }

[vm("__nyar_length")]
private micro __array_nyar_length<T>(array: Array<T>): usize { }
