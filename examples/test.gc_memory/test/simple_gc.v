namespace gc_memory::test;

class Node { value: i32; next: Node? }

[test]
micro simple_gc() -> unit {
    let initial = gc.alive_count()
    let n = Node { value: 1, next: none }
    let after = gc.alive_count()
    print("initial={initial}, after={after}")
}

[test]
micro gc_collect_explicit() -> unit {
    let n = Node { value: 42, next: none }
    n = none
    gc.collect()
    print("after collect ok")
}

[test]
micro gc_heap_size() -> unit {
    let size = gc.heap_size()
    print("heap={size}")
}

[test]
micro allocate_many_then_collect() -> unit {
    let mut arr = []
    for i in 0..100 {
        arr.push(Node { value: i, next: none })
    }
    let before = gc.alive_count()
    arr.clear()
    gc.collect()
    let after = gc.alive_count()
    print("before={before}, after={after}")
}

[test]
micro weak_reference() -> unit {
    let strong = Node { value: 7, next: none }
    let weak = weak_ref(strong)
    let alive1 = weak.deref()
    print("alive1={alive1 != none}")

    strong = none
    gc.collect()
    let alive2 = weak.deref()
    print("alive2={alive2 != none}")
}

[test]
micro circular_reference() -> unit {
    let a = Node { value: 1, next: none }
    let b = Node { value: 2, next: a }
    a.next = b
    let before = gc.alive_count()
    a = none
    b = none
    gc.collect()
    let after = gc.alive_count()
    print("before={before}, after={after}")
}

[test]
micro allocate_buffer() -> unit {
    let buf = allocate_buffer(1024)
    print("buf ok={buf != null}")
    deallocate(buf)
}

[test]
micro gc_stats() -> unit {
    let total = gc.total_allocated()
    let freed = gc.total_freed()
    let collections = gc.collection_count()
    print("total={total}, freed={freed}, collections={collections}")
}

[benchmark]
micro gc_benchmark() -> unit {
    let mut arr = []
    for i in 0..1000 {
        arr.push(Node { value: i, next: none })
    }
    arr.clear()
    gc.collect()
    print("bench done")
}
