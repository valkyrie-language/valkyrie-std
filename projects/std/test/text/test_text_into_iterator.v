[test]
micro `test utf8 text into_iterator count and skip`() {
    let value: utf8 = Utf8Text::from_bytes([65, 228, 189, 160, 66])

    if value.into_iterator().count() != 3 {
        panic("utf8 text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(1)
    if !iter.has_next() {
        panic("utf8 text into_iterator skip has_next test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() || first.unwrap() as u32 != 0x4F60 {
        panic("utf8 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() as u32 != 0x42 {
        panic("utf8 text into_iterator skip second value test failed")
    }
}

[test]
micro `test utf16 text into_iterator count and skip`() {
    let value: utf16 = "A😀B"

    if value.into_iterator().count() != 3 {
        panic("utf16 text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(1)
    if !iter.has_next() {
        panic("utf16 text into_iterator skip has_next test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() || first.unwrap() as u32 != 0x1F600 {
        panic("utf16 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() as u32 != 0x42 {
        panic("utf16 text into_iterator skip second value test failed")
    }
}

[test]
micro `test ascii text into_iterator count and skip`() {
    let value: ascii = AsciiText {
        _bytes: [65, 66, 67]
    }

    if value.into_iterator().count() != 3 {
        panic("ascii text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(2)
    if !iter.has_next() {
        panic("ascii text into_iterator skip has_next test failed")
    }

    let last: Option<char> = iter.next()
    if last.is_none() || last.unwrap() as u32 != 0x43 {
        panic("ascii text into_iterator skip value test failed")
    }
}
