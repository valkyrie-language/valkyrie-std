# Effect 系统

Valkyrie 的效应系统严格区分两类副作用：领域错误和系统效应。前者通过 `Result<T, E>` 与 `?` 操作符在类型层面追踪和传播；后者默认透传，无需在函数签名中声明。同时保留 `catch`/`resume` 代数效应机制，用于捕获和恢复执行流。

## 效应分类

### 领域错误

领域错误是可恢复的、在领域建模中预期之内的错误。例如"文件未找到"、"解析失败"、"网络超时"。领域错误使用 `Result<T, E>` 表示，通过 `?` 操作符传播，是函数签名的一部分——调用者必须显式处理或继续传播。

### 系统效应

系统效应是不可恢复或难以恢复的运行时事件，例如内存溢出（OOM）、栈溢出、线程中止。这些效应默认透传，函数签名中无需声明。Valkyrie 不要求用类型系统追踪系统效应——它们本质上是基础设施层级的事件，不应侵入业务逻辑的类型签名。

```valkyrie
# 领域错误：在签名中显式声明
micro read_file(path: String) -> Result<String, FileError> { ... }

# 系统效应：不在签名中出现
# 运行时可能触发 OOM、栈溢出等，调用者无需处理
```

## Result 类型与 ? 操作符

`Result<T, E>` 是 Valkyrie 内置的联合类型，承载可恢复错误的成功值或错误值。

```valkyrie
union Result<T, E> {
    Ok(T)
    Err(E)
}
```

### ? 操作符

`?` 是领域错误传播的语法糖：

- 遇 `Ok(value)`：提取值，继续执行
- 遇 `Err(e)`：立即短路返回 `Err(e)`

```valkyrie
micro read_config() -> Result<Config, ConfigError> {
    let data = read_file("config.json")?
    let config = parse_config(data)?
    config
}
```

上例等价于：

```valkyrie
micro read_config() -> Result<Config, ConfigError> {
    let data = match read_file("config.json") {
        case Ok(v): v
        case Err(e): return Err(e)
    }
    let config = match parse_config(data) {
        case Ok(v): v
        case Err(e): return Err(e)
    }
    Ok(config)
}
```

### ? 的类型转换

`?` 操作符支持 `From<E1, E2>` 自动转换。若当前函数返回的错误类型与子函数不同，编译器查找 `From<E1, E2>` 实现自动包装：

```valkyrie
micro read_number(path: String) -> Result<i32, AppError> {
    let content = read_file(path)? // FileError → AppError via From<FileError, AppError>
    let num = parse_i32(content)?  // ParseError → AppError via From<ParseError, AppError>
    Ok(num)
}
```

## 匿名和类型 E1 + E2

当函数调用多个可能产生不同领域错误的子函数时，错误类型自动合并为匿名和类型，无需手工定义 `ProcessError` 枚举。

```valkyrie
micro process() -> Config / ConfigError + UserError {
    let cfg = read_config()?
    let user = validate_user(cfg.user_id)?
    cfg
}
```

`E1 + E2` 在类型层面自动形成匿名和类型：

```valkyrie
# 编译器自动生成
union ConfigError + UserError {
    case ConfigError(ConfigError)
    case UserError(UserError)
}
```

### 特点

- **自动合并**：编译器根据实际调用的错误类型自动推导
- **精确匹配**：模式匹配可匹配各子类型，不丢失类型信息
- **零装箱开销**：编译期已知所有变体，无需堆分配
- **开放组合**：`E1 + E2 + E3` 可任意组合，无需预定义

```valkyrie
# 调用方可精确匹配各子类型
match process() {
    case Ok(val): use(val)
    case Err(ConfigError.NotFound(path)): create_default(path)
    case Err(ConfigError.ParseError(msg)): log_error(msg)
    case Err(UserError.InvalidId(id)): prompt_user(id)
}
```

## 效应标注语法

```valkyrie
# 带效应函数：T 为返回类型，E1 + E2 为可能产生的领域错误
micro func() -> T / E1 + E2

# 纯函数：不产生任何领域错误
micro pure() -> T / !

# 纯函数简写：省略 / ! 时默认为纯函数
micro pure() -> T

# 泛型效应
micro map<T, U, E>(self: Iterator<Item = T>, f: micro(T) -> U / E) -> Vec<U> / E
```

### 效应传播规则

- 效应是协变的：若 `f` 声明效应 `E`，调用 `f` 的函数传播 `E`
- 效应合并：`(E1 + E2) + E3` 等价于 `E1 + E2 + E3`
- 纯函数可以出现在任何需要效应的位置（纯函数是零效应的函数）

## 效应不侵入 trait

领域错误是调用上下文的属性，不是容器或迭代器的固有部分。迭代器 trait 定义绝不包含错误类型：

```valkyrie
trait Iterator {
    type Item
    next(mut self) -> Option<Self::Item>
}
```

