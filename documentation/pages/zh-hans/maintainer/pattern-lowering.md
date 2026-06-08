# 模式匹配降级

## 概述

Valkyrie 的 `match` 表达式在 HIR 层保留为语义节点，在 MIR 降级阶段被展开为条件判断和跳转，最终在 LIR 层生成对应的控制流指令。

## 在管线中的位置

```
HIR
  │
  ├── HirMatchNode（语义节点：保留模式结构）
  │
  ▼
MIR（HirToMirLowerer）
  │
  ├── 模式编译为决策树
  ├── 生成 IKunMatch / IKunMatchCase 节点
  ├── 执行穷尽性检查
  │
  ▼
LIR（IkunTreeToLirLowerer）
  │
  ├── IKunMatch → 条件跳转链 / 跳转表
  └── IKunMatchCase → 基本块
```

## 模式类型

| 模式 | 语法 | MIR 降级策略 |
|:---|:---|:---|
| 通配 | `_` | 无条件匹配，总是成功 |
| 绑定 | `x` | 无条件匹配 + 变量绑定 |
| 字面量 | `42`、`"hello"`、`true` | 值相等比较 |
| 枚举 | `Option.Some(x)` | 先检查判值，再递归匹配 payload |
| 元组 | `(x, y)` | 按位置顺序匹配各元素 |
| 命名结构 | `Point { x, y }` | 按字段名匹配，支持嵌套 |
| 列表 | `[head, ..tail]` | 先检查长度，再按模式解构元素 |
| 引用 | `ref x` | 绑定为引用而非拷贝 |
| 类型强制 | `x as i32` | 运行时类型检查 + 绑定 |

## 穷尽性检查

在 HIR 构建阶段，编译器验证 `match` 表达式覆盖了被匹配类型的所有可能值：

- `bool`：必须覆盖 `true` 和 `false`
- `enums`：必须覆盖所有判值，或者有通配分支
- `union`：必须覆盖所有变体，或者有通配分支
- `Option<T>`：必须覆盖 `Some` 和 `None`
- `Result<T, E>`：必须覆盖 `Ok` 和 `Err`

穷尽性检查在模式编译之前执行。若检查失败，报告编译错误而非生成缺省分支。

## 决策树编译

模式匹配被编译为决策树，优化目标是减少平均比较次数：

1. **收集所有分支的模式**，提取公共前缀
2. **按区分度排序**：优先检查能最快缩小候选集的模式
3. **生成 IKunMatch 节点**：
   - 简单值比较 → IKunMatch 直接映射为 if-else 链
   - 枚举/union → 优先编译为跳转表（若判值密集且连续）
   - 列表/结构 → 逐字段展开为嵌套的 if-else

## 跳转表优化

当匹配目标是枚举且分支覆盖了连续判值时，编译器生成跳转表（switch table）代替 if-else 链：

```
match status {
    case Inactive → ...
    case Active   → ...
    case Suspended → ...
}
```

编译为：

```text
// 将判值加载到寄存器
load_discriminant status → tmp
// 跳转表：[Inactive, Active, Suspended]
jump_table tmp → [&case_0, &case_1, &case_2]
```

跳转表在 MIR 层表现为 `IKunJumpTable` 节点，在 LIR 层生成 `Switch` 指令。

## 守卫（when 子句）

`case pattern when guard` 被编译为嵌套条件：

```
match value {
    case x when x > 0 → ...
    case x            → ...
}
```

编译为：

```text
if (value matches case_1_pattern) {
    if (guard_condition) { jump case_1_body }
    else { fallthrough }
}
if (value matches case_2_pattern) {
    jump case_2_body
}
```

守卫条件在模式匹配成功后才求值。守卫失败时继续尝试下一个分支。

## 与效应系统的交互

当 `match` 分支包含可能产生领域错误的表达式时，效应传播发生在各分支内部，不影响分支选择：

```valkyrie
match result {
    case Ok(v) → process(v)?
    case Err(e) → default_value
}
```

`process(v)?` 的 `?` 短路只在 `Ok` 分支内生效。整个 `match` 表达式的效应为各分支效应的并集。

## LIR 输出

模式匹配降级后在 LIR 层表现为以下结构：

| MIR 节点 | LIR 产物 |
|:---|:---|
| `IKunMatch` | 基本块链 + 条件跳转 |
| `IKunMatchCase` | 单个基本块 |
| `IKunJumpTable` | `Switch` 指令 + 跳转表 |
| `IKunEnumDiscriminant` | `LoadField` 指令加载判值 |