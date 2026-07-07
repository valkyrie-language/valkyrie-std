namespace core::types;

# core::types: Result<T, E>

⍝ 结果类型，表示一个操作可能成功 (`Fine`) 或失败 (`Fail`)。
⍝ 用于显式传递错误，替代异常抛出语义。
[tag(ResultKind)]
unite Result<T, E> {
    ⍝ 成功变体，携带结果值
    [tag(0)]
    Fine {
        ⍝ 操作成功的结果值
        value: T,
    },
    ⍝ 失败变体，携带错误信息
    [tag(1)]
    Fail {
        ⍝ 操作失败的错误信息
        error: E,
    },
}

imply Result<T, E> {
    ⍝ 返回成功值，`Fail` 时触发 panic
    micro unwrap(self): T {
        match self {
            case Fine(value):
                value
            case Fail(error):
                panic(error)
        }
    }

    ⍝ 返回错误值，`Fine` 时触发 panic
    micro unwrap_fail(self): E {
        match self {
            case Fine(value):
                panic(value)
            case Fail(error):
                error
        }
    }

    ⍝ 返回成功值，`Fail` 时返回 `default`
    micro unwrap_or(self, default: T): T {
        match self {
            case Fine(value):
                value
            case Fail(error):
                default
        }
    }

    ⍝ 返回成功值，`Fail` 时调用 `f` 计算替代值
    micro unwrap_or_else(self, f: micro(E) -> T): T {
        match self {
            case Fine(value):
                value
            case Fail(error):
                f(error)
        }
    }

    ⍝ 将 `Result<T, E>` 映射为 `Result<U, E>`，`Fail` 保持错误不变
    micro map<U>(self, f: micro(T) -> U): Result<U, E> {
        match self {
            case Fine(value):
                Fine(f(value))
            case Fail(error):
                Fail(error)
        }
    }

    ⍝ 链式映射，`Fine` 时调用 `f`，`Fail` 时保持错误
    micro and_then<U>(self, f: micro(T) -> Result<U, E>): Result<U, E> {
        match self {
            case Fine(value):
                f(value)
            case Fail(error):
                Fail(error)
        }
    }

    ⍝ 对两种分支分别应用回调并汇合为统一类型 `U`
    micro fold<U>(self, fine: micro(T) -> U, fail: micro(E) -> U): U {
        match self {
            case Fine(value):
                fine(value)
            case Fail(error):
                fail(error)
        }
    }
}
