namespace array_methods;

[main]
micro array_methods_main() -> ExitCode {
    let arr = [3, 1, 4, 1, 5, 9, 2, 6]
    print("len={arr.length}")
    print("first={arr.first()}")
    print("last={arr.last()}")
    print("sorted={arr.sort()}")
    print("reversed={arr.reverse()}")
    print("unique={arr.unique()}")
    print("sum={arr.sum()}")
    print("min={arr.min()}")
    print("max={arr.max()}")
    print("take3={arr.take(3)}")
    print("skip3={arr.skip(3)}")
    print("contains5={arr.contains(5)}")
    print("mapped={arr.map(x => x * 2)}")
    print("filtered={arr.filter(x => x > 3)}")
    print("reduced={arr.reduce(0, micro(acc, x) { acc + x })}")
    print("zipped={arr.zip([\"a\", \"b\", \"c\", \"d\", \"e\", \"f\", \"g\", \"h\"])}")
    print("flattened={[[1,2],[3,4]].flatten()}")

    return ExitCode(0 as i32)
}
