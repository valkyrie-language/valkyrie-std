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
