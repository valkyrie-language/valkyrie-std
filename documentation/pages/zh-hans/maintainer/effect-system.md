# 效应系统设计（修正版）

## 第一性原理

程序表达式的求值，本质上是**产生一个值**。这个值要么是**正常结果**，要么是**效应操作**——二者是平等的、对偶的。将这种对偶性贯穿整个类型系统，我们得到一套极简、一致且可组合的效应处理方案。

- **正常值**（类型 `T`）：计算完成，返回一个普通的结构体值。
- **效应操作**（类型集合 `E` 中的某个结构体）：计算挂起，抛出一个携带操作信息的值，由处理器决定是否恢复、如何恢复。

在类型层面，一个表达式可能产生 `T` 或 `E` 中的某个操作，记为 `T / E`。其中 `T` 和 `E` 的地位完全对等：它们都是**结构类型**（row type），即类型由所拥有方法集合决定，字段等价于 `[get]`/`[set]` 方法。消费侧也完全对偶：`match` 解构正常值 `T`，`catch` 解构效应操作 `E`。

由于一切皆为结构体值，效应操作可以是任意结构体，不要求继承特定基类。可恢复性通过 `Effectful` trait 显式标记，未实现者视为不可恢复（`Resume = !`）。整个系统没有特殊关键字，所有能力来自类型组合。

---

## 语法总览

| 类别         | 语法形式                                                   | 说明                           |
|--------------|------------------------------------------------------------|--------------------------------|
| 抛出效应     | `raise expr`                                               | `expr` 为任意结构体实例        |
| 恢复执行     | `resume(value)`                                            | 仅在 `catch` 分支中使用        |
| 正常值处理   | `expr.match { case ... : ... }`                            | 解构 `T`，效应不变             |
| 效应处理     | `expr.catch { case ... : ... }`                            | 解构 `E`，可 `resume`          |
| 效应转错误   | `try Result<T, [E捕获]> { ... }`                           | 将一组效应转为 `Result`        |
| 链式处理     | `expr.match{...}.catch{...}` 或 `expr.catch{...}.match{...}` | 任意顺序组合                   |
| 效应类型标注 | `micro name(...) -> T / [E1, E2]`                          | `E` 可省略，编译器自动推导     |
| 纯计算       | `T / []` 或简写 `T`                                        |                                |
| 生成器       | `yield expr`<br>`yield break`<br>`yield return expr`       | 脱糖为 `raise Yielder::...`    |
| 异步等待     | `expr.await`<br>`expr.awake`                               | 脱糖为 `raise Await`/`Awake`   |

---

## 核心概念

### 效应操作 = 结构体

任何结构体都可以作为效应操作被 `raise`。结构体的字段自动转化为 `[get]x` / `[set]x` 方法，因此类型完全由方法集合决定（row）。

```valkyrie
structure Get
structure Put { new_value: i32 }
structure Log { msg: String }
```

`Get` 的方法集合为空行 `{}`，`Put` 的方法集合为 `{ [get]new_value: () -> i32, [set]new_value: (i32) -> () }`，`Log` 为 `{ [get]msg: () -> String, [set]msg: (String) -> () }`。类型仅由这些行决定，名称无关紧要。

### 可恢复性：`Effectful` trait

标准库定义 `Effectful` trait，用于标记可恢复效应及恢复时的参数类型：

```valkyrie
trait Effectful {
    type Resume
}
```

- 若一个结构体实现了 `Effectful`，则它是**可恢复的**，`raise` 该结构体时，表达式的类型为 `Resume`。
- 若未实现 `Effectful`，编译器隐式赋予 `Resume = !`（即不可恢复），`raise` 表达式的类型为 `!`，控制流不会返回。

统一规则：**只要 `Resume` 为 `!`，效应便不可恢复**，无论是否显式实现 `Effectful`。这消除了“是否实现 trait”的特殊判断。

示例：

```valkyrie
imply Get: Effectful { type Resume = i32 }
imply Put: Effectful { type Resume = () }
# Log 未实现 Effectful => Resume = !，不可恢复
```

### 提取器与 `Case` trait

消费正常值 `T` 和效应操作 `E` 都需要解构。解构行为由 `Case` trait 定义，**类型名即提取器**。`match` 和 `catch` 中的模式匹配均通过调用相应类型的 `Case` 实现完成，与字段的自动 `[get]` 无关。

```valkyrie
imply Get: Case { ... }
imply Put: Case { ... }
imply Log: Case { ... }
```

这保证了结构类型的开放性：任何实现相同 `Case` 协议的类型（即能通过该提取器解构出相同形状的值）都可被同一模式捕获。正常值与效应值的处理在此完全统一。

---

## `T / E` 的对偶性

### 产生侧

