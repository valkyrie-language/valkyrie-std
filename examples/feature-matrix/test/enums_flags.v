namespace feature_matrix::test;

enums Color {
    Red
    Green
    Blue
}

unite Option<T> {
    Some(T)
    None
}

flags FilePerm {
    Read = 1
    Write = 2
}

[test]
micro enums_flags_parse() -> unit {
}
