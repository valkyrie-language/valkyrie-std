# 语句

## 块语句

```valkyrie
{
    let x = 1
    let y = 2
    x + y
}
```

块语句用大括号 `{}` 包裹，最后一个表达式的值作为块的返回值。

## 条件语句

### if

```valkyrie
if x > 0 {
    println("positive")
}
```

### if-else

```valkyrie
if x > 0 {
    println("positive")
} else {
    println("non-positive")
}
```

### if-else if-else

```valkyrie
if x > 0 {
    println("positive")
} else if x < 0 {
    println("negative")
} else {
    println("zero")
}
```

## 循环语句

### while — 条件循环

```valkyrie
let mut count = 0
while count < 10 {
    count += 1
}
```

### loop — 遍历循环

`loop` 是 Valkyrie 的统一迭代语法，替代 `for` 和 `foreach`。

#### 范围遍历

```valkyrie
loop i in 0..10 {
    println(i)
}
```

#### 集合遍历

```valkyrie
loop item in items {
    process(item)
}
```

#### 带条件过滤

```valkyrie
loop item in items if item.active {
    process(item)
}
```

#### 模式匹配遍历

```valkyrie
loop (index, item) in enumerate(items) {
    println("[{index}]: {item}")
}

loop [head, ..tail] in list {
    process(head)
}
```

#### while let — 条件模式匹配

```valkyrie
while let Some(value) = try_next() {
    process(value)
}
```

## 返回语句

```valkyrie
micro add(a: i32, b: i32) -> i32 {
    return a + b
}

micro early_return(x: i32) -> i32 {
    if x < 0 {
        return 0
    }
    return x * 2
}
```

## 效应语句

效应系统是 Valkyrie 的代数效应机制，详见 [效应系统设计](../effect-system/)。

### raise — 抛出效应

```valkyrie
raise Get;
raise Put { new_value: 42 };
raise Log { msg: "error occurred" };
```

`raise expr` 抛出一个效应操作。`expr` 为任意结构体实例，若该结构体实现了 `Effectful` trait 则为可恢复效应，否则为不可恢复效应。

### yield — 生成器产出

```valkyrie
yield 42;
yield break;
yield return 99;
```

`yield` 是生成器的语法糖，脱糖规则：

| 语法 | 脱糖结果 |
|:---|:---|
| `yield expr` | `raise Yielder::Yield { value: expr }` |
| `yield break` | `raise Yielder::YieldBreak` |
| `yield return expr` | `{ raise Yielder::Yield{ value: expr }; raise Yielder::YieldBreak }` |

### try — 效应转 Result

```valkyrie
try Result<String, [Log]> {
    business()
        .catch { case Get: resume(state) }
}
.match {
    case Fine(s): s
    case Fail(Log { msg }): print("error: " + msg)
}
```

`try` 将一组效应操作转为 `Result<T, E>`。正常返回则产生 `Fine(v)`，若内部 `raise` 了捕获列表中的效应则立即终止并产生 `Fail(op)`。

## 表达式语句

任何表达式都可以作为语句使用：

```valkyrie
println("hello")
counter += 1
x + y
```
