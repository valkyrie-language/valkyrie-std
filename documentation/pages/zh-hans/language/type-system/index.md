# 类型系统

## 原始类型

### 整数类型

| 类型 | 说明 | 范围 |
|:---|:---|:---|
| `i8` | 8 位有符号整数 | -128 ~ 127 |
| `i16` | 16 位有符号整数 | -32768 ~ 32767 |
| `i32` | 32 位有符号整数 | -2^31 ~ 2^31-1 |
| `i64` | 64 位有符号整数 | -2^63 ~ 2^63-1 |
| `u8` | 8 位无符号整数 | 0 ~ 255 |
| `u16` | 16 位无符号整数 | 0 ~ 65535 |
| `u32` | 32 位无符号整数 | 0 ~ 2^32-1 |
| `u64` | 64 位无符号整数 | 0 ~ 2^64-1 |

### 浮点类型

| 类型 | 说明 |
|:---|:---|
| `f32` | 32 位浮点数（IEEE 754 单精度） |
| `f64` | 64 位浮点数（IEEE 754 双精度） |

### 其他原始类型

| 类型 | 说明 |
|:---|:---|
| `bool` | 布尔类型，值为 `true` 或 `false` |
| `string` | UTF-8 字符串 |
| `void` | 空类型，函数无返回值时使用 |
| `auto` | 类型推断，由编译器推导实际类型 |

## 泛型类型

| 类型 | 说明 | 示例 |
|:---|:---|:---|
| `list<T>` | 动态长度列表 | `list<i32>` |
| `map<K, V>` | 键值映射 | `map<string, i32>` |
| `Option<T>` | 可选值（可嵌套） | `Option<i32>` |
| `future<T>` | 异步值 | `future<string>` |

嵌套泛型：

```valkyrie
let nested: list<list<i32>> = [[1, 2], [3, 4]]
let mapping: map<string, list<i32>> = {"a": [1, 2]}
```

## 自定义类型

### 函数类型

使用 `micro` 关键字标注函数类型：

```valkyrie
let add: micro(i32, i32) -> i32 = micro(a, b) { a + b }
let callback: micro(event: Event) -> void = on_click
```

详见 [复合类型](compound-types.md)。

### 结构体类型

使用 `structure` 关键字声明不可变值类型：

```valkyrie
structure Point(i32, i32)
structure UserSnapshot { id: i32, name: string }
```

详见 [声明](../declarations.md)。

### trait 类型

使用 `trait` 关键字定义结构类型约束，编译器推导 class 是否自动满足 trait：

```valkyrie
trait Display {
    to_string(self) -> string
}

micro display(value: Display) {
    println(value.to_string())
}
```

任何定义了 `to_string(self) -> string` 的类型自动满足 `Display`，无需显式声明实现。

### 类类型

使用 `class` 关键字声明类类型，大多数情况下使用 `class` 即可。`class` 并不意味着非要装箱，是否装箱取决于优化器的决策。`class` 支持继承。

```valkyrie
class Animal
    name: string
    age: i32
```

详见 [声明](../declarations.md) 和 [类继承](../class-inheritance.md)。

### 枚举类型

#### 离散枚举（`enums`）

使用 `enums` 关键字声明离散枚举值：

```valkyrie
enums Status {
    Inactive = 0,
    Active = 1,
}
```

#### 位标志（`flags`）

使用 `flags` 关键字声明位标志组合：

```valkyrie
flags Permission {
    Read = 1,
    Write = 2,
    Execute = 4,
}
```

#### 代数数据类型（`union`）

使用 `union` 关键字声明代数数据类型（tagged union），为引用类型：

```valkyrie
union Result {
    Ok(i32),
    Err(string),
}
```

#### 紧凑内联 union（`unite`）

使用 `unite` 关键字声明紧凑内联 union，为值类型：

```valkyrie
unite CompactResult {
    Ok(i32),
    Err(string),
}
```

### 联合类型

使用 `|` 运算符组合类型：

```valkyrie
let value: i32 | f32 | string = 42
```

详见 [复合类型](compound-types.md)。

## 容器与可空语法糖

| 语法糖 | 等价形式 | 说明 |
|:---|:---|:---|
| `[T]` | `list<T>` | 动态列表 |
| `[T; N]` | `array<T, N>` | 定长数组 |
| `T?` | `T \| null` | 可空（扁平化） |

详见 [容器与可空类型](container-nullable-types.md)。

## 类型兼容性

### IsAssignableFrom 规则

| 源类型 | 目标类型 | 可赋值 | 说明 |
|:---|:---|:---|:---|
| `i32` | `i32` | ✅ | 类型相同 |
| `i32` | `f32` | ❌ | 不同原始类型需显式转换 |
| `i32` | `i32 \| f32` | ✅ | 联合类型包含源类型 |
| `T` | `T?` | ✅ | 可空是联合的语法糖 |
| T（满足 TraitA）| TraitA | ✅ | 结构推导：编译器自动确认 |
| T（满足 A & B）| A | ✅ | 交集类型投影 |
| T | A \| B | ✅ | 联合类型包含源类型时 |
| `Dog` | `Animal` | ✅ | 子类可赋值给父类 |
| `micro(i32) -> i32` | `micro(i32) -> i32` | ✅ | 函数签名匹配 |

### 类型属性

| 属性 | 适用类型 |
|:---|:---|
| `IsNumeric` | `i8`~`i64`、`u8`~`u64`、`f32`、`f64` |
| `IsInteger` | `i8`~`i64`、`u8`~`u64` |
| `IsFloat` | `f32`、`f64` |
| `IsPrimitive` | 所有原始类型 |

### 结构推导兼容性

Valkyrie 采用**结构子类型**（structural subtyping），而非名义子类型（nominal subtyping）。
类型兼容性由**形状是否匹配**决定，而非"是否声明实现"。

编译器在编译期遍历 class 的方法集，与 trait 要求的方法签名逐一比对，
全部匹配则判定该类满足该 trait。此过程零运行时开销。