| 产生方式 | 表达式类型       | 说明                   |
|----------|------------------|------------------------|
| `value`  | `T / []`         | 正常返回，无效应       |
| `raise op` | `R / [Op]`    | `R` 为 `Op` 的 `Effectful::Resume`（或 `!`） |

### 消费侧

| 消费方式 | 表达式类型变化                | 说明                                 |
|----------|-------------------------------|--------------------------------------|
| `.match { case ... : ... }` | 从 `T / E` 到 `B / E`        | 只解构正常值 `T`，效应 `E` 完整透传 |
| `.catch { case ... : ... }` | 从 `T / E` 到 `B / (E \ E_h)` | 解构效应 `E` 的子集 `E_h`，可恢复   |

- `match` 不触碰效应，所以效应集合 `E` 不变。
- `catch` 处理掉一部分效应后，剩余效应为差集。若某分支未调用 `resume`（或不可恢复），该分支的返回类型 `B` 将成为整个 `catch` 的结果类型（此时 `B` 可能与 `T` 不同）。

这种对偶性使得正常计算流与效应处理流可以任意交织，通过链式调用清晰表达意图。

---

## 效应集合

### 表示方式

效应集合用方括号 `[...]` 表示，内部元素为效应类型（行类型），可用 `|` 分隔：

- 单个效应：`[Get]`
- 多个效应：`[Get, Put, Log]` 或 `[Get | Put | Log]`
- 空效应：`[]`（可省略，即纯计算）

函数签名中的效应标注为上界，实际效应必须为标注的子集（子效应关系）。

### 效应组别名

可以使用类型别名将关联的效应组合成单个名字，方便复用：

```valkyrie
type Awaiter<F> = Await<F> | Awake<F>
type State = Get | Put
```

这并不引入新的类型，只是提供简写。`[State, Log]` 等价于 `[Get, Put, Log]`。

### 子效应关系

效应集合的包含检查基于结构类型：`E1 ⊆ E2` 当且仅当对于 `E1` 中的每个效应类型 `r1`，存在 `E2` 中的某个效应类型 `r2`，使得 `r1 <: r2`。这里的子类型 `<:` 是行多态的子类型：`r1` 的方法集合**包含** `r2` 的方法集合（即 `r1` 更具体）。从而实际抛出的更具体效应可以安全地视为声明效应，因为调用者通过 `catch` 匹配时只依赖 `r2` 的方法，而这些方法在 `r1` 上一定存在。

---

## `raise` 与 `resume` 语义

### `raise expr`

1. 计算 `expr` 得到一个结构体值 `op : Op`。
2. 将 `op` 压入效应栈，查找能处理 `Op` 的最近 `catch` 处理器（基于 `Op` 实现的 `Case` 提取器匹配）。
3. 保存当前 continuation，跳转到处理器的匹配分支。
4. 若 `Op` 的 `Effectful::Resume` 为 `!`，则 `raise` 表达式的类型为 `!`，控制流不会返回；否则类型为 `Resume`。

### `resume(value)`

仅可在 `catch` 分支内使用。恢复被挂起的 continuation，将 `value` 作为原 `raise` 表达式的返回值。`value` 的类型必须严格等于被匹配效应的 `Effectful::Resume`。执行 `resume` 后，当前分支结束。

---

## `catch` 与 `match` 表达式

### `match` 表达式

```valkyrie
expr.match {
    case Pattern1: body1
    case Pattern2: body2
}
```

- `expr` 类型为 `T / E`。
- 模式仅匹配正常值 `T`，效应 `E` 原封不动。
- 各分支返回类型统一为 `B`，整体类型为 `B / E`。

### `catch` 表达式

```valkyrie
expr.catch {
    case Pattern1: body1
    case Pattern2: body2
}
```

- `expr` 类型为 `T / E`。
- 模式匹配 `E` 中的效应操作，基于各效应类型实现的 `Case` 提取器。
- 分支可包含 `resume(v)`。
- 类型规则：
  - 若所有分支均以 `resume` 结束，且被处理的效应子集为 `E_h`，则整体类型为 `T / (E \ E_h)`。
  - 若某些分支未调用 `resume` 且返回类型为 `B`，则要求所有此类分支返回类型可统一为 `B`，整体类型为 `B / (E \ E_h)`。

`catch` 不要求覆盖所有可能效应，未匹配的效应自动向外传播。

---

## `try Result<T, [E捕获]>` 表达式

将效应转化为不可恢复错误，从而用 `match` 统一处理：

```valkyrie
try Result<T, [E捕获]> {
    # 可 raise 各种效应
}
```

- `E捕获` 是一组效应类型（可用 `|` 分隔）。
- 语义：
  - 正常返回 `v : T` 则整体为 `Fine(v)`。
  - 若内部 `raise` 了属于 `E捕获` 的效应操作 `op`，则计算立即终止，整体为 `Fail(op)`。
