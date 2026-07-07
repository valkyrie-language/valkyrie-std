namespace core::types;

# core::types: Option<T>

⍝ 可选值类型，表示一个值可能存在 (`Some`) 或缺失 (`None`)。
⍝ 用于安全地处理可能缺席的值，替代裸空指针语义。
[tag(OptionKind)]
unite Option<T> {
    ⍝ 包含一个有效值的变体
    [tag(0)]
    Some {
        ⍝ 被包裹的实际值
        value: T,
    },
    ⍝ 缺失值变体，作为该联合的默认变体
    [tag(1, default)]
    None,
}

⍝ 构造一个包含给定值的 `Some`
micro Some<T>(value: T) -> Option<T> {
    let wrapped: Option<T> = Some(value)
    return wrapped
}

⍝ 构造一个缺失的 `None`
micro option_none<T>() -> Option<T> {
    let empty: Option<T> = None
    return empty
}

imply Option<T> {
    ⍝ 当且仅当为 `Some` 时返回 `true`
    micro is_some(self): bool {
        match self {
            case Some(value):
                true
            case None:
                false
        }
    }

    ⍝ 当且仅当为 `None` 时返回 `true`
    micro is_none(self): bool {
        match self {
            case Some(value):
                false
            case None:
                true
        }
    }

    ⍝ 返回内部值，`None` 时触发 panic
    micro unwrap(self): T {
        match self {
            case Some(value):
                value
            case None:
                panic("unwrap on `None` value")
        }
    }

    ⍝ 返回内部值，`None` 时返回 `default`
    micro unwrap_or(self, default: T): T {
        match self {
            case Some(value):
                value
            case None:
                default
        }
    }

    ⍝ 返回内部值，`None` 时调用 `f` 计算替代值
    micro unwrap_or_else(self, f: micro() -> T): T {
        match self {
            case Some(value):
                value
            case None:
                f()
        }
    }

    ⍝ 将 `Option<T>` 映射为 `Option<U>`，`None` 保持不变
    micro map<U>(self, f: micro(T) -> U): Option<U> {
        match self {
            case Some(value):
                Some(f(value))
            case None:
                option_none::<U>()
        }
    }

    ⍝ 映射并返回默认值，`None` 时返回 `default`
    micro map_or<U>(self, default: U, f: micro(T) -> U): U {
        match self {
            case Some(value):
                f(value)
            case None:
                default
        }
    }

    ⍝ 链式映射，`Some` 时调用 `f`，`None` 时保持缺失
    micro and_then<U>(self, f: micro(T) -> Option<U>): Option<U> {
        match self {
            case Some(value):
                f(value)
            case None:
                option_none::<U>()
        }
    }

    ⍝ `None` 时调用 `f` 提供替代的 `Option<T>`
    micro or_else(self, f: micro() -> Option<T>): Option<T> {
        match self {
            case Some(value):
                Some(value)
            case None:
                f()
        }
    }

    ⍝ 按谓词过滤内部值，不满足时变为 `None`
    micro filter(self, predicate: micro(T) -> bool): Option<T> {
        match self {
            case Some(value) if predicate(value):
                Some(value)
            else:
                None
        }
    }

    ⍝ 将 `Option<Option<T>>` 摊平为 `Option<T>`
    micro flatten(self: Option<Option<T>>): Option<T> {
        match self {
            case Some(value):
                value
            case None:
                None
        }
    }
}
