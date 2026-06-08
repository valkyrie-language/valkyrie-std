namespace map_methods::test;

[test]
micro simple_map() -> unit {
    let m = { "a": 1, "b": 2 }
    print("len={m.length}")
}

[test]
micro map_get_set() -> unit {
    let m = { "x": 10 }
    let x = m["x"]
    print("x={x}")
}

[test]
micro map_contains() -> unit {
    let m = { "a": 1, "b": 2 }
    let has_a = m.contains("a")
    let has_x = m.contains("x")
    print("has_a={has_a}, has_x={has_x}")
}

[test]
micro map_keys_values() -> unit {
    let m = { "a": 1, "b": 2, "c": 3 }
    let keys = m.keys()
    let values = m.values()
    print("keys={keys.length}, values={values.length}")
}

[test]
micro map_entries() -> unit {
    let m = { "a": 1, "b": 2 }
    let entries = m.entries()
    print("entries={entries.length}")
}

[test]
micro map_get_with_default() -> unit {
    let m = { "a": 1 }
    let x = m.get("x", -1)
    print("default={x}")
}

[test]
micro map_set_immutable() -> unit {
    let m1 = { "a": 1 }
    let m2 = m1.set("b", 2)
    print("m1={m1.length}, m2={m2.length}")
}

[test]
micro map_remove_immutable() -> unit {
    let m1 = { "a": 1, "b": 2 }
    let m2 = m1.remove("a")
    print("m1={m1.length}, m2={m2.length}")
}

[test]
micro map_merge() -> unit {
    let m1 = { "a": 1 }
    let m2 = { "b": 2 }
    let m3 = m1.merge(m2)
    print("merged={m3.length}")
}

[test]
micro map_filter() -> unit {
    let m = { "a": 1, "b": 2, "c": 3 }
    let big = m.filter((k, v) => v > 1)
    print("filtered={big.length}")
}

[test]
micro map_map_values() -> unit {
    let m = { "a": 1, "b": 2 }
    let doubled = m.map_values(v => v * 2)
    print("doubled ok")
}

[test]
micro map_invert() -> unit {
    let m = { "a": 1, "b": 2 }
    let inv = m.invert()
    print("inverted ok")
}

[benchmark]
micro map_benchmark() -> unit {
    let m = { "a": 1, "b": 2, "c": 3 }
    let v = m["a"]
    print("bench: {v}")
}