- 类型：若块类型为 `T / (E ∪ E_c)`，其中 `E_c` 是 `E捕获` 对应的效应集合，则整体为 `Result<T, E_c_op> / E`（剩余效应 `E` 继续传播，`E_c_op` 为捕获到的效应类型的联合）。

后面接 `.match` 处理 `Fine`/`Fail`。

---

## 常用语法糖

### 生成器

标准库定义：

```valkyrie
unite Yielder<T> {
    Yield { value: T }
    YieldBreak
}
imply<T> Yielder<T>: Effectful { type Resume = () }
imply<T> Yielder<T>: Case { ... }   # 为两种变体自动生成提取器
```

`unite` 提供具名变体，每个变体均为独立结构体，但共享同一 `Effectful` 实现。

语法糖映射：

| 语法             | 脱糖结果                                        | 效应引入       |
|------------------|-------------------------------------------------|----------------|
| `yield expr`     | `raise Yielder::Yield { value: expr }`          | `Yielder<T>`   |
| `yield break`    | `raise Yielder::YieldBreak`                     | `Yielder<T>`   |
| `yield return expr` | `{ raise Yielder::Yield{value: expr}; raise Yielder::YieldBreak }` | `Yielder<T>` |

包含 `yield` 的函数自动带上 `Yielder<T>` 效应，可通过 `catch` 收集为迭代器。

### 异步

标准库定义：

```valkyrie
structure Await<F: Future> { future: F }
imply<F> Await<F>: Effectful { type Resume = F::Output }
imply<F> Await<F>: Case { ... }

structure Awake<F: Future> { future: F }
imply<F> Awake<F>: Effectful { type Resume = () }
imply<F> Awake<F>: Case { ... }

type Awaiter<F> = Await<F> | Awake<F>
```

语法糖映射：

| 语法          | 脱糖结果                               | 效应引入        |
|---------------|----------------------------------------|-----------------|
| `expr.await`  | `raise Await { future: expr }`         | `Await<F>`      |
| `expr.awake`  | `raise Awake { future: expr }`         | `Awake<F>`      |

异步运行时通过提供一个全局的 `catch` 处理器实现调度：

```valkyrie
micro run_async<A>(task: micro() -> A / [Awaiter<HttpFuture>]) -> A {
    task()
    .catch {
        case Await { future }:
            runtime.wait(future, result => resume(result))
        case Awake { future }:
            runtime.spawn(future)
            # Awake 的 Resume 为 ()，但此分支不 resume，
            # 属于未恢复分支，其返回值即为整个 catch 的结果
            runtime.default_value()
    }
}
```

---

## 完整示例

```valkyrie
# 定义状态效应
structure Get
imply Get: Effectful { type Resume = i32 }
imply Get: Case { ... }

structure Put { new_value: i32 }
imply Put: Effectful { type Resume = () }
imply Put: Case { ... }

# 定义日志效应（不可恢复）
structure Log { msg: String }
imply Log: Case { ... }
# 未实现 Effectful，Resume 为 !

# 业务函数
micro business() -> String / [Get, Put, Log] {
    let x = raise Get
    if x < 0 {
        raise Log { msg: "negative state" }
    }
    raise Put { new_value: x + 1 }
    "ok"
}

# 处理函数
micro handler() -> String {
    let state = 10
    try Result<String, [Log]> {
        business()
        .catch {
            case Get:
                resume(state)
            case Put { new_value }:
                state = new_value
                resume(())
        }
    }
    .match {
        case Fine(s):
            s
        case Fail(Log { msg }):
            print("Log error: " + msg)
            "error"
    }
}

# 生成器示例
micro numbers() -> () / [Yielder<i32>] {
    yield 1
    yield 2
    yield return 3
}

micro collect_numbers() -> List<i32> {
    var list = List::new()
    numbers()
    .catch {
        case Yielder::Yield { value }:
            list.push(value)
            resume(())
        case Yielder::YieldBreak:
            # 不可恢复，直接结束
    }
    list
}

# 异步示例
micro fetch(url: String) -> String / [Awaiter<HttpFuture>] {
    let future = HttpFuture::new(url)
    future.awake
    let data = future.await
    data
}
```

---

## 总结

本效应系统基于以下第一性原理构建：

- **对偶性**：正常值 `T` 与效应操作 `E` 平等，`match` 与 `catch` 对称，`return`（隐式）与 `raise` 对称。
- **结构类型统一**：类型完全由方法集合（行）决定，效应操作是普通结构体，消费模式基于 `Case` 提取器，无特殊名义。
- **可恢复性标记**：仅通过 `Effectful` trait 的关联类型 `Resume` 标记，`!` 表示不可恢复，语义简洁一致。
- **组合性**：效应集合通过并/差运算自然组合，`try` 提供效应隔离，`catch` 可任意链式组合。

整个设计没有任何魔法或特例，所有能力均来自于类型系统本身的结构多态与 trait 组合，因而具备高度的健壮性与可预测性。