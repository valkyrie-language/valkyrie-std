[test]
micro `test utf8 view full and slice`() {
    let value: utf8 = Utf8Text::from_bytes([104, 101, 108, 108, 111])
    let view: Utf8View = Utf8View::new(value)

    if view.is_empty() {
        panic("utf8 view is_empty test failed")
    }

    if view.byte_length() != 5 {
        panic("utf8 view byte_length test failed")
    }

    let full_span: TextSpan = view.span()
    if full_span.offset != 0 || full_span.length != 5 {
        panic("utf8 view full span test failed")
    }

    let part: Utf8Text = view.slice(TextSpan {
        offset: 1,
        length: 3,
    })
    if !part.equals(Utf8Text::from_bytes([101, 108, 108])) {
        panic("utf8 view slice test failed")
    }
}

[test]
micro `test utf8 view nested span`() {
    let value: utf8 = Utf8Text::from_bytes([104, 101, 108, 108, 111])
    let view: Utf8View = Utf8View::new(value, TextSpan {
        offset: 1,
        length: 3,
    })

    let nested: Utf8View = view.view(TextSpan {
        offset: 1,
        length: 1,
    })
    let nested_span: TextSpan = nested.span()
    if nested_span.offset != 2 || nested_span.length != 1 {
        panic("utf8 view nested span test failed")
    }

    if !nested.to_text().equals(Utf8Text::from_bytes([108])) {
        panic("utf8 view nested to_text test failed")
    }
}

[test]
micro `test utf8 view clamp`() {
    let value: utf8 = Utf8Text::from_bytes([104, 101, 108, 108, 111])
    let view: Utf8View = Utf8View::new(value, TextSpan {
        offset: 3,
        length: 10,
    })

    let span: TextSpan = view.span()
    if span.offset != 3 || span.length != 2 {
        panic("utf8 view clamp span test failed")
    }

    if !view.to_text().equals(Utf8Text::from_bytes([108, 111])) {
        panic("utf8 view clamp to_text test failed")
    }
}
