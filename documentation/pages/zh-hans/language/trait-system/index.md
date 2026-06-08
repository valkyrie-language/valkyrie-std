# trait 系统

## 概述

trait 是 Valkyrie 的"能力宪法"——定义一组方法签名和关联类型，描述类型"能做什么"。与名义类型系统不同，Valkyrie 采用**结构子类型**（Structural Subtyping）：编译器自动判断任意 `class` 是否满足某个 trait，无需 `class` 显式声明实现。

核心设计原则：

| 原则 | 说明 |
|:---|:---|
| 结构推导 | 编译器根据方法签名自动判定 trait 满足关系，零运行时开销 |
| 零侵入 | `class` 作者无需声明 `implements`，能力从形状自动推导 |
| 无字段 | trait 不得包含字段，字段属于 `class` / `structure` 的职责 |
| 默认方法 | trait 可提供基于其他方法实现的默认行为，`class` 可按需覆盖 |

## trait 定义语法

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>

    into_iterator(self) -> Self::Iter
}
```

关联类型用 `type` 声明。冒号后可以跟边界约束——如 `Iter: Iterator<Item = Self::Item>` 要求关联类型 `Iter` 必须满足 `Iterator` trait，且其 `Item` 等于当前 trait 的 `Item`。

trait 体只包含方法签名和关联类型声明，不得包含字段。

`Self` 在 trait 定义中指向"实现该 trait 的当前类型"。

## 结构推导

编译器对每个 `class` 自动执行以下推导步骤：

| 步骤 | 动作 | 说明 |
|:---|:---|:---|
| 1 | 检查方法签名 | 逐方法比对：名称、参数类型、返回类型完全一致即匹配 |
| 2 | 推断关联类型 | 从匹配方法的返回类型和参数类型推断 trait 中 `type` 的具体类型 |
| 3 | 验证关联类型约束 | 确保推断出的关联类型满足其边界约束（如 `Iter: Iterator`） |
| 4 | 建立满足关系 | 将 `class` 注册为该 trait 的满足者 |

以 `Vec<T>` 满足 `IntoIterator` 为例：

1. **检查方法签名**：`Vec<T>` 中存在 `into_iterator(self) -> VecIterator<T>`，与 `IntoIterator` 的 `into_iterator(self) -> Self::Iter` 形状匹配。
2. **推断关联类型**：
   - `Self::Item` 从 `VecIterator<T>` 的 `Item` 关联类型推导 → `T`
   - `Self::Iter` 从返回类型推导 → `VecIterator<T>`
3. **验证约束**：`VecIterator<T>` 确实满足 `Iterator<Item = T>`，通过。
4. **建立关系**：`Vec<T>` 被注册为 `IntoIterator`，编译器在需要 `IntoIterator` 的上下文中接受 `Vec<T>`。

整个过程发生在编译期，零运行时开销，`Vec<T>` 的作者无需任何声明。

## trait 默认方法

trait 可提供 `default` 方法的实现，依赖当前 trait 的其他方法：

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>

    into_iterator(self) -> Self::Iter

    collect(self) -> Vec<Self::Item> {
        let mut out = Vec::new()
        loop item in self.into_iterator() {
            out.push_back(item)
        }
        out
    }

    count(self) -> i32 {
        let mut n = 0
        loop _ in self.into_iterator() {
            n = n + 1
        }
        n
    }
}
```

**覆盖规则**：

| 场景 | 行为 |
|:---|:---|
| `class` 定义了同名方法 | 使用 `class` 版本（覆盖默认实现） |
| `class` 未定义同名方法 | 使用 trait 的 `default` 实现 |
| 多个 trait 提供同名默认方法 | 编译错误，必须显式覆盖消除歧义 |

覆盖是"特化仅在 `class` 内部"原则的体现——trait 提供的只是"最通用"的实现，`class` 知道自己内部的存储布局，可以提供更高效的版本。

## trait 别名

```valkyrie
trait RandomAccessContainer<T> = Indexable<Item = T> & ExtractLength
```

trait 别名是纯语法糖：

| 特性 | 说明 |
|:---|:---|
| 能力 | 不引入新的能力实体，仅为已有 trait 组合起名 |
| 分派 | 不参与方法分派，方法调用追溯到组合中的原始 trait |
| 推导 | 结构推导检查组合中的每个 trait 是否被满足 |
| 约束 | `where T: RandomAccessContainer<i32>` 等价于 `where T: Indexable<Item = i32> & ExtractLength` |

`&` 是 trait 组合运算符，表示"同时满足"。

## 标准库核心 trait 谱系

### 迭代与遍历

| trait | 方法 | 说明 |
|:---|:---|:---|
| `IntoIterator` | `into_iterator(self) -> Self::Iter` | 转换为迭代器，消耗自身所有权。关联类型 `Item` 和 `Iter: Iterator<Item = Self::Item>` |
| `Iterator` | `next(ref self) -> Option<Self::Item>` | 推进迭代器到下一项，返回 `Some(item)` 或 `None`。关联类型 `Item` |
| `DoubleEndedIterator` | `next_back(ref self) -> Option<Self::Item>` | 从尾部推进，支持双向迭代。继承 `Iterator` |

### 长度信息

| trait | 方法 | 说明 |
|:---|:---|:---|
| `ExtractLength` | `extract_length(self) -> i32` | 获取元素数量，保证 O(1) 时间复杂度 |
| `Countable` | `count_hint(self) -> i32`、`count(self) -> i32` | `count_hint` 提供估计数量，`count` 精确计数（可能 O(n)） |

