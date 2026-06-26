namespace std.collections;

structure SwissTableEntry<K, V> {
    key: K
    value: V
    hash: usize
}

class SwissTable<K, V> {
    _states: ArrayList<i32>
    _entries: ArrayList<Option<SwissTableEntry<K, V>>>
    _length: usize
    _used: usize
}

imply SwissTable<K, V> {
    micro new(capacity: usize): Self {
        let slot_count: usize = swiss_table_normalize_capacity(capacity)
        let mut states: ArrayList<i32> = ArrayList::new(slot_count)
        let mut entries: ArrayList<Option<SwissTableEntry<K, V>>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            entries.push(None)
            index = index + 1
        }

        return Self {
            _states: states,
            _entries: entries,
            _length: 0,
            _used: 0,
        }
    }

    micro get(self, key: K): Option<V> {
        let slot: Option<usize> = self.find_slot(key)
        if slot.is_none() {
            return None
        }

        let entry: SwissTableEntry<K, V> = self._entries.get(slot.unwrap() + 1).unwrap().unwrap()
        return Some(entry.value)
    }

    micro insert(mut self, key: K, value: V): Option<V> {
        if self.should_grow() {
            self.rehash(swiss_table_next_capacity(self._states.length()))
        }

        let key_hash: usize = key.hash()
        let slot: Option<usize> = self.find_insert_slot(key, key_hash)
        if slot.is_none() {
            self.rehash(swiss_table_next_capacity(self._states.length()))
            return self.insert(key, value)
        }

        let index: usize = slot.unwrap()
        let state: i32 = self._states.get(index + 1).unwrap()
        if state == 1 {
            let old: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
            self._entries.set(index + 1, Some(SwissTableEntry {
                key: key,
                value: value,
                hash: key_hash,
            }))
            return Some(old.value)
        }

        if state == 0 {
            self._used = self._used + 1
        }

        self._states.set(index + 1, 1)
        self._entries.set(index + 1, Some(SwissTableEntry {
            key: key,
            value: value,
            hash: key_hash,
        }))
        self._length = self._length + 1
        return None
    }

    micro remove(mut self, key: K): Option<V> {
        let slot: Option<usize> = self.find_slot(key)
        if slot.is_none() {
            return None
        }

        let index: usize = slot.unwrap()
        let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
        self._states.set(index + 1, 2)
        self._entries.set(index + 1, None)
        self._length = self._length - 1
        return Some(entry.value)
    }

    micro contains_key(self, key: K): bool {
        return self.find_slot(key).is_some()
    }

    micro keys(self): List<K> {
        let mut result: List<K> = ArrayList::new(self._length)
        let mut index: usize = 0
        while index < self._states.length() {
            if self._states.get(index + 1).unwrap() == 1 {
                let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
                result.push(entry.key)
            }

            index = index + 1
        }

        return result
    }

    micro values(self): List<V> {
        let mut result: List<V> = ArrayList::new(self._length)
        let mut index: usize = 0
        while index < self._states.length() {
            if self._states.get(index + 1).unwrap() == 1 {
                let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
                result.push(entry.value)
            }

            index = index + 1
        }

        return result
    }

    micro length(self): usize {
        return self._length
    }

    micro is_empty(self): bool {
        return self._length == 0
    }

    micro clear(mut self) -> unit {
        let slot_count: usize = self._states.length()
        let mut states: ArrayList<i32> = ArrayList::new(slot_count)
        let mut entries: ArrayList<Option<SwissTableEntry<K, V>>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            entries.push(None)
            index = index + 1
        }

        self._states = states
        self._entries = entries
        self._length = 0
        self._used = 0
    }

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        let mut index: usize = 0
        while index < self._states.length() {
            if self._states.get(index + 1).unwrap() == 1 {
                let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
                f(entry.key, entry.value)
            }

            index = index + 1
        }
    }

    micro find_slot(self, key: K): Option<usize> {
        let slot_count: usize = self._states.length()
        if slot_count == 0 {
            return None
        }

        let key_hash: usize = key.hash()
        let mut index: usize = key_hash % slot_count
        let mut probe: usize = 0
        while probe < slot_count {
            let state: i32 = self._states.get(index + 1).unwrap()
            if state == 0 {
                return None
            }

            if state == 1 {
                let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
                if entry.hash == key_hash && entry.key == key {
                    return Some(index)
                }
            }

            index = (index + 1) % slot_count
            probe = probe + 1
        }

        return None
    }

    micro find_insert_slot(self, key: K, key_hash: usize): Option<usize> {
        let slot_count: usize = self._states.length()
        let mut first_deleted: Option<usize> = None
        let mut index: usize = key_hash % slot_count
        let mut probe: usize = 0
        while probe < slot_count {
            let state: i32 = self._states.get(index + 1).unwrap()
            if state == 0 {
                if first_deleted.is_some() {
                    return first_deleted
                }

                return Some(index)
            }

            if state == 2 {
                if first_deleted.is_none() {
                    first_deleted = Some(index)
                }
            }

            if state == 1 {
                let entry: SwissTableEntry<K, V> = self._entries.get(index + 1).unwrap().unwrap()
                if entry.hash == key_hash && entry.key == key {
                    return Some(index)
                }
            }

            index = (index + 1) % slot_count
            probe = probe + 1
        }

        return first_deleted
    }

    micro should_grow(self): bool {
        let slot_count: usize = self._states.length()
        if slot_count == 0 {
            return true
        }

        return (self._used + 1) * 4 >= slot_count * 3
    }

    micro rehash(mut self, slot_count: usize): unit {
        let old_states: ArrayList<i32> = self._states
        let old_entries: ArrayList<Option<SwissTableEntry<K, V>>> = self._entries

        let mut states: ArrayList<i32> = ArrayList::new(slot_count)
        let mut entries: ArrayList<Option<SwissTableEntry<K, V>>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            entries.push(None)
            index = index + 1
        }

        self._states = states
        self._entries = entries
        self._length = 0
        self._used = 0

        let mut cursor: usize = 0
        while cursor < old_states.length() {
            if old_states.get(cursor + 1).unwrap() == 1 {
                let entry: SwissTableEntry<K, V> = old_entries.get(cursor + 1).unwrap().unwrap()
                self.insert(entry.key, entry.value)
            }

            cursor = cursor + 1
        }
    }
}

micro swiss_table_normalize_capacity(capacity: usize): usize {
    if capacity < 8 {
        return 8
    }

    return capacity * 2
}

micro swiss_table_next_capacity(capacity: usize): usize {
    if capacity < 8 {
        return 8
    }

    return capacity * 2
}
