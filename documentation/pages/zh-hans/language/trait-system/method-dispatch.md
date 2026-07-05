# 方法分派规则

## 概述

方法分派规则是 Valkyrie 语言设计中最核心的机制。它定义了 `x.method(args)` 在编译期如何选择实际被调用的实现。Valkyrie 对此确立了一条绝对的优先级链，编译器严格遵循，绝无例外。

## 三级分派顺序（铁律）

当编译器遇到 `x.method(args)` 时，按以下步骤查找，**找到即停止**：

| 步骤 | 查找位置 | 说明 |
|:---:|:---|:---|
| 第一步 | `class` 自有方法 | 检查 `x` 所属 `class` 的定义体 |
| 第二步 | `trait` 方法 | 检查 `x` 所满足的所有 `trait` |
| 第三步 | 当前作用域可见的独立 `micro` | 检查当前作用域内的独立 `micro` |

### 第一步：class 自有方法

检查 `x` 所属 `class` 的定义体，是否定义了名为 `method` 且参数签名兼容的方法。若有，选中。查找结束。

```valkyrie
class Dog
    name: string

    bark(self) -> string { "汪汪！" }
    sleep(self, hours: i32) -> string { "睡了{hours}小时" }

let dog = Dog { name: "旺财" }
dog.bark()       # 选中 class 自有方法 Dog::bark
dog.sleep(8)     # 选中 class 自有方法 Dog::sleep
```

类自有方法拥有最高优先级，因为类的作者最了解自己的数据结构。

### 第二步：trait 方法（含默认实现）

检查 `x` 所满足的所有 `trait` 中，哪些提供了名为 `method` 的方法。

| 情况 | 结果 |
|:---|:---|
| 只有一个 `trait` 提供 | 选中该 `trait` 的方法 |
| 多个 `trait` 提供 | 编译错误：歧义 |
| 没有 `trait` 提供 | 进入第三步 |

```valkyrie
trait Loggable {
    log(self) -> string { "默认日志" }
}

trait Serializable {
    serialize(self) -> string
}

class Data : Loggable, Serializable {
    serialize(self) -> string { "序列化数据" }
}

let data = Data {}
data.log()         # 选中 Loggable::log（唯一提供者）
data.serialize()   # 选中 Data::serialize（第一步 class 自有方法优先于 trait）
```

**多 trait 同名歧义示例：**

```valkyrie
trait Printable {
    process(self) -> string { "打印中..." }
}

trait Loggable {
    process(self) -> string { "记录中..." }
}

class Document : Printable, Loggable {}

let doc = Document {}
doc.process()  # 编译错误：Printable::process 和 Loggable::process 歧义
```

### 第三步：当前作用域可见的独立 micro

检查当前作用域内是否存在名为 `method` 的独立 `micro`，且其第一个参数（`self`）的类型约束与 `x` 兼容。若有，选中。若无，编译错误。

```valkyrie
micro greet(self: Dog) -> string {
    "你好，我是{self.name}"
}

let dog = Dog { name: "旺财" }
dog.greet()  # 选中独立 micro greet，第一个参数类型 Dog 与 dog 兼容
```

独立 `micro` 是纯粹的算法蓝图，不属于任何类型，作为最后一级兜底。

## 为什么这个顺序不可动摇

| 优先级 | 机制 | 原理 |
|:---:|:---|:---|
| 最高 | `class` 自有方法 | `class` 作者最了解自己的数据结构，理应拥有最终控制权 |
| 次之 | `trait` 方法 | `trait` 是类型主动满足的契约，代表了类型的明确承诺 |
| 兜底 | 独立 `micro` | 独立 `micro` 是纯粹算法蓝图，允许第三方在不修改类型的前提下扩展行为 |

这个顺序保证了：**越接近数据定义者，话语权越大**。这是一种"所有权"优先的设计哲学。

## class 内部的条件特化（唯一合法的特化）

`class` 作者可在 `class` 内部为同名方法提供多个版本，通过 `where` 子句限定不同适用条件。这是 Valkyrie 中唯一合法的同名方法重载形式。

```valkyrie
class Vec<T> {
    items: [T]

    sum(self) -> Option<T> where T: Add + Ord {
        # 基础版本：依赖 Add 和 Ord
        reduce(self.items, 0, |acc, x| acc + x)
    }

    sum(self) -> Option<T> where T: Copy + Add + Ord {
        # 优化版本：利用 Copy 特性避免移动
        reduce(self.items, 0, |acc, x| acc + x)
    }

    sum(self) -> Option<i32> where T = i32 {
        # 特化版本：i32 上的专用实现
        self.items.fold(0, |acc, x| acc + x)
    }
}
```

编译器根据类型参数的具体性选择最匹配版本：

| 类型参数 | 选中版本 | 原因 |
|:---|:---|:---|
| `Vec<f32>` | 通用版本 `T: Add + Ord` | `f32` 不满足 `Copy` |
| `Vec<string>` | 通用版本 `T: Add + Ord` | `string` 满足 `Add` 但不满足 `Copy` |
| `Vec<i32>` | 特化版本 `T = i32` | 精确匹配，具体性最高 |
| `Vec<u64>` | 优化版本 `T: Copy + Add + Ord` | 满足所有约束且不是 i32 |

同等具体的歧义导致编译错误：

```valkyrie
class Ambiguous<T> {
    method(self) -> string where T: Display + Clone { "A" }
    method(self) -> string where T: Clone + Display { "B" }
    # 编译错误：两个版本的约束集合等价，无法区分
}
```

## trait 方法歧义消解（三种手段）

当多个 `trait` 提供同名方法时，Valkyrie 要求调用者显式消歧。

