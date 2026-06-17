namespace std.adaptor.clr.utf16;

[test]
micro `test string length`() {
    let value: utf16 = "xxx"
    let actual: isize = value.length()

    @assert(actual == 3, "clr string length test failed")
}
