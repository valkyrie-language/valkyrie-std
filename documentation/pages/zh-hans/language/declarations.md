# 声明

## 函数声明

`micro`、`mezzo`、`macro` 是 Valkyrie 中声明函数的关键字，按复杂度分级。

### `micro` — 轻量级函数

大多数情况使用 `micro`，这是默认选择。

```valkyrie
micro greet(name: string) {
    println("Hello, {name}")
}

micro add(a: i32, b: i32) -> i32 {
    return a + b
}
```

### 带特性标注

```valkyrie
[export]
micro calculate(x: i32) -> i32 {
    return x * 2
}

[serializable]
micro to_data() -> string {
    return "data"
}
```

### 参数格式

```valkyrie
micro named_params(x: i32, y: i32) -> i32 { x + y }
micro no_params() -> void { println("hello") }
micro with_type(x: i32, name: string) -> void { }
```

### `mezzo` — 中型函数

`mezzo` 适用于复杂逻辑或多阶段处理。

```valkyrie
mezzo process_pipeline(data: Data) -> Result {
    let stage1 = validate(data)?
    let stage2 = transform(stage1)
    finalize(stage2)
}
```

### `macro` — 宏/模板

`macro` 在编译期执行，用于代码生成和元编程。

```valkyrie
macro derive_iterator<T>() {
}
```

### 选型约定

大多数情况使用 `micro`。`mezzo` 和 `macro` 仅在特定需求下使用。

## 变量声明

### `let` — 不可变绑定

```valkyrie
let x = 42
let name = "Valkyrie"
let items = [1, 2, 3]
```

赋值后不可修改，适用于派生计算。

### `let mut` — 可变绑定

```valkyrie
let mut counter = 0
counter += 1
```

显式声明可变，适用于可变状态。

### `auto` — 类型推断

```valkyrie
let x: auto = 42           # 推断为 i32
let mut y: auto = "hello"  # 推断为 string
```

## 命名空间声明 — `namespace`

`namespace` 组织代码的层次结构。

```valkyrie
namespace game::physics {
    class Vector { ... }
}
```

## 导入声明 — `using`

`using` 将名称导入当前作用域，也可用于消除方法歧义。

```valkyrie
using game::physics::Vector
using std::collections::*
```

| 形式 | 说明 |
|:---|:---|
| `using std::io` | 标准库导入 |
| `using game::physics::Vector` | 单名称导入 |
| `using std::collections::*` | 通配符导入 |

详见 [路径解析](path-resolution.md) 和 [方法分发](method-dispatch.md)。

## 结构体声明 — `structure`

`structure` 声明不可变值类型，具有结构相等性语义。

### 位置结构

```valkyrie
structure Point(i32, i32)
structure Color(u8, u8, u8, u8)
structure UserId(i32)
```

### 命名结构

```valkyrie
structure UserSnapshot {
    id: i32,
    name: string,
    level: i32,
}
```

### 带默认值

```valkyrie
structure NetworkConfig {
    host: string = "localhost",
    port: i32 = 8080,
    timeout: i32 = 30,
}
```

### `with` 表达式

```valkyrie
let original = Point(1, 2)
let shifted = original with { x: original.x + 1 }

let config = NetworkConfig()
let production = config with { host: "prod.example.com", port: 443 }
```

### 解构

```valkyrie
let Point(x, y) = point
let { id, name } = user_snapshot
```

## 类声明 — `class`

`class` 声明类类型，大多数情况下使用 `class` 即可。`class` 并不意味着非要装箱，是否装箱取决于优化器的决策。`class` 支持继承。

```valkyrie
class Animal
    name: string
    age: i32

class Dog(Animal)
    breed: string
```

详见 [类继承](class-inheritance.md)。

## trait 声明 — `trait`

`trait` 定义类型的能力形状（接口），编译器自动推导类型是否满足。

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>
    into_iterator(self) -> Self::Iter
}
```

详见 [trait 系统](trait-system/)。

## union 声明 — `union`

`union` 声明代数数据类型（tagged union），每个变体使用 record-style 字段定义。模式匹配使用 `match` / `case`；构造与匹配还可使用紧凑语法 `Some(x)` / `case Some(x)`。

```valkyrie
union Option<T> {
    Some { value: T }
    None
}

union Result<T, E> {
    Ok { value: T }
    Err { error: E }
}
```

`unite` 是 `union` 的紧凑内联形式（值类型），适合小体积、高频使用的场景。

## flags 声明 — `flags`

`flags` 声明位标志类型，支持按位组合。

```valkyrie
flags Permissions {
    Read = 1,
    Write = 2,
    Execute = 4,
}
```

## 泛型约束 — `where`

`where` 子句对泛型参数施加 trait 约束。

```valkyrie
micro sum<C, T>(self: C) -> Option<T>
    where C: IntoIterator<Item = T> & Add<Item = T>
```

`class` 内部方法也可用 `where` 实现条件特化。

## 组件声明 — `component`

`component` 声明 ECS 纯数据容器。

```valkyrie
component Position {
    x: f32;
    y: f32;
}
```

详见 [ECS 扩展](extensions/ecs-extension.md)。

## 系统声明 — `system`

`system` 声明 ECS 逻辑处理器。

```valkyrie
system MovementSystem {
    query all = Query.all(Position, Velocity);

    on_update(frame: Frame) {
        loop entity in query.all {
            entity.position.x += entity.velocity.dx * frame.dt
        }
    }
}
```

详见 [ECS 扩展](extensions/ecs-extension.md)。