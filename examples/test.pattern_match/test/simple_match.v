namespace pattern_match::test;

[test]
micro simple_match() -> unit {
    let x = 42
    let label = match x {
        case 42 => "answer"
        when x > 0 => "positive"
        else => "other"
    }
    print(label)

    structure Point(i32, i32)
    let p = Point(3, 4)
    let coords = match p {
        case Point(x, y) => "ok"
    }
    print(coords)
}
