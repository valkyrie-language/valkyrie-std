[test]
micro `test utf16 text features`() {
    let value: utf16 = "hello"

    if value.is_empty() {
        panic("utf16 is_empty test failed")
    }

    if !value.contains("ell") {
        panic("utf16 contains test failed")
    }

    if !value.starts_with("he") {
        panic("utf16 starts_with test failed")
    }

    if !value.ends_with("lo") {
        panic("utf16 ends_with test failed")
    }

    if value.index_of("ll") != 2 {
        panic("utf16 index_of test failed")
    }

    let part: utf16 = value.substring(1, 3)
    if part.length() != 3 {
        panic("utf16 substring length test failed")
    }

    if !part.starts_with("el") {
        panic("utf16 substring starts_with test failed")
    }

    let merged: utf16 = value.concat("!")
    if !merged.ends_with("!") {
        panic("utf16 concat test failed")
    }

    let padded: utf16 = "  hello  "
    let trimmed: utf16 = padded.trim()
    if !trimmed.equals("hello") {
        panic("utf16 trim test failed")
    }

    let upper: utf16 = value.to_upper()
    if !upper.equals("HELLO") {
        panic("utf16 to_upper test failed")
    }

    let lower: utf16 = upper.to_lower()
    if !lower.equals("hello") {
        panic("utf16 to_lower test failed")
    }

    let replaced: utf16 = value.replace("ll", "yy")
    if !replaced.equals("heyyo") {
        panic("utf16 replace test failed")
    }
}
