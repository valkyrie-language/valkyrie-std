namespace std.collections;

class SwissSet<T> {
    _states: ArrayList<i32>
    _values: ArrayList<Option<T>>
    _length: usize
    _used: usize
}

imply SwissSet<T> {
    micro new(capacity: usize): Self {
        let slot_count: usize = swiss_table_normalize_capacity(capacity)
        let mut states: ArrayList<i32> = ArrayList::new(slot_count)
        let mut values: ArrayList<Option<T>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            values.push(None)
            index = index + 1
        }

        return Self {
            _states: states,
            _values: values,
            _length: 0,
            _used: 0,
        }
    }

    micro insert(mut self, value: T): bool {
        if self.should_grow() {
            self.rehash(swiss_table_next_capacity(self._states.length()))
        }

        let value_hash: usize = value.hash()
        let slot: Option<usize> = self.find_insert_slot(value, value_hash)
        if slot.is_none() {
            self.rehash(swiss_table_next_capacity(self._states.length()))
            return self.insert(value)
        }

        let index: usize = slot.unwrap()
        let state: i32 = self._states.get(index).unwrap()
        if state == 1 {
            return false
        }

        if state == 0 {
            self._used = self._used + 1
        }

        self._states.set(index, 1)
        self._values.set(index, Some(value))
        self._length = self._length + 1
        return true
    }

    micro remove(mut self, value: T): bool {
        let slot: Option<usize> = self.find_slot(value)
        if slot.is_none() {
            return false
        }

        let index: usize = slot.unwrap()
        self._states.set(index, 2)
        self._values.set(index, None)
        self._length = self._length - 1
        return true
    }

    micro contains(self, value: T): bool {
        return self.find_slot(value).is_some()
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
        let mut values: ArrayList<Option<T>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            values.push(None)
            index = index + 1
        }

        self._states = states
        self._values = values
        self._length = 0
        self._used = 0
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let mut index: usize = 0
        while index < self._states.length() {
            if self._states.get(index).unwrap() == 1 {
                f(self._values.get(index).unwrap().unwrap())
            }

            index = index + 1
        }
    }

    micro to_list(self): List<T> {
        let mut result: List<T> = ArrayList::new(self._length)
        let mut index: usize = 0
        while index < self._states.length() {
            if self._states.get(index).unwrap() == 1 {
                result.push(self._values.get(index).unwrap().unwrap())
            }

            index = index + 1
        }

        return result
    }

    micro from_list(values: List<T>): Self {
        let mut result: Self = Self::new(values.length())
        let mut index: usize = 0
        while index < values.length() {
            result.insert(values.get(index).unwrap())
            index = index + 1
        }

        return result
    }

    micro find_slot(self, value: T): Option<usize> {
        let slot_count: usize = self._states.length()
        if slot_count == 0 {
            return None
        }

        let value_hash: usize = value.hash()
        let mut index: usize = value_hash % slot_count
        let mut probe: usize = 0
        while probe < slot_count {
            let state: i32 = self._states.get(index).unwrap()
            if state == 0 {
                return None
            }

            if state == 1 && self._values.get(index).unwrap().unwrap() == value {
                return Some(index)
            }

            index = (index + 1) % slot_count
            probe = probe + 1
        }

        return None
    }

    micro find_insert_slot(self, value: T, value_hash: usize): Option<usize> {
        let slot_count: usize = self._states.length()
        let mut first_deleted: Option<usize> = None
        let mut index: usize = value_hash % slot_count
        let mut probe: usize = 0
        while probe < slot_count {
            let state: i32 = self._states.get(index).unwrap()
            if state == 0 {
                if first_deleted.is_some() {
                    return first_deleted
                }

                return Some(index)
            }

            if state == 2 && first_deleted.is_none() {
                first_deleted = Some(index)
            }

            if state == 1 && self._values.get(index).unwrap().unwrap() == value {
                return Some(index)
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
        let old_values: ArrayList<Option<T>> = self._values

        let mut states: ArrayList<i32> = ArrayList::new(slot_count)
        let mut values: ArrayList<Option<T>> = ArrayList::new(slot_count)
        let mut index: usize = 0
        while index < slot_count {
            states.push(0)
            values.push(None)
            index = index + 1
        }

        self._states = states
        self._values = values
        self._length = 0
        self._used = 0

        let mut cursor: usize = 0
        while cursor < old_states.length() {
            if old_states.get(cursor).unwrap() == 1 {
                self.insert(old_values.get(cursor).unwrap().unwrap())
            }

            cursor = cursor + 1
        }
    }
}
