namespace std.collection.test;

[test]
micro `test array methods`() {
    let values: [i32] = [1, 2, 3]

    if values.length != 3 {
        panic("array property test failed")
    }
}

[test]
micro `test array list host binding`() {
    let list: ArrayList<i32> = ArrayList::new(0)
    list.push(1)
    list.push(2)
    list.push(3)

    if list.length() != 3 {
        panic("array list length test failed")
    }

    if list.length != 3 {
        panic("array list property test failed")
    }

    if list.get(1).unwrap() != 2 {
        panic("array list get test failed")
    }

    list.set(1, 9)
    if list.get(1).unwrap() != 9 {
        panic("array list set test failed")
    }

    if !list.contains(9) {
        panic("array list contains test failed")
    }

    if list.first().unwrap() != 1 {
        panic("array list first test failed")
    }

    if list.last().unwrap() != 3 {
        panic("array list last test failed")
    }

    if list.remove(1).unwrap() != 9 {
        panic("array list remove test failed")
    }

    if list.length() != 2 {
        panic("array list remove length test failed")
    }

    list.clear()
    if !list.is_empty() {
        panic("array list clear test failed")
    }
}

[test]
micro `test linked list push and pop`() {
    let list: LinkedList<i32> = LinkedList::new()

    if !list.is_empty() {
        panic("linked list initial empty test failed")
    }

    list.push_back(2)
    list.push_front(1)
    list.push_back(3)

    if list.length() != 3 {
        panic("linked list length test failed")
    }

    if list.peek_front().unwrap() != 1 {
        panic("linked list peek_front test failed")
    }

    if list.peek_back().unwrap() != 3 {
        panic("linked list peek_back test failed")
    }

    if list.pop_front().unwrap() != 1 {
        panic("linked list pop_front test failed")
    }

    if list.pop_back().unwrap() != 3 {
        panic("linked list pop_back test failed")
    }

    if list.pop_back().unwrap() != 2 {
        panic("linked list final pop test failed")
    }

    if !list.is_empty() {
        panic("linked list empty after pop test failed")
    }
}

[test]
micro `test linked list contains and clear`() {
    let list: LinkedList<i32> = LinkedList::new()

    list.push_back(4)
    list.push_back(5)
    list.push_front(3)

    if !list.contains(4) {
        panic("linked list contains test failed")
    }

    if list.contains(8) {
        panic("linked list contains missing value test failed")
    }

    if list.first().unwrap() != 3 {
        panic("linked list first test failed")
    }

    if list.last().unwrap() != 5 {
        panic("linked list last test failed")
    }

    list.clear()
    if !list.is_empty() {
        panic("linked list clear test failed")
    }
}

[test]
micro `test linked list reverse iteration`() {
    let list: LinkedList<i32> = LinkedList::new()
    let values: List<i32> = ArrayList::new(0)

    list.push_back(1)
    list.push_back(2)
    list.push_back(3)

    list.iter_reverse(micro(value: i32) -> unit {
        values.push(value)
    })

    if values.length() != 3 {
        panic("linked list reverse iteration length test failed")
    }

    if values.get(0).unwrap() != 3 || values.get(1).unwrap() != 2 || values.get(2).unwrap() != 1 {
        panic("linked list reverse iteration order test failed")
    }
}

[test]
micro `test bit set basic operations`() {
    let bits: BitSet = BitSet::with_capacity(16)

    if !bits.is_empty() {
        panic("bit set initial empty test failed")
    }

    bits.set(1)
    bits.set(7)
    bits.toggle(1)

    if bits.get(1) {
        panic("bit set toggle test failed")
    }

    if !bits.get(7) {
        panic("bit set get test failed")
    }

    bits.clear_bit(7)
    if bits.get(7) {
        panic("bit set clear_bit test failed")
    }

    bits.set(12)
    bits.clear_all()
    if !bits.is_empty() {
        panic("bit set clear_all test failed")
    }
}

