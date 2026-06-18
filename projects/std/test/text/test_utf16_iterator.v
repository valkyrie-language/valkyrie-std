[test]
micro `test utf16 iterator`() {
    let value: utf16 = "A😀B"
    let mut iter: Utf16Iterator = Utf16Iterator::new(value)

    if !iter.has_next() {
        panic("utf16 iterator has_next initial test failed")
    }

    if iter.offset() != 0 {
        panic("utf16 iterator initial offset test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() {
        panic("utf16 iterator first next test failed")
    }

    if first.unwrap() as u32 != 0x41 {
        panic("utf16 iterator first value test failed")
    }

    if iter.offset() != 1 {
        panic("utf16 iterator first offset test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() {
        panic("utf16 iterator second next test failed")
    }

    if second.unwrap() as u32 != 0x1F600 {
        panic("utf16 iterator second value test failed")
    }

    if iter.offset() != 3 {
        panic("utf16 iterator second offset test failed")
    }

    let third: Option<char> = iter.next()
    if third.is_none() {
        panic("utf16 iterator third next test failed")
    }

    if third.unwrap() as u32 != 0x42 {
        panic("utf16 iterator third value test failed")
    }

    if iter.offset() != 4 {
        panic("utf16 iterator third offset test failed")
    }

    if iter.has_next() {
        panic("utf16 iterator exhausted has_next test failed")
    }

    if iter.next().is_some() {
        panic("utf16 iterator exhausted next test failed")
    }
}

[test]
micro `test utf16 iterator empty`() {
    let value: utf16 = ""
    let mut iter: Utf16Iterator = Utf16Iterator::new(value)

    if iter.has_next() {
        panic("utf16 iterator empty has_next test failed")
    }

    if iter.next().is_some() {
        panic("utf16 iterator empty next test failed")
    }

    if iter.offset() != 0 {
        panic("utf16 iterator empty offset test failed")
    }
}
