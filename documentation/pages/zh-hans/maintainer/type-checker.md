# 类型检查器实现

## 在管线中的位置

```
AST → MetaStager → Stage 0 AST → TypeChecker → SemanticModel → HirBuilder
```

类型检查器消费 MetaStager 输出后的纯 Stage 0 AST，输出包含绑定结果和诊断的 `SemanticModel`。

## 类型检查流程

类型检查分三个 Pass：

### Pass 1：声明收集

遍历 AST，收集所有顶层声明构建初始符号表：

- 类型声明（`class`、`structure`、`enums`、`flags`、`union`、`unite`、`trait`）
- 函数签名（`micro`、`mezzo`、`macro`）
- 命名空间声明（`namespace`）
- 导入声明（`using`）

此时仅记录声明存在和签名，不检查函数体。

### Pass 2：声明检查

验证 Pass 1 收集的声明是否合法：

- 类型标注是否引用已知类型
- 函数签名中的参数和返回类型是否有效
- `using` 导入路径是否可解析
- 泛型参数约束是否自洽
- 循环继承检测

### Pass 3：体检查

逐函数检查函数体：

1. 为每个函数创建作用域链（全局 → 函数 → 块）
2. 遍历语句和表达式
3. 对每个节点执行类型推断和验证
4. 收集诊断

## 作用域管理

三层 Scope 层次，每一层维护 `Dictionary<string, Symbol>`：

| 层次 | 生命周期 | 存放内容 |
|:---|:---|:---|
| 全局 Scope | 整个编译过程 | 类型声明、顶层函数、命名空间 |
| 函数 Scope | 单函数检查期间 | 参数、局部变量 |
| 块 Scope | 块检查期间 | `{}`、`if`/`loop`/`match` 体内变量 |

变量查找按 块 → 函数 → 全局 顺序向上搜索。

## 类型表示

类型检查器使用 `TypeKind` 枚举表示 15 种类型种类：

| TypeKind | 对应语言类型 |
|:---|:---|
| `Integer` | `i8`~`i64`、`u8`~`u64` |
| `Float` | `f32`、`f64` |
| `Bool` | `bool` |
| `String` | `string` |
| `Void` | `void` |
| `List` | `list<T>` |
| `Map` | `map<K, V>` |
| `Nullable` | `T?` |
| `Function` | `micro(...) -> T` |
| `Class` | `class` |
| `Structure` | `structure` |
| `Enum` | `enums`、`flags` |
| `Union` | `union`、`unite` |
| `Intersection` | `A & B`（trait 组合） |
| `Error` | 类型检查失败时使用 |

预定义类型（`i8`~`i64`、`u8`~`u64`、`f32`、`f64`、`bool`、`string`、`void`）在类型检查器初始化时自动注入全局 Scope。

## Symbol 体系

每个 Symbol 包含名称、类型和种类：

| SymbolKind | 来源 |
|:---|:---|
| `Variable` | `let` / `let mut` |
| `Function` | `micro` / `mezzo` / `macro` |
| `Class` | `class` |
| `Structure` | `structure` |
| `Component` | `component` |
| `System` | `system` |
| `Enum` | `enums` |
| `Flags` | `flags` |
| `Union` | `union` / `unite` |
| `Namespace` | `namespace` |
| `Module` | 外部模块导入 |
| `Parameter` | 函数参数 |

## 类型推断

表达式类型推断遵循以下规则：

1. **字面量**直接推断：`42` → `i32`，`"hello"` → `string`，`true` → `bool`
2. **变量引用**查符号表获取类型
3. **函数调用**从函数签名的返回类型推导
4. **二元运算**按运算符规则推断结果类型
5. **`let` 绑定**无标注时从初始化表达式推断

## 结构子类型检查

Valkyrie 采用结构子类型（structural subtyping），类型兼容性由形状匹配决定：

- `T` 可赋值给 trait `A`，当且仅当 `T` 的方法集覆盖 `A` 要求的所有方法签名
- 编译器遍历 `T` 的方法集与 `A` 的方法签名逐项比对
- 此过程零运行时开销

## 诊断

类型检查器产生 `VALK2xxx` 系列诊断：

| 代码 | 说明 |
|:---|:---|
| `VALK2001` | 类型不匹配 |
| `VALK2002` | 未声明的变量 |
| `VALK2003` | 重复声明 |
| `VALK2004` | 函数参数数量不匹配 |
| `VALK2005` | 类型不可转换 |
| `VALK2006` | 未实现 trait |
| `VALK2007` | 循环引用 |
| `VALK2008` | 泛型约束不满足 |

## 输出

`TypeChecker.Analyze(ast)` 返回 `SemanticModel`，包含：

- 已解析的符号表（所有作用域的完整绑定）
- 每个表达式节点的推断类型
- 诊断列表（错误和警告）
- 模块导入图

`SemanticModel` 是 HirBuilder 的唯一输入，确保 HIR 构建时所有符号均已解析。