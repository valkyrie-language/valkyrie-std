namespace core::types;

⍝ ==========================================================================
⍝ 类型转换 trait 体系
⍝
⍝ Valkyrie 严格区分三种转换语义：
⍝   as    — 强制转换（可能丢失信息），通过 As<T> trait 支持用户重载
⍝   to    — 值级转换（创建新值），通过 To<T> trait 支持用户重载
⍝   into  — 消耗性转换（移动所有权），通过 Into<T> trait 支持用户重载
⍝
⍝ 原始类型之间、子类型向上转型、row 成员裁减自动支持 as，
⍝ 无需用户自定义 As trait 实现。
⍝ ==========================================================================

⍝ 强制转换 trait
⍝ 用于使 `value as Target` 语法生效。
⍝ 实现此 trait 后，该类型对即可使用 `as` 运算符。
⍝ 注意：`as` 转换可能丢失信息（如 i32 → u8 截断），用户需自行保证安全性。
trait As<T> {
    ⍝ 将自身强制转换为 T
    ⍝ 无开销或开销极小，不消耗自身
    micro as_type(self, target_type: type<T>) -> T?;
}

⍝ 值级转换 trait
⍝ 用于使 `value.to::<T>()` 语法生效（可手动转为 `to_xxx()` 方法族）。
⍝ 此转换有开销（如分配新对象）但不消耗原始数据。
⍝ 转换可失败，返回 Option<T>。
trait To<T> {
    ⍝ 将自身转换为 T，可能失败
    ⍝ 有开销但不消耗自身，失败时返回 None
    micro to_type(self, target_type: type<T>) -> Option<T>;
}

⍝ 消耗性转换 trait
⍝ 用于使 `value.into::<T>()` 语法生效（可手动转为 `into_xxx()` 方法族）。
⍝ 转换消耗调用者（移动所有权），无论是否有开销。
trait Into<T> {
    ⍝ 将自身转换为 T，消耗自身
    ⍝ 移动所有权到返回值
    micro into_type(self, target_type: type<T>) -> T;
}