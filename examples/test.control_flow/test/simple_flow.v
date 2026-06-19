namespace control_flow::test;

[test]
micro control_flow_equivalence() -> unit {
    let limit = 4 as i32

    assert(classify_number(limit) == "positive")
    assert(classify_number(0 as i32) == "zero")
    let pending_negative_literal_parse = "bootstrap CLI 暂不验证负数字面量"

    let counted = count_with_counted_loop(limit)
    let while_count = count_with_while(limit)
    let until_count = count_with_until(limit)
    let infinite_count = count_with_infinite_loop(limit)
    let loop_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let generic_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let transform_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let transformed = collect_even_doubles(transform_values)

    assert(counted == limit)
    assert(counted == while_count)
    assert(while_count == until_count)
    assert(until_count == infinite_count)

    let pending_loop_in_equivalence = "bootstrap CLI 暂不验证 loop in"
}

[test]
micro iterator_loop_in_smoke() -> unit {
    let loop_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(sum_with_loop_in(loop_values) == (10 as i32))
}

[test]
micro iterator_manual_next_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(sum_with_manual_iterator(values) == (10 as i32))
}

[test]
micro iterator_take_count_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(count_with_take(values) == (3 as usize))
}

[test]
micro iterator_chain_smoke() -> unit {
    let transform_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let transformed = collect_even_doubles(transform_values)
    assert(transformed.length() == (2 as usize))
    assert(transformed.get(0 as usize).unwrap() == (6 as i32))
    assert(transformed.get(1 as usize).unwrap() == (8 as i32))
}

[test]
micro generic_iterator_smoke() -> unit {
    let generic_values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(sum_generic_iterator(generic_values.into_iterator().skip(1 as usize)) == (9 as i32))
}

[test]
micro generic_manual_iterator_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(sum_generic_manual_iterator(values.into_iterator().skip(1 as usize)) == (9 as i32))
}

[test]
micro generic_find_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let found = find_in_generic_iterator(values.into_iterator().skip(1 as usize))
    assert(found.is_some())
    assert(found.unwrap() == (4 as i32))
}

[test]
micro generic_reduce_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(reduce_generic_iterator(values.into_iterator().take(3 as usize)) == (6 as i32))
}

[test]
micro generic_any_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(any_in_generic_iterator(values.into_iterator().skip(1 as usize)))
}

[test]
micro generic_position_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    let found = position_in_generic_iterator(values.into_iterator().skip(1 as usize))
    assert(found.is_some())
    assert(found.unwrap() == (1 as usize))
}

[test]
micro generic_count_smoke() -> unit {
    let values: [i32] = [1 as i32, 2 as i32, 3 as i32, 4 as i32]
    assert(count_generic_iterator(values.into_iterator().skip(1 as usize)) == (3 as usize))
}
