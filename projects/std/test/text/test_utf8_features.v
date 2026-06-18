[test]
micro `test utf8 text features`() {
    let value: utf8 = Utf8Text::from_bytes([104, 101, 108, 108, 111])

    if value.is_empty() {
        panic("utf8 is_empty test failed")
    }

    if value.byte_length() != 5 {
        panic("utf8 byte_length test failed")
    }

    if value.length() != 5 {
        panic("utf8 length test failed")
    }

    if !value.contains(Utf8Text::from_bytes([101, 108, 108])) {
        panic("utf8 contains test failed")
    }

    if !value.starts_with(Utf8Text::from_bytes([104, 101])) {
        panic("utf8 starts_with test failed")
    }

    if !value.ends_with(Utf8Text::from_bytes([108, 111])) {
        panic("utf8 ends_with test failed")
    }

    if value.index_of(Utf8Text::from_bytes([108, 108])) != 2 {
        panic("utf8 index_of test failed")
    }

    let part: utf8 = utf8_substr(value, 1, 3)
    if part.length() != 3 {
        panic("utf8 substring length test failed")
    }

    if !part.equals(Utf8Text::from_bytes([101, 108, 108])) {
        panic("utf8 substring equals test failed")
    }

    let merged: utf8 = value.concat(Utf8Text::from_bytes([33]))
    if !merged.ends_with(Utf8Text::from_bytes([33])) {
        panic("utf8 concat test failed")
    }
}
