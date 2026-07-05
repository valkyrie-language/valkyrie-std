namespace feature_matrix::test;

mezzo BoxOf(T: type) -> type {
    T
}

macro double(x) = x + x

[test]
micro mezzo_and_macro_declarations_exist() -> unit {
}
