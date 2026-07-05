# Valkyrie 语言标准

## 概述

Valkyrie 是面向 ECS、游戏引擎与 Web 全栈的领域特定语言。它的长期编译主线强调语义先闭合、`Partition` 后按 family 分流，而不是依赖某个统一终态中间表示。

### 设计哲学

Valkyrie 的语言设计围绕三条核心原则展开：

- **trait 是能力宪法**：trait 定义操作形状，描述类型"能做什么"。编译器根据结构的形状自动推导满足关系，无需显式声明。零侵入——已有的 `class` 自动进入新 `trait` 的生态，无需修改任何代码。
- **class 是行为唯一实体**：所有特化必须在 `class` 内部以同名方法或条件方法的形式提供。外部绝不允许定义特化块。
- **micro 是通用算法蓝图**：独立泛型函数，基于最少 trait 约束编写。`micro` 不允许重载——不同功能必须使用不同名字。

这三条原则共同塑造了"所有权优先"设计：越接近数据定义者，话语权越大。

### 编译管线

```mermaid
flowchart LR
    Source[源代码]
    Parse[Parse]
    Semantics[Semantics]
    HIR[HIR]
    MIR[MIR]
    Optimize[Optimize]
    Partition[Partition]
    FamilyLane[Family Lane]
    BackendInput[Backend Input]
    Validate[Validate]
    Compile[Compile]
    Encode[Encode]
    Package[Package]
    ArtifactSet[ArtifactSet]

    Source --> Parse --> Semantics --> HIR --> MIR --> Optimize --> Partition --> FamilyLane --> BackendInput --> Validate --> Compile --> Encode --> Package --> ArtifactSet

    classDef phase fill:#f6f9fc,stroke:#8a9aad,stroke-width:1.2px,color:#1f2937;
    classDef boundary fill:#fff8e8,stroke:#d6a93d,stroke-width:1.2px,color:#5c4400;
    classDef delivery fill:#f3fbf6,stroke:#7fb77e,stroke-width:1.2px,color:#1f5130;

    class Source,Parse,Semantics,HIR,MIR,Optimize phase;
    class Partition,Validate boundary;
    class FamilyLane,BackendInput,Compile,Encode,Package,ArtifactSet delivery;
```

详细管线与各阶段职责参见 [维护者文档：编译管线](../maintainer/compilation.md)。

## 词法结构

行注释使用 `#`，块注释使用 `<# ... #>`。详细规则（标识符、字面量、运算符、分隔符、元代码块）参见 [lexical-structure.md](lexical-structure.md)。

| 类别 | 关键字 |
|:---|:---|
| 函数 | `micro`、`mezzo`、`macro` |
| 类型 | `structure`、`class`、`enums`、`flags`、`union`、`unite`、`trait` |
| 模块 | `namespace`、`using` |
| 变量 | `let`、`let mut` |
| 控制流 | `if`、`else`、`while`、`until`、`loop`、`match`、`case`、`when` |
| 效应 | `catch`、`resume` |

## 类型系统

Valkyrie 采用**结构子类型**（Structural Subtyping），类型兼容性由形状匹配决定。详细规则参见 [类型系统](type-system/)。

**基元类型**：`i8` `i16` `i32` `i64` `u8` `u16` `u32` `u64` `f32` `f64` `bool` `string` `void` `auto`

**复合类型**：

```valkyrie
structure Point(i32, i32)             # 不可变值类型，结构相等
class Animal { name: string }         # 引用类型，支持继承
enums Status { Active = 0, Inactive } # 离散枚举
flags Permission { Read = 1, Write = 2 } # 位标志
union Option<T> { Some(T), None }     # 代数数据类型（引用）
unite CompactResult { Ok(i32), Err(string) } # 紧凑内联 union
```

更多参见：[类型系统](type-system/)、[复合类型](type-system/compound-types.md)、[容器与可空类型](type-system/container-nullable-types.md)

## 声明

