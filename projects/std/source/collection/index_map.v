# std.collections: IndexMap - 保持插入顺序的映射

namespace std.collections;

class IndexMap<K, V> {
    keys: List<K>
    values: List<V>
}

imply IndexMap<K, V>: Map<K, V> {
    micro get(self, key: K): Option<V> {
        let idx: Option<usize> = self.find_index(key)
        if idx.is_some() {
            return self.values.get(idx.unwrap())
        }
        return None
    }
    micro insert(mut self, key: K, value: V): Option<V> {
        let idx: Option<usize> = self.find_index(key)
        if idx.is_some() {
            let old: V = self.values.get(idx.unwrap()).unwrap()
            self.values.set(idx.unwrap(), value)
            return Some(old)
        self.keys.push(key)
        self.values.push(value)
        return None
    }
    micro remove(mut self, key: K): Option<V> {
        let idx: Option<usize> = self.find_index(key)
        if idx.is_some() {
            self.keys.remove(idx.unwrap())
            return self.values.remove(idx.unwrap())
        }
        return None
    }
    micro contains_key(self, key: K): bool {
        return self.find_index(key).is_some()
    }
    micro keys(self): List<K> {
        return self.keys
    }
    micro values(self): List<V> {
        return self.values
    }
    micro length(self): usize {
        return self.keys.len()
    }
    micro is_empty(self): bool {
        return self.keys.is_empty()
    }
    micro clear(mut self) -> unit {
        self.keys.clear()
        self.values.clear()
    }
    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        let mut i: usize = 0
        while i < self.keys.len() {
            f(self.keys.get(i).unwrap(), self.values.get(i).unwrap())
            i = i + 1
        }
    }
}

imply IndexMap<K, V> {
    micro new(): Self {
        return Self { keys: ArrayList.new(0), values: ArrayList.new(0) }
    }
    micro find_index(self, key: K): Option<usize> {
        let mut i: usize = 0
        while i < self.keys.len() {
            if self.keys.get(i).unwrap() == key {
                return Some(i)
            }
            i = i + 1
        }
        return None
    }
}
