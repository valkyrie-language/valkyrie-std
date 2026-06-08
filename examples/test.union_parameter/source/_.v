namespace union_parameter;

class LeftValue {
}

class RightValue {
}

micro accept_union(value: LeftValue | RightValue) -> i32 {
    return 21
}

[main]
micro union_parameter_main() -> ExitCode {
    let first = accept_union(LeftValue {})
    let second = accept_union(RightValue {})
    let total = first + second
    return ExitCode(total as i32)
}
