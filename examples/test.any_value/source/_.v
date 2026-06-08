namespace any_value;

class Box {
}

micro echo(value: any) -> any {
    return value
}

micro consume(value: any) -> Unit {
    print("Any Value OK")
}

[main]
micro any_value_main() -> ExitCode {
    let box: any = Box {}
    let echoed: any = echo(box)
    consume(echoed)
    return ExitCode(0 as i32)
}
