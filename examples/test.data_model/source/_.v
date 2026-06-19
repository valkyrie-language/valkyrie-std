namespace map_methods;


[data]
structure Point {
    x: f32,
    y: f32,
}

[main]
micro map_methods_main() -> ExitCode {
    let m = { "a": 1, "b": 2, "c": 3 }
    print("len={m.length}")
    print("a={m[\"a\"]}")
    print("contains_b={m.contains(\"b\")}")
    print("keys={m.keys()}")
    print("values={m.values()}")
    print("entries={m.entries()}")
    print("get_a={m.get(\"a\")}")
    print("get_x={m.get(\"x\", -1)}")

    let m2 = m.set("d", 4)
    print("after_set={m2.length}")

    let m3 = m.remove("a")
    print("after_remove={m3.length}")

    let merged = m.merge({ "d": 4, "e": 5 })
    print("merged={merged.length}")

    let inverted = m.invert()
    print("inverted ok")

    let filtered = m.filter((k, v) => v > 1)
    print("filtered={filtered.length}")

    let mapped = m.map_values(v => v * 10)
    print("mapped ok")

    return ExitCode(0 as i32)
}
