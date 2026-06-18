namespace control_flow;

[main]
micro control_flow_main() -> ExitCode {
    let a = 10
    if a > 0 {
        print("positive")
    } else if a < 0 {
        print("negative")
    } else {
        print("zero")
    }

    loop count in 0..3 {
        print("loop in {count}")
    }

    loop i in 0..3 {
        print("loop {i}")
    }

    let mut n = 0
    loop {
        n += 1
        if n >= 3 { break }
    }
    print("loop break ok")

    return ExitCode(0 as i32)
}
