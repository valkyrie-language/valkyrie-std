namespace control_flow_smoke;

micro classify_number(value: i32) -> utf8 {
    if value > 0 {
        return "positive"
    } else if value < 0 {
        return "negative"
    } else {
        return "zero"
    }
}

micro count_with_counted_loop(limit: i32) -> i32 {
    let mut count = 0
    loop let i = 0; i < limit; i += 1 {
        count += 1
    }
    return count
}

micro count_with_while(limit: i32) -> i32 {
    let mut current = 0
    while (current < limit) {
        current += 1
    }
    return current
}

micro count_with_until(limit: i32) -> i32 {
    let mut current = 0
    until (current >= limit) {
        current += 1
    }
    return current
}

micro count_with_infinite_loop(limit: i32) -> i32 {
    let mut current = 0
    loop {
        if current >= limit {
            break
        }
        current += 1
    }
    return current
}

[main]
micro main() -> ExitCode {
    let limit = 4 as i32
    let counted = count_with_counted_loop(limit)
    let while_count = count_with_while(limit)
    let until_count = count_with_until(limit)
    let infinite_count = count_with_infinite_loop(limit)
    if classify_number(limit) != "positive" {
        return ExitCode(1 as i32)
    }
    if counted != limit {
        return ExitCode(2 as i32)
    }
    if counted != while_count {
        return ExitCode(3 as i32)
    }
    if while_count != until_count {
        return ExitCode(4 as i32)
    }
    if until_count != infinite_count {
        return ExitCode(5 as i32)
    }
    return ExitCode(0 as i32)
}