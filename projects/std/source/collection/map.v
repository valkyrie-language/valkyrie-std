namespace std.collections;

⍝ std.collections: Map trait
trait Map<K, V> {
    micro get(self, key: K) -> Option<V>;
    micro set(mut self, key: V, value: V) -> Option<V>;
    micro insert(mut self, key: K, value: V) -> unit {
        self.set(key, value);
    }
    micro remove(mut self, key: K) -> Option<V>;
    micro contains(self, key: K) -> bool;
    micro keys(self) -> std::iterator::Iterator<Item=K>;
    micro values(self) -> std::iterator::Iterator<Item=V>;
    micro count(self) -> usize;
    micro is_empty(self) -> bool;
    micro clear(mut self) -> unit;
    micro iterator(self, f: micro(K, V) -> unit) -> unit;
}
