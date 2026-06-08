# 效应系统实现手册

本文档详细描述在 Valkyrie 编译器中实现效应系统的技术方案，涵盖类型检查、中间表示降级、代码生成和运行时模型。读者需已熟悉 [效应系统设计](#) 中的核心概念与语法。

---

## 1. 类型表示

### 1.1 表达式类型

每个表达式类型在编译器内部表示为 `Typed` 结构：

```
Typed {
    normal: Type,       // 正常返回类型 T
    effects: Set<EffectType>  // 效应类型集合 E
}
```

- `normal` 为任意 Valkyrie 类型（包括行类型变量）。
- `effects` 为一组 **效应类型**，每个效应类型是一个具体的**行类型**（可能带行变量），代表一个可被 `raise` 的结构体。

效应类型集合的表示不采用简单的标识符集合，而是一组行类型，因为结构类型系统下效应操作的“身份”由其完整的方法集合决定。例如 `Put` 效应可能表示为 `{ [get]new_value: () -> i32, [set]new_value: (i32) -> () }`。

### 1.2 效应类型（EffectType）

```
EffectType = RowType   // 至少包含所有 [get]/[set] 及自身方法，可能存在行变量约束
```

特殊效应：
- 空效应集 `[]` 表示纯计算。
- 不可恢复效应在类型上并不特殊，只是在 `raise` 时产生的正常类型为 `!`，效应集中仍包含该效应类型。

`Effectful` trait 的 `Resume` 关联类型在类型系统中作为效应类型的一个**附属属性**存储，不直接作为效应集合的一部分，而是在处理 `raise`/`resume` 时查询。

### 1.3 效应多态

函数类型带效应变量 `E` 时，`E` 是一个效应集合的变量，内部表示为一个 `EffectSet` 类型的变量。在实例化时，通过约束求解推导出具体效应集合。

---

## 2. 类型检查

### 2.1 效应推导

类型检查阶段采用自底向上推导每个子表达式的 `Typed`，并根据组合规则计算上级表达式的效应。

**核心规则**：

- **字面量/纯调用**：`effects = []`
- **`raise expr`**：
  - 若 `expr` 的类型为 `Op`（一个结构体/行类型），则表达式类型为：
    - `normal = Effecful::Resume`（若 `Op` 实现了 `Effectful`），否则 `normal = !`
    - `effects = { Op }`
- **`e.match { ... }`**：
  - `normal = 合并分支返回类型`，`effects = e.effects`
- **`e.catch { ... }`**：
  - 对于每个分支 `case Extractor pattern: body`：
    - 若分支以 `resume(v)` 结束，则该分支不贡献最终正常类型（`normal` 保持 `e.normal`）
    - 若分支未恢复（或不可恢复），则该分支的返回类型 `B_i` 参与最终正常类型的合并
  - `normal = merge(all B_i)`（若所有分支恢复则为 `e.normal`）
  - `effects = e.effects \ handled_effects`，其中 `handled_effects` 是被各分支覆盖的效应类型的并集。覆盖判定：提取器对应的效应类型（由 `Case` 实现关联）如果是当前效应集合中某个类型的超类型（结构子类型），则认为该效应被处理。
- **`try Result<T, [E_c]> { ... }`**：
  - 内部块的类型推导为 `T' / E_body`
  - 将被捕获的效应集合 `E_c` 与 `E_body` 求交，验证它们确实是可捕获的效应（可被提取器匹配）
  - 整体类型为 `Result<T, E_c_op> / (E_body \ E_c)`，其中 `E_c_op` 为由 `E_c` 中具体效应类型所构成的匿名联合类型（若 `E_c` 为单个类型则是它本身）

**函数体推导**：
- 遍历函数体所有返回点和 `raise` 点，收集效应并求并集。
- 函数声明效应为 `E_decl`，若 `E_body ⊆ E_decl` 则通过，否则报错。

**效应集合的包含检查**：对于 `E1` 中的每个效应类型 `r1`，必须在 `E2` 中存在一个 `r2` 使得 `r1 <: r2`。行子类型 `r1 <: r2` 当且仅当 `r1` 的方法集合包含 `r2` 的方法集合（字段方法 + 显式方法），且对应方法签名类型兼容。这个检查利用结构类型的子类型算法完成。

### 2.2 `Case` 提取器验证

对于 `catch` 中的每一个分支 `case Extractor(pattern): body`，类型检查器需要：

1. 确定 `Extractor` 期望解构的效应类型 `Op_target`（即 `Extractor` 作为 `Case` 实现的输入类型）。
2. 检查 `Op_target` 是否与当前 `e.effects` 中的某个效应类型兼容（即存在 `r ∈ e.effects` 使得 `r <: Op_target`）。若不存在，发出“不可达分支”警告。
3. 将 `pattern` 绑定的变量赋予 `Case` 解构后的类型。
4. 对于 `resume(v)` 调用，检查 `v` 的类型是否严格等于 `Op_target` 的 `Effectful::Resume`。

对于 `match` 分支，类似的逻辑仅针对正常类型 `T`，不涉及效应。

### 2.3 `Effectful` trait 合规

当用户为某结构体 `S` 实现 `Effectful` 时，必须提供 `type Resume`。类型检查器将记录此关联，供 `raise` 处查询。对于未实现 `Effectful` 的结构体，默认 `Resume = !`，且 `Case` 实现不受影响（仍然可被 `catch` 捕获，但不可恢复）。

### 2.4 语法糖脱糖

在类型检查前，语法糖在 AST → HIR 阶段被展开：

| 语法             | 展开结果                                      |
|------------------|-----------------------------------------------|
| `yield expr`     | `raise Yielder::Yield { value: expr }`        |
| `yield break`    | `raise Yielder::YieldBreak`                   |
| `yield return e` | `{ raise Yielder::Yield{value:e}; raise Yielder::YieldBreak }` |
| `expr.await`     | `raise Await { future: expr }`                |
| `expr.awake`     | `raise Awake { future: expr }`                |

展开后，这些结构体必须已在标准库或当前作用域中定义且实现相关 trait，类型检查按普通 `raise` 处理。

---

## 3. HIR 表示

HIR 保留效应处理的高级语义，节点定义如下：

```
Expr
  | HirRaise { value: Expr }               // raise e
  | HirMatch { value: Expr, arms: [Arm] }  // match
  | HirCatch { value: Expr, arms: [CatchArm] }  // catch
  | HirTry { capture: [EffectType], body: Expr } // try Result<T, E>
  | ...
```

`CatchArm` 包含：
```
CatchArm {
    extractor: Path,        // 提取器路径
    patterns: [Pattern],    // 绑定变量
    body: Expr,             // 分支体
    has_resume: bool        // 是否包含 resume
}
```

`HirResume(value)` 作为 `CatchArm.body` 内的特殊表达式出现，在 HIR 中保留为独立节点。

`HirTry` 节点带有捕获效应列表，其 `body` 是一个作用域块。

HIR 构建阶段仅做简单翻译，不进行控制流拆分。

---

## 4. MIR 降级

MIR 阶段将高层的效应控制流转换为低级的基本块指令（IKun 指令）。关键节点：

```
IKun
  | IKunRaise { op: Value, resume_type: Type }  // 执行效应操作
  | IKunCatch { body: Block, handlers: [Handler] }  // 效应处理器块
  | IKunResume { value: Value, target: Continuation } // 恢复
  | IKunTry { capture: [EffectType], body: Block, ok_bb, err_bb }
  | ...
```

### 4.1 `HirRaise` → `IKunRaise`

`raise expr` 被翻译为：
1. 计算 `expr` 得到效应操作值 `op`。
2. 生成 `IKunRaise(op, resume_type)`。该指令标记当前控制流暂停，携带操作值和期望恢复类型。

### 4.2 `HirCatch` → `IKunCatch`

`e.catch { arms }` 的翻译步骤：
1. 为 `e` 生成一个基本块，其出口连接到 `IKunCatch` 节点。
2. `IKunCatch` 包含一个 `body` 块（即 `e` 的求值）和一组 `Handler`。
   - `Handler` 包含：匹配的效应类型（提取器对应的行类型）、解构代码、以及分支体。
   - 若分支含有 `resume`，则分支体尾部为 `IKunResume` 并跳转回原 `IKunRaise` 的下一条指令。
   - 若分支无 `resume`，则分支体退出 `catch` 区域，返回统一结果。

**效应栈**：运行时通过效应处理器链查找匹配的 `IKunCatch`。MIR 层不体现栈结构，只标记 `IKunCatch` 作为一个处理点。后续 LIR 或运行时负责注册/注销处理器。

### 4.3 `HirResume` → `IKunResume`

`resume(value)` 翻译为 `IKunResume(value, target_continuation)`。`target_continuation` 指向原始的 `IKunRaise` 之后的位置。该指令将恢复值写入原计算点并跳转。

### 4.4 `HirTry` 降级

```
try Result<T, [E_c]> { body }
```

在 MIR 中展开为一个带有效应捕获的专用块：
1. 为 `body` 生成基本块，所有对 `E_c` 效应类型的 `raise` 点会被特殊标记。
2. 在 `IKunTry` 中，若 `body` 正常结束，则走 `ok_bb`，生成 `Fine(v)`。
3. 若在 `body` 中任何位置 `raise` 了 `E_c` 中的效应，控制流直接跳到 `err_bb`，生成 `Fail(op)`，且不执行后续指令。
4. 非 `E_c` 的效应仍然透传，不进入 `err_bb`。

`IKunTry` 最终转化为带有两个出口的基本块，链接到后续的 `match` 解构。

### 4.5 效应多态处理

对于泛型函数，效应变量 `E` 在 MIR 中仍保留为类型参数。当单态化时，具体的效应集合替换变量，所有 `IKunRaise` 和 `IKunCatch` 得到具体的效应类型信息，便于优化。

---

## 5. LIR 生成与代码生成

LIR 阶段将 MIR 进一步低级化，生成可执行代码或目标机器码。

### 5.1 效应处理器链

每个线程/任务维护一个**效应处理器栈**（类似异常处理器栈）。`IKunCatch` 在进入时注册一个效应处理器到栈顶，包含：
- 处理的效应类型列表（及其 `Case` 解构函数指针）
- 对应的基本块入口（各处理分支）

`IKunRaise` 操作：
1. 从栈顶开始遍历处理器，调用每个处理器的类型匹配函数（基于效应操作值的方法表，进行结构类型检查）。找到第一个能够解构该效应值的处理器。
2. 若找到，创建一个 `Continuation` 对象，保存当前指令指针和栈帧。
3. 跳转到处理器对应的基本块。
4. 若未找到，则程序崩溃（或调用默认兜底处理）。

`IKunResume` 操作：
1. 接收 `Continuation` 对象，恢复其保存的指令指针和栈帧。
2. 将恢复值写入 `IKunRaise` 的结果寄存器。
3. 跳转回原 `IKunRaise` 之后继续执行。

### 5.2 Continuation 实现

单次 continuation 可通过栈拷贝或堆分配实现。对于常见的代数效应使用模式，许多 continuation 是单次的，可以采用**栈快照 + 不可变**的技术：
- 在 `raise` 点记录当前栈顶、栈底和程序计数器。
- `resume` 时，将栈恢复到快照状态（需处理栈中对象的生命周期）。
- 为简化，可默认使用堆分配的保存策略：将当前栈帧和寄存器状态打包为一个堆对象，`resume` 时恢复。

多射 continuation（高级特性）需要复制整个栈帧，代价较高，不作为默认路径。

### 5.3 静态优化

在 MIR 和 LIR 阶段，编译器可对效应流进行静态分析：

- **内联 catch**：若一个 `IKunRaise` 和处理它的 `IKunCatch` 在同一个函数内且没有闭包逃逸，可直接将 `raise` 转换为条件跳转 + 直接调用处理分支，避免运行时栈搜索。这是常见的尾调用优化。
- **效应集合下推**：通过类型信息可以确定某些 `raise` 永远不会被某些 `catch` 捕获，从而提前排除无效处理器。

### 5.4 `try` 块生成

`IKunTry` 在 LIR 中展开为：
- 进入 `try` 块时安装一个特殊的效应处理器，它仅捕获 `E_c` 指定的效应类型。该处理器内部直接跳转到 `err_bb` 并生成 `Fail` 值。
- 其他效应继续向上搜索。
- `body` 正常执行后，卸载该处理器并走 `ok_bb`。

因为 `E_c` 已知，处理器可以直接判定效应类型，高效。

---

## 6. 运行时组件

运行时负责提供：
- 效应处理器栈（每个线程/协程一个）
- Continuation 的创建、恢复和垃圾回收
- 基本异常/兜底处理（未被捕获的效应，转成 panic）

标准库提供 `Effectful` trait 和基础效应结构体（`Yielder`、`Await`、`Awake` 等），以及异步运行时的 `catch` 循环。

---

## 7. 与其他特性的交互

### 7.1 闭包

闭包捕获自由变量时，若自由变量中涉及可抛出效应的环境，则闭包类型会携带相同的效应。闭包调用时，其效应与调用者效应合并。实现上，闭包对象在存储时记录捕获变量的效应集合，MIR 层生成相应 `IKunRaise`。

### 7.2 泛型与效应多态

泛型函数实例化时，效应变量被替换为具体效应集合。编译器生成每个单态化版本的代码，其中的 `IKunCatch` 可以专门针对已知效应类型生成直接匹配代码，获得高性能。

### 7.3 模式匹配完备性

`catch` 分支不需要完备覆盖所有效应，未覆盖效应继续传播。`match` 分支需要对正常类型 `T` 完备，遵循标准模式匹配完备性规则。

---

## 8. 测试与验证

建议为效应系统实现提供以下测试：
- 效应推导正确性（包括多态）
- `catch`/`resume` 控制流正确性（单/多继续）
- `try` 捕获与透传
- 生成器、异步的脱糖和执行
- 效应处理器链的动态查找和 continuation 恢复
- 结构类型下的兼容匹配（不同模块的等效效应操作可被同一 `catch` 处理）

---

本手册提供了从类型检查到运行时支持的完整实现路线，严格遵循设计文档中的对偶原则与结构类型统一性。通过分阶段的降级策略和可选的静态优化，实现既保持了代数效应的灵活性，又能在常见场景下达到零开销。