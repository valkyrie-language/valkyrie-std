[test]
micro `test utf8 iterator`() {
    let value: utf8 = Utf8Text::from_bytes([65, 194, 162, 228, 189, 160, 240, 159, 152, 128])
    let mut iter: Utf8Iterator = Utf8Iterator::new(value)

    if !iter.has_next() {
        panic("utf8 iterator has_next initial test failed")
    }

    if iter.offset() != 0 {
        panic("utf8 iterator initial offset test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() {
        panic("utf8 iterator first next test failed")
    }

    if first.unwrap() as u32 != 0x41 {
        panic("utf8 iterator first value test failed")
    }

    if iter.offset() != 1 {
        panic("utf8 iterator first offset test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() {
        panic("utf8 iterator second next test failed")
    }

    if second.unwrap() as u32 != 0xA2 {
        panic("utf8 iterator second value test failed")
    }

    if iter.offset() != 3 {
        panic("utf8 iterator second offset test failed")
    }

    let third: Option<char> = iter.next()
    if third.is_none() {
        panic("utf8 iterator third next test failed")
    }

    if third.unwrap() as u32 != 0x4F60 {
        panic("utf8 iterator third value test failed")
    }

    if iter.offset() != 6 {
        panic("utf8 iterator third offset test failed")
    }

    let fourth: Option<char> = iter.next()
    if fourth.is_none() {
        panic("utf8 iterator fourth next test failed")
    }

    if fourth.unwrap() as u32 != 0x1F600 {
        panic("utf8 iterator fourth value test failed")
    }

    if iter.offset() != 10 {
        panic("utf8 iterator fourth offset test failed")
    }

    if iter.has_next() {
        panic("utf8 iterator exhausted has_next test failed")
    }
}

[test]
micro `test utf8 iterator empty`() {
    let value: utf8 = Utf8Text::from_bytes([])
    let mut iter: Utf8Iterator = Utf8Iterator::new(value)

    if iter.has_next() {
        panic("utf8 iterator empty has_next test failed")
    }

    if iter.next().is_some() {
        panic("utf8 iterator empty next test failed")
    }

    if iter.offset() != 0 {
        panic("utf8 iterator empty offset test failed")
    }
}
