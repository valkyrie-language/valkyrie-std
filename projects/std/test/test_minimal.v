namespace std.types;

unite Test {
    A(T)
    B
}

imply Test {
    micro unwrap(self): T {
        match self {
            case A(value):
                value
            case B:
                T.default
        }
    }
}