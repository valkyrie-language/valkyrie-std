namespace std.collections;

class DisjointSet<T> {
    _parent: HashMap<T, T>
    _rank: HashMap<T, usize>
    _count: usize
}

imply DisjointSet<T> {
    micro new(): Self {
        return Self {
            _parent: HashMap::new(16),
            _rank: HashMap::new(16),
            _count: 0,
        }
    }

    micro add(mut self, value: T): bool {
        if self._parent.contains_key(value) {
            return false
        }

        self._parent.insert(value, value)
        self._rank.insert(value, 0)
        self._count = self._count + 1
        return true
    }

    micro contains(self, value: T): bool {
        return self._parent.contains_key(value)
    }

    micro find(mut self, value: T): Option<T> {
        if !self.contains(value) {
            return None
        }

        return Some(self.find_root(value))
    }

    micro union(mut self, left: T, right: T): bool {
        self.add(left)
        self.add(right)

        let left_root: T = self.find_root(left)
        let right_root: T = self.find_root(right)
        if left_root == right_root {
            return false
        }

        let left_rank: usize = self._rank.get(left_root).unwrap()
        let right_rank: usize = self._rank.get(right_root).unwrap()

        if left_rank < right_rank {
            self._parent.insert(left_root, right_root)
        }
        else if left_rank > right_rank {
            self._parent.insert(right_root, left_root)
        }
        else {
            self._parent.insert(right_root, left_root)
            self._rank.insert(left_root, left_rank + 1)
        }

        self._count = self._count - 1
        return true
    }

    micro connected(mut self, left: T, right: T): bool {
        if !self.contains(left) || !self.contains(right) {
            return false
        }

        return self.find_root(left) == self.find_root(right)
    }

    micro length(self): usize {
        return self._parent.length()
    }

    micro group_count(self): usize {
        return self._count
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self): unit {
        self._parent.clear()
        self._rank.clear()
        self._count = 0
    }

    micro elements(self): List<T> {
        return self._parent.keys()
    }

    micro find_root(mut self, value: T): T {
        let parent: T = self._parent.get(value).unwrap()
        if parent == value {
            return value
        }

        let root: T = self.find_root(parent)
        self._parent.insert(value, root)
        return root
    }
}
