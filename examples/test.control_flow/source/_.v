namespace control_flow;

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

micro sum_with_loop_in(values: [i32]) -> i32 {
    let mut total = 0 as i32
    loop value in values {
        total += value
    }
    return total
}

micro collect_even_doubles(values: [i32]) -> [i32] {
    return values
        .into_iterator()
        .skip(1 as usize)
        .map(micro(value: i32) -> i32 {
            return value * (2 as i32)
        })
        .filter(micro(value: i32) -> bool {
            return value >= (6 as i32)
        })
        .collect_array()
}

micro sum_generic_iterator<I>(iter: I) -> i32
    where I: std.iterator.Iterator<Item = i32>
{
    let mut total = 0 as i32
    loop item in iter {
        total += item
    }
    return total
}

micro smoke_loop_in() -> ExitCode {
    let loop_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let loop_in_sum = sum_with_loop_in(loop_values)
    if loop_in_sum != 10 {
        return ExitCode(1 as i32)
    }
    return ExitCode(0 as i32)
}

micro smoke_iterator_chain() -> ExitCode {
    let transform_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let transformed = collect_even_doubles(transform_values)
    if transformed.length() != (2 as usize) {
        return ExitCode(1 as i32)
    }
    if transformed.get(0 as usize).unwrap() != 6 {
        return ExitCode(2 as i32)
    }
    if transformed.get(1 as usize).unwrap() != 8 {
        return ExitCode(3 as i32)
    }
    return ExitCode(0 as i32)
}

micro smoke_generic_iterator() -> ExitCode {
    let generic_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let generic_iter_sum = sum_generic_iterator(generic_values.into_iterator().skip(1 as usize))
    if generic_iter_sum != 9 {
        return ExitCode(1 as i32)
    }
    return ExitCode(0 as i32)
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
    if smoke_loop_in() != ExitCode(0 as i32) {
        return ExitCode(6 as i32)
    }
    if smoke_generic_iterator() != ExitCode(0 as i32) {
        return ExitCode(7 as i32)
    }
    if smoke_iterator_chain() != ExitCode(0 as i32) {
        return ExitCode(8 as i32)
    }

    # pending loop_in sample for CLR bootstrap
    #
    # let mut ranged = 0
    # loop item in [0 as i32, 1 as i32, 2 as i32, 3 as i32] {
    #     ranged += item
    # }
    # if ranged != counted {
    #     return ExitCode(6 as i32)
    # }

    return ExitCode(0 as i32)
}