```valkyrie
let x = 42                           # 不可变绑定
let mut counter = 0                  # 可变绑定

micro add(a: i32, b: i32) -> i32 { a + b }  # 轻量函数
mezzo process(data: &mut Buffer) -> Result  # 中型函数
macro derive_iterator<T>() { }              # 编译期宏

structure Point(i32, i32)
class Dog(Animal) { breed: string }  # 单继承
enums Direction { North, South, East, West }
flags Permissions { Read = 1, Write = 2 }
union Result<T, E> { Ok(T), Err(E) }
unite CompactOption<T> { Some(T), None }

namespace game::physics { ... }
using game::physics::Vector
```

详细规则参见：[declarations.md](declarations.md)、[class-inheritance.md](class-inheritance.md)

## trait 系统

trait 定义类型的能力形状，编译器通过**结构推导**自动判定满足关系。详见 [trait 系统](trait-system/)。

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>
    into_iterator(self) -> Self::Iter
    default collect(self) -> Vec<Self::Item> { ... }
}

trait RandomAccessContainer<T> = Indexable<Item = T> & ExtractLength  # trait 别名
```

任何定义了 `into_iterator(self)` 方法的类型自动进入 `IntoIterator` 生态，无需显式声明——这是结构推导的核心价值。

## 方法分派

当编译器遇到 `x.method(args)` 时，按三级铁律查找，**找到即停止**：

| 步骤 | 查找位置 | 说明 |
|:---:|:---|:---|
| 1 | `class` 自有方法 | class 作者最了解自己的数据结构 |
| 2 | `trait` 方法 | trait 是类型满足的契约 |
| 3 | 独立 `micro` | 算法蓝图，允许第三方扩展 |

```valkyrie
class Dog {
    bark(self) -> string { "汪汪！" }
}

trait Loggable {
    log(self) -> string { "默认日志" }
}
class Data : Loggable {}

dog.bark()   # 第一步命中：class 自有
data.log()   # 第二步命中：trait 默认方法
```

详细规则（消歧手段、条件特化、动态分派）参见 [维护者文档：方法分派边界](../maintainer/method-dispatch.md)。

## 表达式

### 运算符优先级（从低到高）

| 优先级 | 运算符 | 兼容写法 | 结合性 |
|:---:|:---|:---|:---:|
| 1 | `∨` | `\|\|` | 左 |
| 2 | `∧` | `&&` | 左 |
| 3 | `==` `!=` `<` `>` `<=` `>=` | — | 左 |
| 4 | `\|` `⊻` | — | 左 |
| 5 | `&` `⩟` | — | 左 |
| 6 | `+` `-` | — | 左 |
| 7 | `*` `/` `//` `%` `×` | — | 左 |
| 8 | `!` `-`（一元） | — | 右 |

逻辑运算符以 Unicode 形式（`∧` `∨` `⊼` `⊻` `⊽` `⩟`）为规范写法；`&&` / `\|\|` 为 ASCII 兼容。限定名以 `⸬` 为规范写法，`::` 为兼容。泛型以 `⟨T⟩` 为规范写法，`<T>` / `::<T>` 为兼容。详见 [词法结构](lexical-structure.md)。

### 关键表达式

```valkyrie
let max = if a > b { a } else { b }     # if 是表达式
loop i in 0..10 { println("{i}") }      # 遍历
loop item in items.enumerate() { ... }  # 带索引遍历
loop { count += 1; if count >= 10 { break count } }  # 无限循环
items.map(.name)                         # 字段简写
items.filter(x => x > 0)                # Lambda
items.map(micro(item) -> string { ... }) # 完整闭包
items.map { $1.name }                   # 尾随闭包
value |> process |> format              # 管道

items[1]           # 序数访问（从 1 开始）
items⁅0⁆          # 偏移访问（从 0 开始）
```

详细规则参见：[expressions.md](expressions.md)、[statements.md](statements.md)

## 模式匹配

```valkyrie
match value {
    case 42 => "答案"
    case n when n > 0 => "正数"
    else => "其他"
}

match shape {
    case Circle(radius) => pi * radius * radius
    case Rectangle(width, height) => width * height
}

match items {
    case [] => "空列表"
    case [head, ..tail] => "头：{head}"
    case [first, second, ..rest] => "前两个：{first}, {second}"
}
```

