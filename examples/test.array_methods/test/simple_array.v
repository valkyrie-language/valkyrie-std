namespace array_methods::test;

[test]
micro simple_array() -> unit {
    let arr = [3, 1, 4, 1, 5, 9, 2, 6]
    print("len={arr.length}, first={arr.first()}")
}

[test]
micro array_literal() -> unit {
    let arr = [1, 2, 3, 4, 5]
    print("len={arr.length}")
}

[test]
micro array_map() -> unit {
    let arr = [1, 2, 3]
    let doubled = arr.map(x => x * 2)
    print("doubled={doubled.length}")
}

[test]
micro array_filter() -> unit {
    let arr = [1, 2, 3, 4, 5]
    let big = arr.filter(x => x > 3)
    print("count={big.length}")
}

[test]
micro array_reduce() -> unit {
    let arr = [1, 2, 3, 4, 5]
    let sum = arr.reduce(0, micro(acc, x) { acc + x })
    print("sum={sum}")
}

[test]
micro array_sort() -> unit {
    let arr = [3, 1, 4, 1, 5]
    let sorted = arr.sort()
    print("sorted ok")
}

[test]
micro array_reverse() -> unit {
    let arr = [1, 2, 3]
    let rev = arr.reverse()
    print("reversed ok")
}

[test]
micro array_unique() -> unit {
    let arr = [1, 1, 2, 2, 3]
    let u = arr.unique()
    print("unique={u.length}")
}

[test]
micro array_sum_min_max() -> unit {
    let arr = [1, 2, 3, 4, 5]
    let s = arr.sum()
    let mn = arr.min()
    let mx = arr.max()
    print("sum={s}, min={mn}, max={mx}")
}

[test]
micro array_take_skip() -> unit {
    let arr = [1, 2, 3, 4, 5]
    let t = arr.take(2)
    let s = arr.skip(2)
    print("take={t.length}, skip={s.length}")
}

[test]
micro array_zip() -> unit {
    let a = [1, 2, 3]
    let b = ["x", "y", "z"]
    let z = a.zip(b)
    print("zipped={z.length}")
}

[test]
micro array_flatten() -> unit {
    let arr = [[1, 2], [3, 4]]
    let f = arr.flatten()
    print("flat={f.length}")
}

[test]
micro array_indexing() -> unit {
    let arr = [10, 20, 30, 40, 50]
    let third = arr[2]
    print("third={third}")
}

[test]
micro array_slicing() -> unit {
    let arr = [1, 2, 3, 4, 5]
    let slice = arr[1..3]
    print("slice={slice.length}")
}

[test]
micro array_push_pop() -> unit {
    let mut arr = [1, 2, 3]
    arr.push(4)
    let last = arr.pop()
    print("last={last}, len={arr.length}")
}

[benchmark]
micro array_benchmark() -> unit {
    let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let s = arr.sum()
    print("bench sum={s}")
}
