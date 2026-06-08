# LIR 降级：类型映射与分派

## 概述

LIR（Low-level Intermediate Representation）是 MIR（EGraph + IKun）到 `GenerateModule`（Nyar Standard IR）的降级层。由 `LirBuilder` 完成转换。

## 在管线中的位置

```
EGraph<IKun> → ⑥ Nyar.Optimizer → IKunTree → ⑦ IkunTreeToLirLowerer → GenerateModule → ⑧ Backend
```

LIR 消费优化后的线性 `IKunTree`，输出平台无关的 `GenerateModule`。不做 ABI 决策——对象布局和调用约定由各后端独立决定。

## 类型映射

`LirBuilder.MapTypeNameToValueType` 将类型名映射为 `GenerateValueType`：

| 类型名 | GenerateValueType | 说明 |
|:---|:---|:---|
| `void` | Void | 空返回 |
| `bool` | Bool | 布尔 |
| `i8` | I8 | 有符号 8 位 |
| `i16` | I16 | 有符号 16 位 |
| `i32` | I32 | 有符号 32 位 |
| `i64` | I64 | 有符号 64 位 |
| `f32` | F32 | 单精度浮点 |
| `f64` | F64 | 双精度浮点 |
| `string` / `utf8` / `utf16` / `utf32` | String | 字符串 |
| 枚举 / 标志 | 底层整数类型 | 判值作为常量比较 |
| 结构体 / unite | Struct | 值类型内联布局 |
| 类 / union / trait | ExternRef | 引用类型 |

非基元类型（class、union、trait）映射为 `ExternRef`，其具体布局信息由 `LirTypeDef` 表提供。

## LirTypeDef

```csharp
public sealed record LirTypeDef(
    string Name,
    GenerateValueType BaseType,
    IReadOnlyList<LirFieldDef> Fields,
    IReadOnlyList<int> GcPointerFieldIndices,
    int? EnumUnderlyingType
);

public sealed record LirFieldDef(
    string Name,
    GenerateValueType Type,
    int Offset,
    int Size
);
```

| 字段 | 说明 |
|:---|:---|
| `Name` | 类型名称 |
| `BaseType` | LIR 基类型 |
| `Fields` | 字段列表（含偏移和大小） |
| `GcPointerFieldIndices` | GC 扫描时需追踪的字段索引 |
| `EnumUnderlyingType` | 枚举的底层整数类型 |

类型定义表在 `LirModule` 构建时一并生成，供后端查询。LIR 不做 ABI 决策，对象布局由各后端自行完成。

## 调用分派

`EmitCall` 根据 `HirDispatchKind` 选择分派策略：

### Static 分派

直接按函数名调用，生成 `CallStatic "fully.qualified.method.name"`。

### Witness 分派

通过槽索引间接调用，生成 `CallWitness slotIndex`。witness 绑定表在 `LirBuilder.Build()` 头部通过 `GenerateWitnessDispatchEntry` 注入到模块。

```csharp
module.AddWitnessEntry(new GenerateWitnessDispatchEntry(
    binding.TraitName, binding.SlotIndex, binding.MethodName,
    binding.TargetTypeName, binding.ImplementationFunctionName));
```

这是静态全局表，运行时通过 `(TraitName, SlotIndex)` 键查找 `(TargetTypeName, ImplementationFunctionName)`。

### Dynamic 分派

`dyn Trait` 对象由胖指针（对象指针 + TypeInfo 指针）构成。分派流程：

```
obj → TypeInfo → witness_table[slotIndex] → func_ptr → call
```

对应的 LIR 指令序列：

```
LoadTypeInfo obj → type_info
LoadSlot type_info slotIndex → func_ptr
CallIndirect func_ptr (obj, args...)
```

HIR 层负责标记 `DispatchKind.Dynamic` 并记录 trait 和槽位信息，LIR 层生成间接调用指令，运行时层实现 TypeInfo 加载和函数指针跳转。

## 复合类型的 LIR 降级要求

| 类型 | LIR 应保留的信息 |
|:---|:---|
| `class` | 字段列表、每个字段的偏移和类型、GC 位图、父类型 |
| `structure` | 字段列表、对齐约束、总大小 |
| `enums` | 底层整数类型、判值到名称映射 |
| `flags` | 底层整数类型、位值到名称映射 |
| `union` | 变体列表、每个变体的字段、TypeInfo 判值 |
| `unite` | 变体列表、标签字段类型和位置、最大变体大小 |

## LIR 的边界

LIR 是平台无关的低级 IR，不做 ABI 决策：

| LIR 做 | LIR 不做 |
|:---|:---|
| 类型信息的数据描述 | 内存分配决策 |
| 调用约定统一表达 | `.wasm`/`.class`/`.dll` 编码 |
| 控制流结构 | 宿主入口包装 |
| GC 位图标记 | sidecar 资产生成 |