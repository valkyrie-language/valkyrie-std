namespace std.collections;

class BTreeSetNode<T> {
    leaf: bool
    keys: ArrayList<T>
    children: ArrayList<BTreeSetNode<T>>
    next: Option<BTreeSetNode<T>>
}

class BTreeSet<T> {
    _root: Option<BTreeSetNode<T>>
    _length: usize
}

imply BTreeSet<T> {
    micro new(): Self {
        return Self {
            _root: None,
            _length: 0,
        }
    }

    micro insert(mut self, value: T): bool {
        if self._root.is_none() {
            let root: BTreeSetNode<T> = BTreeSetNode {
                leaf: true,
                keys: ArrayList::new(4),
                children: ArrayList::new(0),
                next: None,
            }
            root.keys.push(value)
            self._root = Some(root)
            self._length = 1
            return true
        }

        if self.contains(value) {
            return false
        }

        let root: BTreeSetNode<T> = self._root.unwrap()
        if self.is_full(root) {
            let new_root: BTreeSetNode<T> = BTreeSetNode {
                leaf: false,
                keys: ArrayList::new(4),
                children: ArrayList::new(4),
                next: None,
            }
            new_root.children.push(root)
            self.split_child(new_root, 0)
            self._root = Some(new_root)
        }

        self.insert_non_full(self._root.unwrap(), value)
        self._length = self._length + 1
        return true
    }

    micro remove(mut self, value: T): bool {
        if !self.contains(value) {
            return false
        }

        let values: List<T> = self.to_list()
        self.clear()

        let mut index: usize = 0
        while index < values.length() {
            let current: T = values.get(index).unwrap()
            if current != value {
                self.insert(current)
            }

            index = index + 1
        }

        return true
    }

    micro contains(self, value: T): bool {
        if self._root.is_none() {
            return false
        }

        return self.search_node(self._root.unwrap(), value)
    }

    micro length(self): usize {
        return self._length
    }

    micro is_empty(self): bool {
        return self._length == 0
    }

    micro clear(mut self) -> unit {
        self._root = None
        self._length = 0
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: List<T> = self.to_list()
        let mut index: usize = 0
        while index < items.length() {
            f(items.get(index).unwrap())
            index = index + 1
        }
    }

    micro to_list(self): List<T> {
        let mut result: List<T> = ArrayList::new(self._length)
        if self._root.is_none() {
            return result
        }

        let mut current: Option<BTreeSetNode<T>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeSetNode<T> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                result.push(leaf.keys.get(cursor).unwrap())
                cursor = cursor + 1
            }

            current = leaf.next
        }

        return result
    }

    micro from_list(list: List<T>): Self {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit {
            result.insert(value)
        })
        return result
    }

    micro search_node(self, node: BTreeSetNode<T>, value: T): bool {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get(cursor).unwrap() == value {
                    return true
                }

                cursor = cursor + 1
            }

            return false
        }

        return self.search_node(node.children.get(self.find_child_index(node, value)).unwrap(), value)
    }

    micro insert_non_full(mut self, node: BTreeSetNode<T>, value: T): unit {
        if node.leaf {
            let mut insert_at: usize = 0
            while insert_at < node.keys.length() {
                if value < node.keys.get(insert_at).unwrap() {
                    break
                }

                insert_at = insert_at + 1
            }

            node.keys.insert(insert_at, value)
            return
        }

        let mut child_index: usize = self.find_child_index(node, value)
        let child: BTreeSetNode<T> = node.children.get(child_index).unwrap()
        if self.is_full(child) {
            self.split_child(node, child_index)
            if value >= node.keys.get(child_index).unwrap() {
                child_index = child_index + 1
            }
        }

        self.insert_non_full(node.children.get(child_index).unwrap(), value)
    }

    micro split_child(self, parent: BTreeSetNode<T>, child_index: usize): unit {
        let child: BTreeSetNode<T> = parent.children.get(child_index).unwrap()
        let right: BTreeSetNode<T> = BTreeSetNode {
            leaf: child.leaf,
            keys: ArrayList::new(4),
            children: ArrayList::new(4),
            next: None,
        }

        if child.leaf {
            while child.keys.length() > 1 {
                right.keys.push(child.keys.remove(1).unwrap())
            }

            right.next = child.next
            child.next = Some(right)

            parent.children.insert(child_index + 1, right)
            parent.keys.insert(child_index, parent.children.get(child_index + 1).unwrap().keys.get(0).unwrap())
            return
        }

        let separator: T = child.keys.get(1).unwrap()
        right.keys.push(child.keys.remove(2).unwrap())
        child.keys.remove(1)

        while child.children.length() > 2 {
            right.children.push(child.children.remove(2).unwrap())
        }

        parent.children.insert(child_index + 1, right)
        parent.keys.insert(child_index, separator)
    }

    micro leftmost_leaf(self, node: BTreeSetNode<T>): BTreeSetNode<T> {
        let mut current: BTreeSetNode<T> = node
        while !current.leaf {
            current = current.children.get(0).unwrap()
        }

        return current
    }

    micro find_child_index(self, node: BTreeSetNode<T>, value: T): usize {
        let mut cursor: usize = 0
        while cursor < node.keys.length() {
            if value < node.keys.get(cursor).unwrap() {
                return cursor
            }

            cursor = cursor + 1
        }

        return cursor
    }

    micro is_full(self, node: BTreeSetNode<T>): bool {
        return node.keys.length() >= 3
    }
}