### 索引与查找

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Indexable` | `at(ref self, index: i32) -> Self::Item` | 整数索引访问。关联类型 `Item` |
| `Lookup` | `lookup(ref self, key: Self::Key) -> Option<Self::Value>` | 键值查找。关联类型 `Key` 和 `Value` |
| `Contains` | `contains(ref self, value: Self::Item) -> bool` | 判断是否包含指定元素。关联类型 `Item` |

### 添加与移除

| trait | 方法 | 说明 |
|:---|:---|:---|
| `PushBack` | `push_back(ref self, value: Self::Item)` | 在尾部添加元素 |
| `PushFront` | `push_front(ref self, value: Self::Item)` | 在头部添加元素 |
| `PopBack` | `pop_back(ref self) -> Option<Self::Item>` | 移除并返回尾部元素 |
| `PopFront` | `pop_front(ref self) -> Option<Self::Item>` | 移除并返回头部元素 |
| `Insertable` | `insert(ref self, index: i32, value: Self::Item)` | 在指定位置插入元素 |
| `RemovableAt` | `remove_at(ref self, index: i32) -> Option<Self::Item>` | 移除指定位置的元素 |
| `Clearable` | `clear(ref self)` | 清空所有元素 |

### 有序与优先级

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Ordered` | `compare(ref self, other: Self) -> Ordering` | 全序比较。派生 `PartialEq` 和 `PartialOrd` 行为 |
| `Priority` | `extract_priority(self) -> i32` | 提取优先级整数值，用于优先队列排序 |

### 并行

| trait | 方法 | 说明 |
|:---|:---|:---|
| `ParallelIterable` | `into_parallel_iterator(self) -> Self::ParIter` | 转换为并行迭代器。关联类型 `ParIter: ParallelIterator` |
| `ParallelIterator` | `next_chunk(ref self, size: i32) -> Option<list<Self::Item>>` | 并行拉取一批元素 |

### 批量与映射

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Extendable` | `extend(ref self, other: Self::Item)` | 批量追加另一个容器中的所有元素 |
| `ImmPushBack` | `imm_push_back(self, value: Self::Item) -> Self` | 不可变式尾部追加，返回新实例，原实例不变。用于持久化数据结构 |

## 与其他关键字的关系

### trait 与 class

| 方面 | trait | class |
|:---|:---|:---|
| 职责 | 定义能力形状（方法签名 + 关联类型） | 定义具体类型（字段 + 方法实现） |
| 实例化 | 不可实例化 | 可实例化 |
| 包含字段 | 否 | 是 |
| 实现关系 | 被结构推导判定满足 | 被编译器检查是否满足 trait |
| 默认实现 | 可提供 `default` 方法 | 方法实现为最终行为 |

### trait 与 micro

`micro` 函数通过 `where` 约束引用 trait，实现泛型约束：

```valkyrie
micro sum_up<T>(items: T) -> i32
    where T: IntoIterator, T::Item: Addable
{
    let mut total = 0
    loop item in items.into_iterator() {
        total = total + item
    }
    total
}
```

`where` 子句中的 `T: IntoIterator` 表示类型 `T` 必须满足 `IntoIterator` trait，`T::Item: Addable` 进一步约束关联类型。

### trait 与 union / unite

`union` 和 `unite` 的变体可作为 trait 方法的返回类型：

```valkyrie
union IntOrString {
    Int(i32)
    Str(string)
}

trait FallibleParser {
    parse(self, input: string) -> Fine<Self::Output> | Fail<ParseError>
}
```

trait 方法返回联合类型时，调用方使用 `catch` 处理各变体分支。详见 [Effect 系统](../effect-system/)。

## 边界原则

### 显式 trait

部分 trait 涉及语义层面的保证（如内存安全、线程安全），无法仅凭方法签名判定——其满足关系**不能**仅凭形状推导，必须由类型作者显式声明。

| trait 类别 | 推导方式 | 示例 |
|:---|:---|:---|
| 普通 trait | 编译器自动从形状推导 | `IntoIterator`、`Indexable`、`ExtractLength` |
| 显式 trait | 类型作者显式声明 | `Serializable`、`Sendable`、`Syncable`、`Cloneable` |

例如 `Serializable` 要求类型的所有字段都可序列化——这是递归的语义保证，不是签名级信息。

### 外部类型与包裹类

外部代码（来自其他包或运行时的类型）**绝不**通过形状自动获得显式 trait。外部类型必须通过**包裹类**（Wrapper Class）显式封装后才能参与 trait 推导：

```valkyrie
# 外部类型 ExternVec 有 push_back 方法，但不会自动满足 PushBack
# 必须创建包裹类：

class MyVec
    inner: ExternVec

    push_back(ref self, value: i32) {
        self.inner.push_back(value)
    }
end
```

包裹类通过在 `class` 内部手动实现对应方法来"认领" trait 满足关系。编译器对包裹类同样执行结构推导——只要方法签名匹配，就会建立 trait 满足关系。

对于涉及 FFI 的外部类型，显式 trait 的约束同样适用。详见 [特性标注](../attributes.md)。

### 推导边界总结

| 类型来源 | 普通 trait | 显式 trait |
|:---|:---|:---|
| 当前包定义的 `class` | 自动形状推导 | 需显式声明 |
| 外部包的类型 | 自动形状推导 | **永不**自动获得，必须通过包裹类 |
| FFI 类型 | 自动形状推导 | **永不**自动获得，必须通过包裹类 |