详细规则参见：[pattern-matching.md](pattern-matching.md)

## Effect 系统

Valkyrie 严格区分领域错误和系统效应。详见 [Effect 系统](effect-system/)。

```valkyrie
union Result<T, E> { Ok(T), Err(E) }

micro read_config() -> Result<Config, ConfigError> {
    let data = read_file("config.json")?     # 遇 Err 短路返回
    let config = parse_config(data)?
    config
}

micro func() -> T / !     # 纯函数，不产生领域错误
micro func() -> T          # 纯函数简写

catch expr {
    case Fine(value) => handle_success(value)
    case Fail(error) =>
        log(error)
        resume default_value
}
```

## 模块系统

使用 `namespace` 组织代码，`using` 导入名称。`::` 是编译时路径分隔符，`.` 是运行时成员访问符。详见 [path-resolution.md](path-resolution.md)。

```valkyrie
namespace game::physics {
    class Vector { ... }
}

using game::physics::Vector
using std::collections::*
```

## 标准库核心 trait 谱系

### 迭代与遍历

| trait | 核心方法 | 说明 |
|:---|:---|:---|
| `IntoIterator` | `into_iterator(self) -> Self::Iter` | 转换为迭代器 |
| `Iterator` | `next(mut self) -> Option<Self::Item>` | 推进迭代器 |
| `DoubleEndedIterator` | `next_back(mut self) -> Option<Self::Item>` | 双向迭代 |

### 长度与索引

| trait | 核心方法 | 说明 |
|:---|:---|:---|
| `ExtractLength` | `extract_length(self) -> i32` | O(1) 获取长度 |
| `Countable` | `count_hint(self) -> i32`、`count(self) -> i32` | 估算 / 精确计数 |
| `Indexable` | `at(ref self, index: i32) -> Self::Item` | 整数索引 |
| `Lookup` | `lookup(ref self, key: Self::Key) -> Option<Self::Value>` | 键值查找 |
| `Contains` | `contains(ref self, value: Self::Item) -> bool` | 包含判断 |

### 添加与移除

| trait | 核心方法 | 说明 |
|:---|:---|:---|
| `PushBack` | `push_back(ref self, value: Self::Item)` | 尾部添加 |
| `PushFront` | `push_front(ref self, value: Self::Item)` | 头部添加 |
| `PopBack` | `pop_back(ref self) -> Option<Self::Item>` | 尾部移除 |
| `PopFront` | `pop_front(ref self) -> Option<Self::Item>` | 头部移除 |

### 有序与并行

| trait | 核心方法 | 说明 |
|:---|:---|:---|
| `Ordered` | `compare(ref self, other: Self) -> Ordering` | 全序比较 |
| `Priority` | `extract_priority(self) -> i32` | 优先级提取 |
| `ParallelIterable` | `into_parallel_iterator(self) -> Self::ParIter` | 并行迭代转换 |

## 语法速查表

| 概念 | 语法 |
|:---|:---|
| 变量 | `let x = 42`、`let mut y = 0` |
| 函数 | `micro add(a: i32, b: i32) -> i32 { a + b }` |
| 结构体 | `structure Point(i32, i32)` |
| 类 | `class Animal { name: string; age: i32 }` |
| 枚举 | `enums Status { Inactive = 0, Active = 1 }` |
| 标志 | `flags Permission { Read = 1, Write = 2 }` |
| 联合 | `union Option<T> { Some(T), None }` |
| trait | `trait Iterator { type Item; next(mut self) -> Option<Self::Item> }` |
| 模块 | `namespace foo::bar`、`using foo::bar::Type` |
| 遍历 | `loop item in items { ... }` |
| 条件 | `if cond { ... } else { ... }` |
| 模式匹配 | `match val { case pattern => result }` |
| 特性标注 | `[attr]` |
| 效应 | `Result<T, E>` / `?` / `catch` |
| 注释 | `# 行注释` / `<# 块注释 #>` |
| 元代码 | `<% code %>` |