[test]
micro `test bit set set operations`() {
    let left: BitSet = BitSet::with_capacity(8)
    let right: BitSet = BitSet::with_capacity(8)

    left.set(1)
    left.set(3)
    right.set(3)
    right.set(4)

    left.union(right)
    if !left.get(1) || !left.get(3) || !left.get(4) {
        panic("bit set union test failed")
    }

    let intersect_left: BitSet = BitSet::with_capacity(8)
    let intersect_right: BitSet = BitSet::with_capacity(8)
    intersect_left.set(1)
    intersect_left.set(3)
    intersect_right.set(3)
    intersect_right.set(4)
    intersect_left.intersect(intersect_right)
    if intersect_left.get(1) || !intersect_left.get(3) || intersect_left.get(4) {
        panic("bit set intersect test failed")
    }

    let difference_left: BitSet = BitSet::with_capacity(8)
    let difference_right: BitSet = BitSet::with_capacity(8)
    difference_left.set(1)
    difference_left.set(3)
    difference_right.set(3)
    difference_left.difference(difference_right)
    if !difference_left.get(1) || difference_left.get(3) {
        panic("bit set difference test failed")
    }

    let xor_left: BitSet = BitSet::with_capacity(8)
    let xor_right: BitSet = BitSet::with_capacity(8)
    xor_left.set(1)
    xor_left.set(3)
    xor_right.set(3)
    xor_right.set(4)
    xor_left.xor(xor_right)
    if !xor_left.get(1) || xor_left.get(3) || !xor_left.get(4) {
        panic("bit set xor test failed")
    }
}

[test]
micro `test binary heap ordering`() {
    let heap: BinaryHeap<i32> = BinaryHeap::new()

    heap.push(3)
    heap.push(1)
    heap.push(2)

    if heap.length() != 3 {
        panic("binary heap length test failed")
    }

    if heap.peek().unwrap() != 1 {
        panic("binary heap peek test failed")
    }

    if heap.pop().unwrap() != 1 || heap.pop().unwrap() != 2 || heap.pop().unwrap() != 3 {
        panic("binary heap pop order test failed")
    }

    if !heap.is_empty() {
        panic("binary heap empty test failed")
    }
}

[test]
micro `test priority queue ordering`() {
    let queue: PriorityQueue<i32> = PriorityQueue::new()

    queue.push(3)
    queue.push(1)
    queue.push(2)

    if queue.length() != 3 {
        panic("priority queue length test failed")
    }

    if queue.peek().unwrap() != 1 {
        panic("priority queue peek test failed")
    }

    if queue.pop().unwrap() != 1 || queue.pop().unwrap() != 2 || queue.pop().unwrap() != 3 {
        panic("priority queue pop order test failed")
    }

    if !queue.is_empty() {
        panic("priority queue empty test failed")
    }
}

[test]
micro `test disjoint set connectivity`() {
    let set: DisjointSet<i32> = DisjointSet::new()

    set.add(1)
    set.add(2)
    set.add(3)

    if set.length() != 3 || set.group_count() != 3 {
        panic("disjoint set initial count test failed")
    }

    if !set.union(1, 2) {
        panic("disjoint set union test failed")
    }

    if !set.connected(1, 2) || set.connected(1, 3) {
        panic("disjoint set connectivity test failed")
    }

    if set.group_count() != 2 {
        panic("disjoint set group count test failed")
    }
}

[test]
micro `test disjoint set union auto add`() {
    let set: DisjointSet<i32> = DisjointSet::new()

    set.union(10, 20)
    set.union(20, 30)

    if set.length() != 3 {
        panic("disjoint set auto add length test failed")
    }

    if set.group_count() != 1 {
        panic("disjoint set auto add group count test failed")
    }

    if !set.connected(10, 30) {
        panic("disjoint set auto add connectivity test failed")
    }

    if set.find(10).is_none() || set.find(30).is_none() {
        panic("disjoint set find test failed")
    }
}