### 方式一：全限定调用

使用 `Trait::method` 语法直接指定哪个 `trait` 的方法：

```valkyrie
let result1 = Loggable::process(&data)
let result2 = Printable::process(&data)
```

全限定调用是最直接、最明确的消歧方式，推荐在调用点明确知道意图时使用。

### 方式二：using 声明

在当前作用域通过 `using` 声明导入特定的 `trait` 方法：

```valkyrie
using Loggable::process

x.process()  # 明确使用 Loggable 版本
```

`using` 声明影响整个当前作用域，适用于某个作用域内统一使用特定 `trait` 版本的场景。

```valkyrie
{
    using Printable::process
    doc1.process()  # Printable 版本
    doc2.process()  # Printable 版本
}

{
    using Loggable::process
    doc3.process()  # Loggable 版本
}
```

### 方式三：包裹类型转发

通过创建包裹类型，在类内部显式转发到特定的 `trait` 方法：

```valkyrie
class MyWrapper {
    inner: SomeType

    process(self) {
        Loggable::process(&self.inner)
    }
}
```

这种方式的优势在于将消歧决策封装在类型定义中，调用者无需关心底层细节。

## MRO（多继承方法解析顺序）

`super.method()` 在 Valkyrie 中的行为由 MRO（Method Resolution Order）决定，采用从左到右的深度优先线性化（C3 线性化）。

```valkyrie
class A {
    method(self) -> string { "A" }
}

class B {
    method(self) -> string { "B::" + super.method() }
}

class C {
    method(self) -> string { "C" }
}

class D(B, C) : A {
    # MRO: D → B → C → A
    method(self) -> string { "D::" + super.method() }
}
```

| 调用 | 解析链 | 结果 |
|:---|:---|:---|
| `D {}.method()` | D → B → C → A | `"D::B::C::A"` |

### 重要限定

- MRO **仅影响** `super.method()` 语法糖的查找路径
- MRO **不参与**全局方法分派（`x.method()` 的三级优先级链）
- 两者的职责完全正交，互不干涉

## witness table 概念

> **术语区分**
>
> | 术语 | 所属层级 | 含义 |
> |:---|:---|:---|
> | **witness table** | Valkyrie `trait` / `imply` | 非侵入式胖指针 `(data, witness)`，记录“类型满足某 trait”的证据 |
> | **COM vtable** | Windows FFI（`[com]`） | COM 接口对象首指针处的虚表，按槽位调用外部方法 |
> | **传统 OOP vtable** | 对比参照（C++ 等） | 侵入式类虚表，**不是** Valkyrie 的实现模型 |
>
> 下文 “witness table” 均指 Valkyrie 语言机制；与 COM / 传统 vtable 的对比见文末表格。

Witness Table 是编译器的核心数据结构，将"类型 `T` 满足 `trait X`"转化为可传递的编译期证据。

### 结构

对于每对（具体类型 `C`，`trait T`），编译器生成独立的静态证据对象，包含 `C` 实现 `T` 所需的所有方法的函数指针。

以 `IntoIterator` witness 为例：

```valkyrie
trait IntoIterator {
    type Item
    type IntoIter: Iterator<Item=Self::Item>

    into_iter(self) -> Self::IntoIter
}

class Vec<T> : IntoIterator {
    type Item = T
    type IntoIter = VecIter<T>

    into_iter(self) -> VecIter<T> { ... }
}
```

编译器为 `Vec<i32>` 生成类似以下结构的 witness table：

| 条目 | 内容 |
|:---|:---|
| `trait` 标识 | `IntoIterator` |
| 具体类型 | `Vec<i32>` |
| `type Item` | `i32` |
| `type IntoIter` | `VecIter<i32>` |
| `into_iter` 函数指针 | `&Vec::<i32>::into_iter` |

### 与 vtable 的对比

以下对比的是 Valkyrie **witness table** 与**传统 OOP vtable**（C++ 式类虚表），不含 Windows `[com]` 的 COM vtable（后者属于 FFI，见 [特性标注 — `[com]`](../attributes.md)）。

| 特性 | vtable（传统语言） | witness table（Valkyrie） |
|:---|:---|:---|
| 存储位置 | 嵌入对象头部（对象膨胀） | 编译期静态生成，独立存储 |
| 传递方式 | 随对象指针隐式传递 | 作为独立参数显式传递 |
| 大小开销 | 每个对象携带指针（8 字节） | 调用点按需传入，无对象膨胀 |
| 单态化友好度 | 阻碍单态化 | 天然支持单态化，编译器可完全消去 |

Witness Table 的设计消除了传统 OOP 中每个对象携带 vtable 指针的膨胀问题，同时保留了 `trait` 的动态分派能力。

## 显式原则

任何可能引起行为歧义的语言构造，都必须由人类作者显式消歧，编译器绝不代劳。

| 场景 | 策略 | 示例 |
|:---|:---|:---|
| 多继承同名方法冲突 | 子类作者显式消歧 | `super<B>.method()` |
| 多 `trait` 同名方法 | 调用者显式消歧 | `TraitA::method(x)` 或 `using` |
| 独立 `micro` | 不允许重载 | 不同功能必须使用不同名字 |

这一原则贯穿 Valkyrie 语言设计的始终，确保代码的行为在任何情况下都是可预测、可阅读、可审计的。

```valkyrie
# 以下写法将导致编译错误：
micro process(x: Dog) -> string { "处理狗" }
micro process(x: Cat) -> string { "处理猫" }
# 编译错误：独立 micro 不允许重载，请使用不同名字

# 正确做法：
micro process_dog(x: Dog) -> string { "处理狗" }
micro process_cat(x: Cat) -> string { "处理猫" }
```