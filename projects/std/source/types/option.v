namespace std.types;

# std.types: Option<T>

[tag(OptionKind)]
unite Option<T> {
    [tag(0)]
    Some(T)
    [tag(1, default)]
    None
}

imply Option<T> {
    micro is_some(self): bool {
        match self {
            case Some(value):
                true
            case None:
                false
        }
    }

    micro is_none(self): bool {
        match self {
            case Some(value):
                false
            case None:
                true
        }
    }

    micro unwrap(self): T {
        match self {
            case Some(value):
                value
            case None:
                T.default
        }
    }

    micro unwrap_or(self, default: T): T {
        match self {
            case Some(value):
                value
            case None:
                default
        }
    }

    micro unwrap_or_else(self, f: micro() -> T): T {
        match self {
            case Some(value):
                value
            case None:
                f()
        }
    }

    micro map<U>(self, f: micro(T) -> U): Option<U> {
        match self {
            case Some(value):
                Some(f(value))
            case None:
                None
        }
    }

    micro map_or<U>(self, default: U, f: micro(T) -> U): U {
        match self {
            case Some(value):
                f(value)
            case None:
                default
        }
    }

    micro and_then<U>(self, f: micro(T) -> Option<U>): Option<U> {
        match self {
            case Some(value):
                f(value)
            case None:
                None
        }
    }

    micro or_else(self, f: micro() -> Option<T>): Option<T> {
        match self {
            case Some(value):
                Some(value)
            case None:
                f()
        }
    }

    micro filter(self, pred: micro(T) -> bool): Option<T> {
        match self {
            case Some(value):
                if pred(value) {
                    Some(value)
                } else {
                    None
                }
            case None:
                None
        }
    }

    micro flatten(self: Option<Option<T>>): Option<T> {
        match self {
            case Some(value):
                value
            case None:
                None
        }
    }
}
