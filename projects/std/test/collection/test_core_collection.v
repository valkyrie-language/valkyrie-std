namespace std.collections.test;

[test]
micro `test array helpers`() {
    let values: [i32] = [1, 2, 3]

    if array_len(values) != 3 {
        panic("array len test failed")
    }

    if array_length(values) != 3 {
        panic("array length test failed")
    }

    if array_is_empty(values) {
        panic("array is_empty test failed")
    }

    if array_get(values, 1).unwrap() != 2 {
        panic("array get test failed")
    }

    if array_first(values).unwrap() != 1 {
        panic("array first test failed")
    }

    if array_last(values).unwrap() != 3 {
        panic("array last test failed")
    }

    if !array_contains(values, 2) {
        panic("array contains test failed")
    }
}

[test]
micro `test fixed array helpers`() {
    let values: [i32] = [4, 5, 6]

    if fixed_array_len(values) != 3 {
        panic("fixed array len test failed")
    }

    if fixed_array_length(values) != 3 {
        panic("fixed array length test failed")
    }

    if fixed_array_is_empty(values) {
        panic("fixed array is_empty test failed")
    }

    if fixed_array_get(values, 2).unwrap() != 6 {
        panic("fixed array get test failed")
    }

    if fixed_array_first(values).unwrap() != 4 {
        panic("fixed array first test failed")
    }

    if fixed_array_last(values).unwrap() != 6 {
        panic("fixed array last test failed")
    }

    if !fixed_array_contains(values, 5) {
        panic("fixed array contains test failed")
    }
}

[test]
micro `test array list host binding`() {
    let list: ArrayList<i32> = ArrayList.new(0)
    list.push(1)
    list.push(2)
    list.push(3)

    if list.length() != 3 {
        panic("array list length test failed")
    }

    if list.length != 3 {
        panic("array list property test failed")
    }

    if list.get(1).unwrap() != 2 {
        panic("array list get test failed")
    }

    list.set(1, 9)
    if list.get(1).unwrap() != 9 {
        panic("array list set test failed")
    }

    if !list.contains(9) {
        panic("array list contains test failed")
    }

    if list.first().unwrap() != 1 {
        panic("array list first test failed")
    }

    if list.last().unwrap() != 3 {
        panic("array list last test failed")
    }

    if list.remove(1).unwrap() != 9 {
        panic("array list remove test failed")
    }

    if list.length() != 2 {
        panic("array list remove length test failed")
    }

    list.clear()
    if !list.is_empty() {
        panic("array list clear test failed")
    }
}
