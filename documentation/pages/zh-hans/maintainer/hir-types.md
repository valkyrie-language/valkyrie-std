# HIR 类型系统

## 概述

HIR（High-level Intermediate Representation）是 Valkyrie 编译管线中位于语义分析和 MIR 之间的中间表示层。HIR 类型系统负责将 AST 中的类型声明转换为结构化的语义描述，为下游 MIR/LIR 提供类型信息。

## 在管线中的位置

```
Stage 0 AST → ③ TypeChecker → SemanticModel → ④ HirBuilder → HIR → ⑤ HirToMirLowerer → EGraph<IKun>
```

HIR 消费 SemanticModel（已解析的符号和类型），不接触原始 AST。向下游 MIR 降级层提供类型定义和分派决策。

## HirTypeKind

`HirTypeKind` 枚举定义了 Valkyrie 语言的全部七种类型声明：

```csharp
public enum HirTypeKind
{
    Class,
    Structure,
    Enums,
    Flags,
    Union,
    Unite,
    Trait
}
```

## HirTypeDef

`HirTypeDef` 是 HIR 层中类型定义的核心记录类型：

```csharp
public sealed record HirTypeDef(
    string Name,
    string QualifiedName,
    HirTypeKind Kind,
    IReadOnlyList<HirMethod> Methods,
    IReadOnlyList<HirVariantDef>? Variants,
    HirTypeRef? BaseType,
    int? EnumBaseType
);
```

| 字段 | 说明 | 适用类型 |
|:---|:---|:---|
| `Name` | 类型名 | 全部 |
| `QualifiedName` | 完全限定名 | 全部 |
| `Kind` | 类型种类 | 全部 |
| `Methods` | 方法列表 | Class / Structure / Union / Unite / Trait |
| `Variants` | 变体列表 | Enums / Flags / Union / Unite |
| `BaseType` | 父类引用 | Class |
| `EnumBaseType` | 枚举底层整数类型 | Enums / Flags |

## HirVariantDef

```csharp
public sealed record HirVariantDef(
    string Name,
    HirTypeRef? PayloadType,
    long? Discriminant
);
```

| 字段 | 说明 |
|:---|:---|
| `Name` | 变体名称 |
| `PayloadType` | 变体携带的数据类型 |
| `Discriminant` | 判值：Enums/Flags 为整数值，Union/Unite 为运行时 TypeInfo 判值 |

## 各类型到 HIR 的映射

### structure

值类型，栈分配：

```valkyrie
structure Point { x: i32, y: i32 }
```

HIR：`Kind = Structure`，`Variants = null`，字段通过 `Methods` 中的 getter/setter 表达。

### class

引用类型，GC 堆分配：

```valkyrie
class Animal { name: string, age: i32 }
```

HIR：`Kind = Class`，`BaseType` 可指定父类。

### enums

离散枚举：

```valkyrie
enums Status { Inactive = 0, Active = 1, Suspended = 2 }
```

HIR：`Kind = Enums`，`Variants` 包含三个 `HirVariantDef`，各自带有 `Discriminant` 判值。

### flags

位标志组合：

```valkyrie
flags Permission { Read = 1, Write = 2, Execute = 4 }
```

HIR：`Kind = Flags`，`Variants` 包含带位值的变体。位运算由 IKun 节点承载。

### union

代数数据类型（引用语义）：

```valkyrie
union Option<T> { Some(T), None }
```

HIR：`Kind = Union`，每个变体一个 `HirVariantDef`，运行时通过 TypeInfo 判断当前变体。

### unite

紧凑内联 union（值语义）：

```valkyrie
unite CompactOption<T> { Some(T), None }
```

HIR：`Kind = Unite`。与 Union 的区别：

| 属性 | Union | Unite |
|:---|:---|:---|
| 分配语义 | 引用（GC 堆） | 值（栈或内联） |
| 拷贝语义 | 引用拷贝 | 逐位拷贝 |
| trait object | 支持 `dyn Trait` | 不支持 |

### trait

结构类型约束：

```valkyrie
trait Display { to_string(self) -> string }
```

trait 的实际定义数据由独立的 `HirTraitDef` 承载。`HirTypeKind.Trait` 仅用于类型引用场景（如 `HirTypeRef` 指向 trait 时）。

## HirTraitDef

```csharp
public sealed record HirTraitDef(
    string Name,
    string QualifiedName,
    IReadOnlyList<HirMethod> Methods
);
```

## HirImplyDef

```csharp
public sealed record HirImplyDef(
    string TargetType,
    string ContractType,
    IReadOnlyList<HirMethod> Methods,
    IReadOnlyList<WitnessBinding> WitnessBindings
);
```

## HirCallResolution

```csharp
public enum HirDispatchKind
{
    Static,
    Witness,
    Dynamic
}
```

| 分派种类 | 说明 |
|:---|:---|
| `Static` | 直接按函数名调用 |
| `Witness` | 通过 witness table 槽索引间接调用 |
| `Dynamic` | 通过 trait object 的 TypeInfo 动态分派 |

## 与下游的接口

### 对 MIR 的影响

`HirTypeDef` 的 `Variants` 信息被 `MirBuilder` 编码为 IKun 节点，支持模式匹配的下游优化（如 `match` 跳转表生成）。

### 对 LIR 的影响

`LirBuilder` 将 HIR 类型映射为 `GenerateValueType`：

| HIR 类型 | LIR 降级 | 说明 |
|:---|:---|:---|
| `Enums` | 底层整数类型 | 判值作为常量比较 |
| `Flags` | 底层整数类型 | 位运算由 IKun 承载 |
| `Union` | ExternRef 或 Struct | 取决于布局策略 |
| `Unite` | Struct | 紧凑内联布局 |
| `Trait` | ExternRef | trait object 胖指针 |

## HIR 的边界

HIR 不做布局决策，仅保留纯语义信息：

| HIR 知道 | HIR 不知道 |
|:---|:---|
| 类型种类（Class / Structure / Enums / ...） | 对象在内存中的具体布局 |
| 变体名称与判值 | vtable 槽位排列 |
| 字段名与类型引用 | 字段偏移量 |
| 父类型引用 | GC 扫描策略 |

对象布局决策在 `TargetArtifactEmitter` 中各后端自行完成。