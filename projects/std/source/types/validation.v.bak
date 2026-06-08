namespace std.types;

# std.types: Validation<T, E>

unite Validation<T, E> {
    Success { value: T, errors: Vector<E> }
    Failure { fatal: E, errors: Vector<E> }
}

imply Validation<T, E> {
    micro is_success(self): bool {
        match self {
            case Success { value, errors }:
                true
            case Failure { fatal, errors }:
                false
        }
    }

    micro is_failure(self): bool {
        match self {
            case Success { value, errors }:
                false
            case Failure { fatal, errors }:
                true
        }
    }

    micro errors(self): Vector<E> {
        match self {
            case Success { value, errors }:
                errors
            case Failure { fatal, errors }:
                errors
        }
    }

    micro to_result(self): Result<T, E> {
        match self {
            case Success { value, errors }:
                Fine { value: value }
            case Failure { fatal, errors }:
                Fail { error: fatal }
        }
    }

    micro map<U>(self, f: micro(T) -> U): Validation<U, E> {
        match self {
            case Success { value, errors }:
                Success { value: f(value), errors: errors }
            case Failure { fatal, errors }:
                Failure { fatal: fatal, errors: errors }
        }
    }

    micro and_then<U>(self, f: micro(T) -> Validation<U, E>): Validation<U, E> {
        match self {
            case Success { value, errors }:
                match f(value) {
                    case Success { value, errors: next_errors }:
                        Success { value: value, errors: errors.concat(next_errors) }
                    case Failure { fatal, errors: next_errors }:
                        Failure { fatal: fatal, errors: errors.concat(next_errors) }
                }
            case Failure { fatal, errors }:
                Failure { fatal: fatal, errors: errors }
        }
    }

    micro fold<U>(self, on_success: micro(T, Vector<E>) -> U, on_failure: micro(E, Vector<E>) -> U): U {
        match self {
            case Success { value, errors }:
                on_success(value, errors)
            case Failure { fatal, errors }:
                on_failure(fatal, errors)
        }
    }
}