[test]
micro `test multiset counts`() {
    let set: MultiSet<i32> = MultiSet::new()

    if set.insert(3) != 1 {
        panic("multiset first insert count test failed")
    }

    set.insert(3)
    set.insert(1)

    if set.length() != 3 {
        panic("multiset total length test failed")
    }

    if set.distinct_length() != 2 {
        panic("multiset distinct length test failed")
    }

    if set.count(3) != 2 || set.count(1) != 1 || set.count(8) != 0 {
        panic("multiset count test failed")
    }

    if !set.contains(3) || set.contains(8) {
        panic("multiset contains test failed")
    }
}

[test]
micro `test multiset remove and iterate counts`() {
    let set: MultiSet<i32> = MultiSet::new()
    let keys: List<i32> = ArrayList::new(0)
    let counts: List<usize> = ArrayList::new(0)

    set.insert(2)
    set.insert(2)
    set.insert(2)
    set.insert(5)

    if !set.remove(2) {
        panic("multiset remove single test failed")
    }

    if set.count(2) != 2 || set.length() != 3 {
        panic("multiset remove single count test failed")
    }

    if set.remove_all(2) != 2 {
        panic("multiset remove_all test failed")
    }

    if set.count(2) != 0 || set.length() != 1 || set.distinct_length() != 1 {
        panic("multiset remove_all state test failed")
    }

    set.iterator(micro(value: i32, count: usize) -> unit {
        keys.push(value)
        counts.push(count)
    })

    if keys.length() != 1 || keys.get(0).unwrap() != 5 {
        panic("multiset iterator key test failed")
    }

    if counts.length() != 1 || counts.get(0).unwrap() != 1 {
        panic("multiset iterator count test failed")
    }
}

[test]
micro `test ordered map keeps insertion order`() {
    let map: OrderedMap<i32, i32> = OrderedMap::new(0)

    map.insert(3, 30)
    map.insert(1, 10)
    map.insert(2, 20)
    map.insert(1, 11)

    let keys: List<i32> = map.keys()
    let values: List<i32> = map.values()
    if map.length() != 3 {
        panic("ordered map length test failed")
    }

    if keys.get(0).unwrap() != 3 || keys.get(1).unwrap() != 1 || keys.get(2).unwrap() != 2 {
        panic("ordered map key order test failed")
    }

    if values.get(0).unwrap() != 30 || values.get(1).unwrap() != 11 || values.get(2).unwrap() != 20 {
        panic("ordered map value order test failed")
    }

    if map.remove(1).unwrap() != 11 {
        panic("ordered map remove test failed")
    }

    map.insert(4, 40)
    let keys_after: List<i32> = map.keys()
    if keys_after.get(0).unwrap() != 3 || keys_after.get(1).unwrap() != 2 || keys_after.get(2).unwrap() != 4 {
        panic("ordered map order after remove test failed")
    }
}

[test]
micro `test hash map keys and values`() {
    let map: HashMap<i32, i32> = HashMap::new(0)

    map.insert(3, 30)
    map.insert(1, 10)
    map.insert(2, 20)
    map.insert(1, 11)

    let keys: List<i32> = map.keys()
    let values: List<i32> = map.values()
    if map.length() != 3 {
        panic("hash map length test failed")
    }

    if keys.length() != 3 || values.length() != 3 {
        panic("hash map keys or values length test failed")
    }

    if !keys.contains(1) || !keys.contains(2) || !keys.contains(3) {
        panic("hash map keys content test failed")
    }

    if !values.contains(11) || !values.contains(20) || !values.contains(30) {
        panic("hash map values content test failed")
    }
}

[test]
micro `test hash set basic operations`() {
    let set: HashSet<i32> = HashSet::new()

    if !set.insert(3) {
        panic("hash set first insert test failed")
    }

    set.insert(1)
    set.insert(2)

    if set.insert(1) {
        panic("hash set duplicate insert test failed")
    }

    if set.length() != 3 {
        panic("hash set length test failed")
    }

    if !set.contains(1) || !set.contains(2) || !set.contains(3) {
        panic("hash set contains test failed")
    }

    let values: List<i32> = set.to_list()
    if values.length() != 3 {
        panic("hash set to_list length test failed")
    }
}

