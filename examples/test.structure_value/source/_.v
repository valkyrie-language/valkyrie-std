namespace structure_value;

structure Point(i32, i32)

structure Circle { radius: i32 }

micro distance(p: Point) -> i32 {
    return p.0 + p.1
}

[main]
micro structure_main() -> ExitCode {
    let p = Point(3, 4)
    let d = distance(p)
    print("distance={d}")

    let c = Circle { radius: 5 }
    print("radius={c.radius}")

    return ExitCode(0 as i32)
}