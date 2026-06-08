# trait 推导与 Witness Table

## 概述

Valkyrie 的 trait 系统采用结构子类型（structural subtyping），编译器在语义分析阶段自动判断每个类型是否满足 trait，无需显式声明。此过程在类型检查器的 Pass 2（声明检查）中执行。

## 结构推导算法

### 输入

- 所有已声明的 trait 定义（来自全局 Scope）
- 所有已声明的 class/structure 定义（来自全局 Scope）

### 推导步骤

对每个类型 `T` 和每个 trait `A`：

**第一步：检查方法签名覆盖**

遍历 trait `A` 要求的每个方法签名，在类型 `T` 的方法集中查找匹配：

- 方法名相同
- 参数数量相同
- 每个参数类型兼容（目标 trait 参数类型可赋值给源类型参数）
- 返回类型兼容（源返回类型可赋值给目标 trait 返回类型）

若全部匹配，进入第二步。

**第二步：推断关联类型**

trait 可以声明关联类型（`type Item`、`type Iter`）。推导器从匹配到的实现方法签名中推断关联类型的具体映射：

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>
    into_iterator(self) -> Self::Iter
}
```

从 `into_iterator` 的返回类型推断出 `Iter`，再从 `Iter` 的 `Iterator` 实现推断出 `Item`。

**第三步：验证关联类型约束**

trait 中对关联类型的约束（如 `Iter: Iterator<Item = Self::Item>`）需要在第二步推断完成后验证。若推断的关联类型不满足约束，该类型不满足此 trait。

**第四步：建立满足关系**

通过以上检查的类型 `T` 被标记为满足 trait `A`，编译器记录此关系用于后续类型检查和代码生成。

### 复杂度控制

推导是 **O(N × M)** 的，其中 N 为类型数量，M 为 trait 数量。但 trait 通常远少于类型，且方法签名比对是常量时间的字符串匹配，因此实际开销可忽略。

## Witness Table

### 概念

witness table 是编译器生成的编译期数据结构，记录"类型 `T` 满足 trait `A`"的证据。每条记录包含：

- trait 名
- 目标类型名
- 每个 trait 方法对应的实现函数签名
- 槽索引（slot index）：trait 方法在 witness table 中的位置

### 生成时机

在类型检查器确认结构推导结果后，为每个成功的 `(T, A)` 对生成一条 witness table 条目。

### 编译期表示

```csharp
// (TraitName, SlotIndex, MethodName, TargetTypeName, ImplementationFunctionName)
GenerateWitnessDispatchEntry binding
```

条目集合为静态全局表，运行时通过 `(TraitName, SlotIndex)` 键查找 `(TargetTypeName, ImplementationFunctionName)`。

### 运行时表示

在 NyarVM 中，witness table 以函数指针表形式存在。编译期生成的 witness entry 被编码为模块元数据，运行时加载后构建指针表。

## Aura trait

Aura trait 是语义 trait，需要显式声明，不能仅凭形状推导：

| trait | 说明 |
|:---|:---|
| `Serializable` | 可序列化 |
| `Sendable` | 可跨线程发送 |
| `Syncable` | 可跨线程共享 |
| `Cloneable` | 可克隆 |

Aura trait 的满足关系由程序员显式声明或由编译器对特定场景自动注入（如 `structure` 自动获得 `Cloneable`）。外部类型绝不自动获得 Aura trait，必须通过包裹类封装。

## 在管线中的位置

```
TypeChecker Pass 2
  ├── 声明检查
  │     ├── trait 定义验证
  │     └── 结构推导（遍历所有 类型 × trait 对）
  │           └── 生成 witness table 条目
  ├── Pass 3: 体检查
  │     └── 使用 trait 满足关系验证类型约束
  └── SemanticModel
        ├── 已解析符号表
        ├── trait 满足关系表
        └── witness table 条目集合
```

## 与多文件编译的关系

多文件场景中，trait 推导在全局声明收集完成后统一执行。详见 [multi-file.md](multi-file.md)。

## 对下游的影响

### HIR

`HirTypeDef` 中不直接记录 trait 满足关系，此关系保留在 `SemanticModel` 中为 `HirBuilder` 所用。`HirBuilder` 在构建方法分派时查询 trait 满足关系。

### LIR

witness table 条目在 LIR 构建阶段被编码为 `GenerateWitnessDispatchEntry`，注入到 `GenerateModule` 的元数据段。