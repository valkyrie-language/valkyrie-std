namespace feature_matrix.test;

unite Option<T> {
    Some {
        value: T,
    },
    None,
}

enums Color {
    RED   = 2,
    GREEN = 4,
    BLUE  = 6,
}


flags FilePerm {
    READ  = 1,
    WRITE = 2,
}

[test]
micro enums_flags_parse() -> unit {}
