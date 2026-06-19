namespace std.collection.test;

[test]
micro `test iterator collect to array`() {
    let result: [i32] = [1, 2, 3]
        .into_iterator()
        .map(micro(value: i32) -> i32 {
            return value + 1
        })
        .collect()

    if result.length != 3 {
        panic("iterator collect array length test failed")
    }

    if result[0] != 2 || result[1] != 3 || result[2] != 4 {
        panic("iterator collect array value test failed")
    }
}

[test]
micro `test iterator collect to array list`() {
    let result: ArrayList<i32> = [1, 2, 3]
        .into_iterator()
        .skip(1)
        .collect()

    if result.length() != 2 {
        panic("iterator collect array list length test failed")
    }

    if result.get(0).unwrap() != 2 || result.get(1).unwrap() != 3 {
        panic("iterator collect array list value test failed")
    }
}

[test]
micro `test iterator take count and collect`() {
    let taken_count: usize = [1, 2, 3, 4]
        .into_iterator()
        .take(2)
        .count()

    if taken_count != 2 {
        panic("iterator take count test failed")
    }

    let result: [i32] = [1, 2, 3, 4]
        .into_iterator()
        .take(3)
        .collect_array()

    if result.length != 3 {
        panic("iterator take collect length test failed")
    }

    if result[0] != 1 || result[1] != 2 || result[2] != 3 {
        panic("iterator take collect value test failed")
    }
}

[test]
micro `test iterator find and position`() {
    let found: Option<i32> = [1, 2, 3, 4]
        .into_iterator()
        .find(micro(value: i32) -> bool {
            return value > 2
        })

    if found.is_none() || found.unwrap() != 3 {
        panic("iterator find value test failed")
    }

    let position: Option<usize> = [1, 2, 3, 4]
        .into_iterator()
        .position(micro(value: i32) -> bool {
            return value == 4
        })

    if position.is_none() || position.unwrap() != 3 {
        panic("iterator position value test failed")
    }

    let missing: Option<i32> = [1, 2]
        .into_iterator()
        .find(micro(value: i32) -> bool {
            return value == 9
        })

    if missing.is_some() {
        panic("iterator find missing value test failed")
    }
}

[test]
micro `test iterator all and contains`() {
    let all_positive: bool = [1, 2, 3, 4]
        .into_iterator()
        .all(micro(value: i32) -> bool {
            return value > 0
        })

    if !all_positive {
        panic("iterator all value test failed")
    }

    let all_even: bool = [2, 4, 5]
        .into_iterator()
        .all(micro(value: i32) -> bool {
            return value % 2 == 0
        })

    if all_even {
        panic("iterator all false test failed")
    }

    if ![1, 2, 3].into_iterator().contains(2) {
        panic("iterator contains existing value test failed")
    }

    if [1, 2, 3].into_iterator().contains(9) {
        panic("iterator contains missing value test failed")
    }
}

[test]
micro `test iterator first last and nth`() {
    let first_value: Option<i32> = [4, 5, 6]
        .into_iterator()
        .first()

    if first_value.is_none() || first_value.unwrap() != 4 {
        panic("iterator first value test failed")
    }

    let last_value: Option<i32> = [4, 5, 6]
        .into_iterator()
        .last()

    if last_value.is_none() || last_value.unwrap() != 6 {
        panic("iterator last value test failed")
    }

    let third_value: Option<i32> = [4, 5, 6]
        .into_iterator()
        .nth(2)

    if third_value.is_none() || third_value.unwrap() != 6 {
        panic("iterator nth value test failed")
    }

    let empty_first: Option<i32> = ([] as [i32])
        .into_iterator()
        .first()

    if empty_first.is_some() {
        panic("iterator first empty test failed")
    }

    let missing_nth: Option<i32> = [4, 5]
        .into_iterator()
        .nth(3)

    if missing_nth.is_some() {
        panic("iterator nth missing value test failed")
    }
}

[test]
micro `test iterator take_while and skip_while`() {
    let taken: [i32] = [1, 2, 3, 1]
        .into_iterator()
        .take_while(micro(value: i32) -> bool {
            return value < 3
        })
        .collect_array()

    if taken.length != 2 || taken[0] != 1 || taken[1] != 2 {
        panic("iterator take_while value test failed")
    }

    let skipped: [i32] = [1, 2, 3, 1]
        .into_iterator()
        .skip_while(micro(value: i32) -> bool {
            return value < 3
        })
        .collect_array()

    if skipped.length != 2 || skipped[0] != 3 || skipped[1] != 1 {
        panic("iterator skip_while value test failed")
    }

    let empty: [i32] = []
    let empty_taken: Option<i32> = empty
        .into_iterator()
        .take_while(micro(value: i32) -> bool {
            return value > 0
        })
        .first()

    if empty_taken.is_some() {
        panic("iterator take_while empty test failed")
    }
}

[test]
micro `test iterator filter_map`() {
    let result: [i32] = [1, 2, 3, 4]
        .into_iterator()
        .filter_map(micro(value: i32) -> Option<i32> {
            if value % 2 == 0 {
                return Some(value * 10)
            }

            return None
        })
        .collect_array()

    if result.length != 2 || result[0] != 20 || result[1] != 40 {
        panic("iterator filter_map value test failed")
    }

    let missing: Option<i32> = [1, 3, 5]
        .into_iterator()
        .filter_map(micro(value: i32) -> Option<i32> {
            if value % 2 == 0 {
                return Some(value)
            }

            return None
        })
        .first()

    if missing.is_some() {
        panic("iterator filter_map empty test failed")
    }
}
