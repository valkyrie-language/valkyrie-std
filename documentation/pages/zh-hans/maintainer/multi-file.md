# 多文件语义分析

## 概述

Valkyrie 编译器支持两种分析模式：单文件分析和多文件分析。多文件分析需要处理跨文件类型引用、trait 推导、方法分派决议等问题。

## 在管线中的位置

```
多个 .v 文件 → ① Oak → ② MetaStager → 所有 Stage 0 AST
                                        │
          ┌─────────────────────────────┘
          ▼
   全局声明收集（所有文件） → 拓扑排序 → ③ TypeChecker（逐文件）
```

多文件编译在 TypeChecker 阶段之前插入全局声明收集和拓扑排序步骤。管线其余阶段（④~⑩）不变。

## 两阶段分析模型

多文件语义分析分为两个阶段：

### Phase 1：声明收集

遍历所有文件的 AST，收集：

- 类型声明（`class`、`structure`、`enums`、`flags`、`union`、`unite`、`trait`）
- 函数签名（`micro`、`mezzo`、`macro`）
- 模块导入（`namespace`、`using`）

此阶段不做类型检查，仅记录签名。

### Phase 2：体分析

在全局声明表就绪后，按拓扑序逐文件分析：

- 函数体类型检查
- trait 满足性推导
- 方法分派决议
- 效应检查

## 全局声明表

```csharp
public sealed class GlobalDeclarationTable
{
    public Dictionary<string, ModuleSymbolTable> Modules { get; }
    public Dictionary<string, HirTypeDef> Types { get; }
    public Dictionary<string, HirTraitDef> Traits { get; }
    public Dictionary<string, FunctionSignature> Functions { get; }
    public Dictionary<string, HashSet<string>> TypeTraitSatisfactions { get; }
    public Dictionary<(string TypeName, string TraitName), WitnessTable> WitnessTables { get; }
}
```

| 字段 | 说明 |
|:---|:---|
| `Modules` | 模块名到模块符号表的映射 |
| `Types` | 完全限定类型名到类型定义 |
| `Traits` | 完全限定 trait 名到 trait 定义 |
| `Functions` | 完全限定函数名到函数签名 |
| `TypeTraitSatisfactions` | 类型到满足的 trait 集合（Phase 2 填入） |
| `WitnessTables` | trait 到 witness table 的映射（Phase 2 填入） |

## 拓扑排序与依赖分析

```
解析 import/using → 构建模块依赖图 → 拓扑排序 → 按序分析
```

示例：

```
math.v:   namespace math
physics.v: using math; namespace physics
game.v:   using math; using physics; namespace game
```

依赖图：

```
math.v (无依赖)
  ├── physics.v (依赖 math.v)
  └── game.v (依赖 math.v, physics.v)
```

拓扑序输出：`math.v → physics.v → game.v`

### 循环依赖处理

若文件 A 和 B 互相 `using` 对方的类型，报告诊断但不中断编译。只要类型不递归引用自身，即可通过部分检查。

## 模块可见性规则

| 声明类型 | 跨文件可见 | 说明 |
|:---|:---|:---|
| `namespace` | 是 | 全局可见 |
| `using` | 是 | 导入路径对所有后续文件生效 |
| `class` / `structure` | 是 | 全局可见，需通过路径引用 |
| `micro`（独立） | 是 | 独立 micro 全局可见，参与分派 |
| `class` 内的 `micro` | 是 | 通过 `class.method()` 形式访问 |
| `macro` | 是 | 编译期全局可见 |
| 文件私有声明 | 否 | 文件作用域内使用 |

## Witness Table 跨文件传递

witness table 是编译器将"类型满足 trait"转化为可传递的编译期证据的核心数据结构。

多文件场景构建流程：

1. Phase 1：收集所有 trait 定义和 class 定义，构建候选满足关系
2. Phase 2：逐文件分析函数体时，遇到 trait 约束则查询全局声明表
3. 查询命中：生成对应 witness table 条目
4. 查询未命中：报告诊断"类型 X 不满足 trait Y"

witness table 条目在 NyarVM 运行时以函数指针表形式存在，编译期输出为 `GenerateWitnessDispatchEntry`。

## 与现有组件的关系

| 组件 | 角色 |
|:---|:---|
| `Valkyrie.TypeChecker` | Phase 2 体分析核心 |
| `ValkyrieSemanticBridge` | 分析结果聚合器 |
| `ValkyrieWorkspaceServices` | 源码解析服务 |
| DeclarationCollector | Phase 1 声明收集（新） |
| ModuleDependencyGraph | 拓扑排序模块（新） |

## 增量编译

多文件场景下的增量编译通过文件指纹（内容哈希）判断变化，重新分析变更文件及其反向依赖：

- 全量编译：`AnalyzeAll(asts, projectRoot)`
- 增量编译：`AnalyzeIncremental(allAsts, changedAsts, previousState, projectRoot)`