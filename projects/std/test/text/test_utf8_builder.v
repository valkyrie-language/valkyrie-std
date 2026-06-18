[test]
micro `test utf8 builder append and build`() {
    let mut builder: Utf8Builder = Utf8Builder::new(8)
    builder.append(Utf8Text::from_bytes([104, 101]))
    builder.append(Utf8Text::from_bytes([108, 108, 111]))

    if builder.is_empty() {
        panic("utf8 builder is_empty test failed")
    }

    if builder.byte_length() != 5 {
        panic("utf8 builder byte_length test failed")
    }

    let value: utf8 = builder.build()
    if !value.equals(Utf8Text::from_bytes([104, 101, 108, 108, 111])) {
        panic("utf8 builder build test failed")
    }
}

[test]
micro `test utf8 builder concat`() {
    let mut left: Utf8Builder = Utf8Builder::new(4)
    left.append(Utf8Text::from_bytes([104, 101]))

    let mut right: Utf8Builder = Utf8Builder::new(4)
    right.append(Utf8Text::from_bytes([108, 108, 111]))

    let value: utf8 = left.concat(right).build()
    if !value.equals(Utf8Text::from_bytes([104, 101, 108, 108, 111])) {
        panic("utf8 builder concat test failed")
    }
}

[test]
micro `test utf8 builder from text`() {
    let builder: Utf8Builder = Utf8Builder::new(Utf8Text::from_bytes([97, 98, 99]))
    if builder.byte_length() != 3 {
        panic("utf8 builder from text length test failed")
    }

    if !builder.build().equals(Utf8Text::from_bytes([97, 98, 99])) {
        panic("utf8 builder from text build test failed")
    }
}