若某个 `micro` 需要处理可能出错的迭代，在签名中声明效应，不要求 `Iterator` trait 携带错误类型参数。这一设计避免了 Rust 中 `Iterator<Item = Result<T, E>>` 带来的类型复杂度和 `collect::<Result<Vec<_>, _>>()` 的 boilerplate。

```valkyrie
# trait 定义简洁，不含错误类型
trait Iterator {
    type Item
    next(mut self) -> Option<Self::Item>
}

# 效应在 micro 签名中声明
micro process_items<I: Iterator<Item = i32>>(items: I) -> i32 / ProcessError {
    let mut sum = 0
    for item in items {
        sum = sum + validate(item)?
    }
    sum
}
```

## 短路 micro 命名约定

对于需要处理 `Result` 迭代的 micro，定义带效应处理的版本，使用不同名字让调用者显式选择：

```valkyrie
# 普通版本：不涉及效应
micro map<T, U>(self: IntoIterator<Item = T>, f: micro(T) -> U) -> Vec<U> { ... }

# 效应感知版本：遇 Err 短路
micro map_fallible<T, E, U>(
    self: IntoIterator<Item = Result<T, E>>,
    f: micro(T) -> U / E
) -> Result<Vec<U>, E> { ... }
```

调用者根据场景显式选择 `map` 或 `map_fallible`，编译器确保效应签名匹配。

```valkyrie
# 普通迭代——用 map
let doubled = [1, 2, 3].iter().map(|x| x * 2)

# 可能出错的迭代——用 map_fallible
let parsed: Result<Vec<Config>, ConfigError> =
    filenames.iter().map_fallible(|name| read_config(name)?)
```

## 代数效应 catch / resume

除 `Result<T, E>` + `?` 的顺流传播之外，Valkyrie 保留 `catch`/`resume` 代数效应机制，用于逆流捕获可恢复的效应。

### Term 与 Effect 的对偶性

| 概念 | 方向 | 关键字 | 说明 |
|:---|:---|:---|:---|
| **Term** | 顺流而下 | `match` | 对值进行模式匹配 |
| **Effect** | 逆流而上 | `catch` | 捕获副作用或异常 |

`match` 从外向内分解值，`catch` 从内向外捕获效应。两者形成对偶。

### 内置变体类型

| 类型 | 声明 | 构造 / 匹配 |
|:---|:---|:---|
| `Fine \| Fail` | `Fine { value: T }` / `Fail { error: E }` | `Fine(x)` / `case Fine(x)` |
| `Some \| None` | `Some { value: T }` / `None` | `Some(x)` / `case Some(x)` |

### catch 语法

前置形式：

```valkyrie
catch expr {
    case Fine(value): handle_success(value)
    case Fail(error): handle_error(error)
}
```

后置形式：

```valkyrie
expr.catch {
    case Fine(value): handle_success(value)
    case Fail(error): handle_error(error)
}
```

`else` 分支匹配所有未被前面 `case` 捕获的变体：

```valkyrie
catch expr {
    case Fine(value): handle_success(value)
    else: handle_failure()
}
```

### resume 语法

`resume` 在 `catch` 块内恢复被中断的执行流：

```valkyrie
catch perform_read() {
    case Fail(error):
        log(error)
        resume default_value
}
```

`resume` 将值逆流送回 `perform` 发起的位置，执行流从断点继续。

### match 与 catch 的区别

| 特性 | match | catch |
|:---|:---|:---|
| 方向 | 顺流：分解已有值 | 逆流：捕获未处理的效应 |
| 控制流 | 选择分支后继续 | 可用 `resume` 恢复到断点 |
| 返回值 | 分支表达式的值 | 整个 catch 表达式的值 |
| 嵌套 | 逐层解构 | 逆流冒泡直到被捕获 |

### 链式使用

```valkyrie
result
    .catch {
        case Fail(_): resume Fine(0)
    }
    .match {
        case Fine(value): process(value)
    }
```

### 与 Async 的关系

`.await` 本质上是 `perform AsyncWait` 的语法糖：

```valkyrie
# 以下两种写法等价
let result = fetch_data().await
let result = catch perform AsyncWait(fetch_data()) {
    case Fine(value): resume value
}
```

详见 [Async 扩展](../extensions/async-extension.md)。

## 总结对比

| 机制 | 适用场景 | 方向 | 类型参与 |
|:---|:---|:---|:---|
| `Result<T, E>` + `?` | 领域错误传播 | 顺流 | 签名中显式声明 |
| 匿名和类型 `E1 + E2` | 跨领域错误聚合 | 编译时类型合并 | 自动推导 |
| `catch` / `resume` | 代数效应捕获恢复 | 逆流 | 运行时匹配 |
| 系统效应（OOM 等） | 不可恢复事件 | 默认透传 | 不参与签名 |