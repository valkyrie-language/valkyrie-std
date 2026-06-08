namespace std.types;

# std.types: Result<T, E>

[tag(ResultKind)]
unite Result<T, E> {
    [tag(0)]
    Fine(T)
    [tag(1, default)]
    Fail(E)
}

imply Result<T, E> {
    micro unwrap(self): T {
        match self {
            case Fine(value):
                value
            case Fail(error):
                panic(error)
        }
    }

    micro unwrap_fail(self): E {
        match self {
            case Fine(value):
                panic(value)
            case Fail(error):
                error
        }
    }

    micro unwrap_or(self, default: T): T {
        match self {
            case Fine(value):
                value
            case Fail(_):
                default
        }
    }

    micro unwrap_or_else(self, f: micro(E) -> T): T {
        match self {
            case Fine(value):
                value
            case Fail(error):
                f(error)
        }
    }

    micro map<U>(self, f: micro(T) -> U): Result<U, E> {
        match self {
            case Fine(value):
                Fine(f(value))
            case Fail(error):
                Fail(error)
        }
    }

    micro and_then<U>(self, f: micro(T) -> Result<U, E>): Result<U, E> {
        match self {
            case Fine(value):
                f(value)
            case Fail(error):
                Fail(error)
        }
    }

    micro fold<U>(self, fine: micro(T) -> U, fail: micro(E) -> U): U {
        match self {
            case Fine(value):
                fine(value)
            case Fail(error):
                fail(error)
        }
    }
}
