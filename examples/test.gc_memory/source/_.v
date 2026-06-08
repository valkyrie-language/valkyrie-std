namespace gc_memory;

class Node { value: i32; next: Node? }

[main]
micro gc_memory_main() -> ExitCode {
    print("initial heap={gc.heap_size()}")
    print("initial alive={gc.alive_count()}")

    let nodes = []
    for i in 0..1000 {
        let n = Node { value: i, next: nodes.last() }
        nodes.push(n)
    }
    print("after alloc heap={gc.heap_size()}")
    print("after alloc alive={gc.alive_count()}")

    nodes.clear()
    gc.collect()
    print("after collect heap={gc.heap_size()}")
    print("after collect alive={gc.alive_count()}")

    let strong = Node { value: 1, next: none }
    let weak = weak_ref(strong)
    strong = none
    gc.collect()
    let resolved = weak.deref()
    print("weak resolved={resolved != none}")

    let big = allocate_buffer(1024 * 1024)
    print("big buffer ptr={big != null}")
    deallocate(big)

    return ExitCode(0 as i32)
}
