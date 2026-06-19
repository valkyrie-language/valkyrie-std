namespace data_model;


[data]
structure Point {
    x: f32,
    y: f32,
}

micro offset(point: Point, dx: f32, dy: f32) -> Point {
    return Point {
        x: point.x + dx,
        y: point.y + dy,
    }
}

[main]
micro data_model_main() -> ExitCode {
    let origin = Point { x: 0.0, y: 0.0 }
    let target = Point { x: 3.5, y: 4.5 }
    let moved = offset(target, -1.0, 2.0)

    print("origin=({origin.x}, {origin.y})")
    print("target=({target.x}, {target.y})")
    print("moved=({moved.x}, {moved.y})")

    return ExitCode(0 as i32)
}
