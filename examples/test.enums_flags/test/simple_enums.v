namespace enums_flags::test;

enums Status { Active = 0, Inactive = 1 }

[test]
micro simple_enums() -> unit {
    let s = Status::Active
    print("enums ok")
}