[test]
micro `test hash set remove and reuse deleted slot`() {
    let set: HashSet<i32> = HashSet::new()

    set.insert(1)
    set.insert(9)
    set.insert(17)

    if !set.remove(9) {
        panic("hash set remove test failed")
    }

    if set.contains(9) {
        panic("hash set removed value still present test failed")
    }

    if !set.insert(25) {
        panic("hash set insert after tombstone test failed")
    }

    if !set.contains(25) {
        panic("hash set contains reinserted value test failed")
    }

    if set.length() != 3 {
        panic("hash set length after tombstone reuse test failed")
    }
}

[test]
micro `test hash set grow and clear`() {
    let set: HashSet<i32> = HashSet::new()
    let mut value: i32 = 0
    while value < 32 {
        if !set.insert(value) {
            panic("hash set grow insert test failed")
        }

        value = value + 1
    }

    if set.length() != 32 {
        panic("hash set grow length test failed")
    }

    let mut verify: i32 = 0
    while verify < 32 {
        if !set.contains(verify) {
            panic("hash set grow contains test failed")
        }

        verify = verify + 1
    }

    set.clear()
    if !set.is_empty() {
        panic("hash set clear test failed")
    }

    if !set.insert(100) || !set.contains(100) || set.length() != 1 {
        panic("hash set reuse after clear test failed")
    }
}

[test]
micro `test ordered set keeps insertion order`() {
    let set: OrderedSet<i32> = OrderedSet::new()

    if !set.insert(5) {
        panic("ordered set first insert test failed")
    }

    set.insert(1)
    set.insert(3)

    if set.insert(1) {
        panic("ordered set duplicate insert test failed")
    }

    let values: List<i32> = set.to_list()
    if set.length() != 3 {
        panic("ordered set length test failed")
    }

    if values.get(0).unwrap() != 5 || values.get(1).unwrap() != 1 || values.get(2).unwrap() != 3 {
        panic("ordered set order test failed")
    }

    if !set.remove(1) {
        panic("ordered set remove test failed")
    }

    let values_after: List<i32> = set.to_list()
    if values_after.get(0).unwrap() != 5 || values_after.get(1).unwrap() != 3 {
        panic("ordered set order after remove test failed")
    }
}

[test]
micro `test sorted map keeps key order`() {
    let map: SortedMap<i32, i32> = SortedMap::new(0)

    map.insert(3, 30)
    map.insert(1, 10)
    map.insert(2, 20)
    map.insert(1, 11)

    let keys: List<i32> = map.keys()
    let values: List<i32> = map.values()
    if map.length() != 3 {
        panic("sorted map length test failed")
    }

    if keys.get(0).unwrap() != 1 || keys.get(1).unwrap() != 2 || keys.get(2).unwrap() != 3 {
        panic("sorted map key order test failed")
    }

    if values.get(0).unwrap() != 11 || values.get(1).unwrap() != 20 || values.get(2).unwrap() != 30 {
        panic("sorted map value order test failed")
    }

    if map.remove(2).unwrap() != 20 {
        panic("sorted map remove test failed")
    }

    let keys_after: List<i32> = map.keys()
    if keys_after.length() != 2 || keys_after.get(0).unwrap() != 1 || keys_after.get(1).unwrap() != 3 {
        panic("sorted map remove order test failed")
    }
}

[test]
micro `test sorted set keeps value order`() {
    let set: SortedSet<i32> = SortedSet::new()

    set.insert(5)
    set.insert(1)
    set.insert(3)
    set.insert(1)

    let values: List<i32> = set.to_list()
    if set.length() != 3 {
        panic("sorted set length test failed")
    }

    if values.get(0).unwrap() != 1 || values.get(1).unwrap() != 3 || values.get(2).unwrap() != 5 {
        panic("sorted set order test failed")
    }

    if !set.remove(3) {
        panic("sorted set remove test failed")
    }

    let values_after: List<i32> = set.to_list()
    if values_after.length() != 2 || values_after.get(0).unwrap() != 1 || values_after.get(1).unwrap() != 5 {
        panic("sorted set remove order test failed")
    }
}
