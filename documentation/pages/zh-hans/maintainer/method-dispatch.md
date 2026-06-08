# 方法分派实现

## 概述

Valkyrie 的方法分派机制在类型检查器的 Pass 3（体检查）中解析每个方法调用，确定调用目标。分派结果编码在 `HirCallResolution` 中，经过 HIR → MIR → LIR 向下传递，最终在后端生成实际的调用指令。

## 三级分派

当编译器遇到 `receiver.method(args)` 形式的调用时，按以下优先级查找：

### 第一级：class 自有方法

在 receiver 类型的 class 定义中查找名为 `method` 的方法。

- 找到 → 使用此方法，生成的 `HirDispatchKind` 为 `Static`
- 若 class 内部有同名方法但通过 `where` 子句条件特化，选择最具体的版本
- 若多个特化版本同等具体 → 报告歧义错误

### 第二级：trait 方法

在 receiver 类型满足的所有 trait 中查找名为 `method` 的方法：

- 仅一个 trait 提供 → 使用此方法，生成的 `HirDispatchKind` 为 `Witness`，记录 `(trait名, 槽索引)`
- 多个 trait 提供 → 报告歧义错误，要求调用方使用 `Trait::method(receiver)` 消歧
- 无 trait 提供 → 进入第三级

### 第三级：独立 micro

在当前作用域和所有 `using` 导入中查找独立的 `micro method`。

- 找到 → 使用此函数，生成的 `HirDispatchKind` 为 `Static`
- 未找到 → 报告"未定义的方法"错误

注意：独立 micro 禁止重载，同一作用域不能有两个同名的独立 micro。

## HirCallResolution

分派结果编码为：

```csharp
public enum HirDispatchKind
{
    Static,   // 直接按函数名调用
    Witness,  // 通过 witness table 槽索引间接调用
    Dynamic   // 通过 trait object 的 TypeInfo 动态分派
}
```

| DispatchKind | 触发条件 | LIR 指令 |
|:---|:---|:---|
| `Static` | class 自有方法 / 独立 micro | `CallStatic` |
| `Witness` | trait 方法（单 trait 命中） | `CallWitness slotIndex` |
| `Dynamic` | `dyn Trait` 调用 | `CallDynamic slotIndex`（通过 TypeInfo） |

## MRO（方法解析顺序）

MRO 仅影响 `super.method()` 在类内部的解析，不参与全局方法分派。

解析顺序：从左到右深度优先 C3 线性化。`super` 从当前类开始，沿基类列表递归查找第一个定义了 `method` 的类。

编译器在类声明检查阶段计算每个类的 MRO 序列并缓存。

## 三种消歧手段的实现

### 全限定调用 `Trait::method(receiver)`

编译器跳过三级分派流程，直接在指定 trait 的 witness table 中查找槽索引。生成 `Witness` 分派。

### using 声明

在类内部通过 `using Base1::foo` 声明显式选择基类方法。编译器在处理此类的方法调用时，优先使用 `using` 声明指定的来源。

### 包裹类型

编写一个 wrapper 类型重导出特定实现。这是常规的类定义，不涉及编译器特殊处理。

## 条件特化

class 内部可通过 `where` 子句对泛型参数做条件特化：

```valkyrie
class Container<T> {
    foo(self) where T: Add + Ord { ... }
    foo(self) where T: Copy + Add + Ord { ... }
}
```

编译器选择最具体的版本：第二个 `foo` 的约束（`Copy + Add + Ord`）严格包含第一个（`Add + Ord`），因此当 `T` 同时满足 `Copy` 时选择第二个。若两个版本的约束互相不包含，报告歧义。

## 在管线中的位置

```
TypeChecker Pass 3（体检查）
  │
  └── 遇到 receiver.method(args)
        │
        ├── 查询 class 自有方法
        │     ├── 命中 → HirDispatchKind.Static
        │     └── 未命中 ↓
        ├── 查询 trait 满足表
        │     ├── 仅一个 → HirDispatchKind.Witness(slotIndex)
        │     ├── 多个 → 歧义错误
        │     └── 无 ↓
        └── 查询独立 micro
              ├── 命中 → HirDispatchKind.Static
              └── 未命中 → "未定义的方法"错误

HirBuilder
  │
  └── 将分派结果编码为 HirCallResolution

HirToMirLowerer
  │
  └── 保留分派信息到 IKun 节点

IkunTreeToLirLowerer（LirBuilder.EmitCall）
  │
  ├── Static  → EmitStaticCall()     → CallStatic "fully.qualified.name"
  ├── Witness → EmitWitnessCall()     → CallWitness slotIndex
  └── Dynamic → EmitDynamicCall()    → CallDynamic slotIndex
```

## 动态分派（dyn Trait）

当 receiver 类型为 `dyn Trait` 时，分派变为 `Dynamic`：

1. 对象在运行时携带 TypeInfo 指针
2. 编译器生成代码从 TypeInfo 的 witness table 按槽索引查找函数指针
3. 执行间接调用

LIR 指令序列：

```text
LoadTypeInfo obj → type_info
LoadSlot type_info slotIndex → func_ptr
CallIndirect func_ptr (obj, args...)
```