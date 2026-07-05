# 语言约定

Valkyrie 语言的核心关键字约定和设计决策。本文档是所有语言规范的基础参照。

## 关键字约定

Valkyrie 语言的关键字经过精心选择，与常见语言有明确区别：

### 函数 → `micro`

Valkyrie 使用 `micro` 声明函数，不使用 `fn`、`function`、`func`、`def`。

```valkyrie
micro add(a: i32, b: i32) -> i32 {
    return a + b
}

micro greet(name: string) {
    println("Hello, {name}")
}
```

**理由**：`micro` 强调轻量级、可组合的函数语义，与 Valkyrie 的微过程理念一致。在 Schema 扩展中，`micro` 同时作为函数类型注解关键字：`micro(i32) -> i32`。

### mezzo 和 macro

Valkyrie 提供三种函数声明级别，对应不同的复杂度和使用场景：

```valkyrie
# 轻量函数：默认选择
micro add(a: i32, b: i32) -> i32 { a + b }

# 中型函数：复杂多阶段逻辑
mezzo compile_project(sources: [string]) -> Artifact {
    let ast = parse_all(sources)
    let ir = lower_to_ir(ast)
    generate_code(ir)
}

# 宏/模板：编译期代码生成
macro derive<T>() { ... }
```

| 关键字 | 语义 | 使用场景 |
|:---|:---|:---|
| `micro` | 轻量级函数（默认） | 纯算法、短逻辑、trait 方法实现 |
| `mezzo` | 中型函数 | 多阶段处理、状态管理、管线编排 |
| `macro` | 编译期宏/模板 | 代码生成、元编程、编译期计算 |

大多数场景使用 `micro` 即可。

### 循环 → `loop`

Valkyrie 使用 `loop` 进行遍历和迭代，不使用 `for`、`foreach`。

```valkyrie
loop i in 0..10 {
    println(i)
}

loop item in items {
    process(item)
}

loop pattern in iterator {
    handle(pattern)
}
```

**理由**：`loop` 统一了所有迭代形式——范围遍历、集合遍历、模式匹配遍历。`for` 在游戏引擎中常作为方向向量使用，避免冲突。

### 结构体 → `structure`

Valkyrie 使用 `structure` 声明值类型，不使用 `struct`、`record`。

```valkyrie
structure Point(i32, i32)

structure UserSnapshot {
    id: i32,
    name: string,
    level: i32,
}
```

**理由**：`structure` 明确表达结构相等、不可变、值复制的语义，提供最大程度的可控性。`struct`、`record` 这类词在不同语言中历史包袱很重，而 `structure` 更直接表达这里要的语义。

### 类 → `class`

`class` 用于声明类类型，大多数情况下使用 `class` 即可。`class` 并不意味着非要装箱，是否装箱取决于优化器的决策。`class` 支持继承：

```valkyrie
class Animal
    name: string
    age: i32

class Dog(Animal)
    breed: string
```

### trait / union / unite / flags

Valkyrie 使用以下关键字进行类型抽象：

| 关键字 | 用途 | 选择理由 |
|:---|:---|:---|
| `trait` | 能力形状定义 | 沿用 Rust 惯例，精确表达结构子类型契约 |
| `union` | 代数数据类型 | 强调"多选一"本质，区别于 C 的 untagged union |
| `unite` | 紧凑内联 union | 值类型版本，适合小体积高频场景 |
| `flags` | 位标志类型 | 明确表达按位组合语义 |

## 不存在的关键字

以下关键字在 Valkyrie 中**不存在**，任何文档或代码中不应出现：

| 禁止使用 | 正确替代 | 说明 |
|:---|:---|:---|
| `fn` | `micro` | 函数声明 ✅ |
| `function` | `micro` | 函数声明 ✅ |
| `func` | `micro` | 函数声明 ✅ |
| `def` | `micro` | 函数声明 ✅ |
| `for` | `loop` | 遍历循环 ✅ |
| `foreach` | `loop` | 集合遍历 ✅ |
| `struct` | `structure` | 值类型声明 ✅ |
| `record` | `structure` | 值类型声明 ✅ |
| `import` | `using` | 模块导入 |

## 命名规范

### 标识符

| 类别 | 风格 | 示例 |
|:---|:---|:---|
| 类型名（class、structure、enums） | PascalCase | `PlayerState`、`NetworkConfig` |
| 函数名（micro） | snake_case | `calculate_damage`、`process_input` |
| 变量名 | snake_case | `player_health`、`item_count` |
| 常量名 | SCREAMING_SNAKE_CASE | `MAX_HEALTH`、`DEFAULT_PORT` |
| 组件名 | PascalCase | `Position`、`Velocity` |
| 系统名 | PascalCase | `MovementSystem`、`RenderSystem` |
| 枚举变体 | PascalCase | `Active`、`Suspended` |
| 命名空间 | snake_case | `game::physics`、`app::models` |

### 文件扩展名

| 扩展名 | 用途 |
|:---|:---|
| `.v` | Valkyrie 源码 |
| `.script` | Gnosis Script 源码 |
| `.shader` | Gnosis Shader 源码 |
| `.awsl` | AWSL 源码（Vue 式 SFC，VOA） |
| `.widget` | Gnosis Widget 源码 |
| `.hermes` | Hermes 源码 |
| `.schema` | Gnosis Schema 源码 |
| `.dora` | Dora 模板源码 |
| `.doki` | Doki 模板源码 |

## 设计决策

### 编译器独立设计

VCC 是一个独立的编译器工具，不依赖于任何包管理器。它直接使用 `vendors` 目录中的依赖进行编译。

### ECS 原生语言设计

`component`、`system`、`widget`、`plugin` 是一等公民语法，不是库模拟：

| 面向框架的写法 | Valkyrie |
|:---|:---|
| 用普通数据类型手动注册组件 | `component Position { ... }` |
| 用调度对象登记系统逻辑 | `system MovementSystem { ... }` |
| 通过查询 API 组合筛选条件 | `query all = Query.all(Position, Velocity)` |

### 前端复用，不自建解析器

`Valkyrie` 不把文本处理、语义分析、目标编码和打包揉进单一工具。长期原则是职责分层：
- 文本解析负责把源码转为稳定语法输入
- 语义与中层负责闭合语言事实
- family 路线各自生成目标输入
- 编码与打包负责交付物组织

### 年度版本号

YearlyVersion（`yearly.major.minor.patch`）消除了 SemVer 预发布标记的歧义：
- `yearly=0`：预研版
- `major=0`：测试版
- `major>0`：稳定版
