namespace pattern_match;

structure Point(i32, i32)

class Circle { radius: i32 }
class Rectangle { width: i32; height: i32 }

[main]
micro pattern_match_main() -> ExitCode {
    let x = 42
    let label = match x {
        case 42 => "answer"
        when x > 0 => "positive"
        else => "other"
    }
    print(label)

    let p = Point(3, 4)
    let coords = match p {
        case Point(x, y) => "x={x}, y={y}"
    }
    print(coords)

    let items = [1, 2, 3]
    let head = match items {
        case [] => "empty"
        case [head, ..tail] => "head={head}"
    }
    print(head)

    return ExitCode(0 as i32)
}