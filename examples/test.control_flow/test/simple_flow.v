namespace control_flow::test;

[test]
micro control_flow_equivalence() -> unit {
    let limit = 4 as i32
    let negative = 0 as i32 - 1

    assert(classify_number(limit) == "positive")
    assert(classify_number(0 as i32) == "zero")
    assert(classify_number(negative) == "negative")

    let counted = count_with_counted_loop(limit)
    let while_count = count_with_while(limit)
    let until_count = count_with_until(limit)
    let infinite_count = count_with_infinite_loop(limit)

    assert(counted == limit)
    assert(counted == while_count)
    assert(while_count == until_count)
    assert(until_count == infinite_count)

    # pending loop_in equivalence check
    #
    # let mut ranged = 0 as i32
    # loop item in [0 as i32, 1 as i32, 2 as i32, 3 as i32] {
    #     ranged += 1
    # }
    # assert(ranged == counted)
}
