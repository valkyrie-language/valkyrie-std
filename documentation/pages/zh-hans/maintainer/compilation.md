# 编译管线逐阶段详解

本文按管线顺序逐阶段展开。每个阶段回答三个问题：**输入是什么、输出是什么、做了什么**。你可以从头读到尾理解全貌，也可以跳到任一阶段查看细节。

---

## 阶段 ①：Oak.Valkyrie — 文本解码

| | |
|:---|:---|
| **位置** | 管线最前端 |
| **输入** | 源码字符串（`.v` 文件） |
| **输出** | `CompilationUnit`（AST 根节点） |

### 做了什么

- **Lexer** 将字符流切分为 token 流
- **Parser** 将 token 流解析为 AST 树
- 每个 AST 节点保留 `TextSpan`（行列号），供后续阶段生成诊断
- 不做任何语义分析——此阶段完全不关心标识符是否是类型名、函数名还是变量名

### 语言特性在此阶段的处理

无。纯语法解析，不涉及语义。

> 详见 Oak.Valkyrie 项目（外部依赖，`Valkyrie.cs` 通过 NuGet 引用）。

---

## 阶段 ②：MetaStager — 多阶段编程变换

| | |
|:---|:---|
| **位置** | Parse 之后、Analyze 之前 |
| **输入** | AST（可能包含 `<% %>` 元节点） |
| **输出** | 纯 Stage 0 AST（所有元节点已消除） |

### 做了什么

- 递归遍历 AST，识别 `<% %>` 元节点
- 编译期求值：`<% match target.spec %>` 根据 `CanonicalTriple` 选择代码分支
- 宏展开：`@macro_name(args)` 从 `MacroRegistry` 查找宏定义并展开
- 循环展开：`<% loop field in node.fields %>` 生成重复代码
- 元代码块逃逸：`<% expr %>` 将编译期求值结果插入为 AST 片段
- 重复消除直到 AST 中不再包含任何元节点（最大深度 64）

### 语言特性在此阶段的处理

| 特性 | 处理方式 |
|:---|:---|
| `macro` 定义 | 提取到 `MacroRegistry`，不展开自身 |
| `@macro` 调用 | 展开宏体，替换调用点 |
| `[derive(Trait)]` | 触发生成 `imply` 块 |
| `<% if / match / loop %>` | 编译期求值并替换 |

> 详见 [meta-stager.md](meta-stager.md)。

---

## 阶段 ③：TypeChecker — 类型检查

| | |
|:---|:---|
| **位置** | MetaStager 之后、HirBuilder 之前 |
| **输入** | Stage 0 AST |
| **输出** | `SemanticModel`（含符号表、类型绑定、trait 满足关系、witness table、诊断） |

### 做了什么

三个 Pass 顺序执行：

**Pass 1 — 声明收集**：遍历 AST 收集所有顶层声明（类型、函数、命名空间、导入），构建初始符号表。不检查函数体。

**Pass 2 — 声明检查**：验证声明的合法性。同时执行以下语言特性的编译期处理：

| 特性 | 在此阶段的处理 |
|:---|:---|
| **trait 结构推导** | 对每个 `类型 × trait` 对，检查方法签名是否覆盖 → 推断关联类型 → 验证关联类型约束 → 建立满足关系 → 生成 witness table 条目 |
| **类继承展开** | `class Dog(Animal)` → `class Dog { animal: Animal; ... }`，PascalCase 类型名自动转 snake_case 字段名，计算 MRO 序列 |
| 泛型约束验证 | 验证 `where T: Trait` 约束是否自洽 |
| 循环依赖检测 | 循环继承、循环 trait 依赖 |

**Pass 3 — 体检查**：逐函数检查函数体。同时执行：

| 特性 | 在此阶段的处理 |
|:---|:---|
| **方法分派决议** | 遇到 `receiver.method(args)` → 按 class 自有 > trait > 独立 micro 三级查找 → 编码为 `HirDispatchKind`（Static / Witness / Dynamic） |
| **? 操作符验证** | 验证接收者类型是 `Result<T, E>`，验证错误类型 `E` 能传播到当前函数的返回错误类型 |
| **效应签名验证** | 验证函数声明的效应签名与实际传播的效应一致 |
| **`.block` 上下文检查** | `system` 的 `on_update` 等回调中禁止 `.block`，产生编译错误 |

### 输出 SemanticModel 包含

- 完整符号表（所有作用域绑定）
- 每个表达式节点的推断类型
- trait 满足关系表（哪类满足哪 trait）
- witness table 条目集合
- 方法分派决议结果
- 诊断列表

> 详见 [type-checker.md](type-checker.md)、[trait-resolution.md](trait-resolution.md)、[method-dispatch.md](method-dispatch.md)、[class-inheritance.md](class-inheritance.md)。

---

## 阶段 ④：HirBuilder — HIR 构建

| | |
|:---|:---|
| **位置** | TypeChecker 之后、MIR 降级之前 |
| **输入** | AST + SemanticModel |
| **输出** | HIR（已解析符号的高层中间表示） |

### 做了什么

- 将 AST 节点一对一或一对多转换为 HIR 节点
- 变量引用 → 绑定到符号表中的具体 Symbol（含类型信息）
- 方法调用 → 编码为 `HirCall`，携带 TypeChecker 阶段已决议的 `HirDispatchKind`
- 各语言特性的语义节点保留在高层的 HIR 形式：

| AST 语法 | HIR 节点 | 说明 |
|:---|:---|:---|
| `?` | `HirTryOperator` | 保留语义，不在此展开 |
| `catch/resume` | `HirCatchNode` | 保留语义 |
| `.await` | `HirAwaitNode` | 保留语义 |
| `.awake` | `HirAwakeNode` | 保留语义 |
| `.block` | `HirBlockNode` | 保留语义 |
| `match` | `HirMatchNode` | 保留模式结构 |
| `dyn Trait` | `HirDynamicDispatch` | 标记为动态分派 |

### HIR 不做什么

- 不做布局决策（字段偏移、内存大小）
- 不做 ABI 决策
- 不编码文件格式信息

> 详见 [hir-types.md](hir-types.md)。

---

## 阶段 ⑤：HirToMirLowerer — MIR 降级

| | |
|:---|:---|
| **位置** | HIR 之后、优化之前 |
| **输入** | HIR |
| **输出** | `EGraph<IKun>`（以 IKun 判别联合为节点的等价图） |

### 做了什么

将高级语义节点展开为以 `IKun` 为原子操作的低级表示。这是大多数语言特性的 **实际展开发生地**：

| 特性 | 变换 |
|:---|:---|
| **`?` 操作符** | `HirTryOperator` → 展开为 `match { Ok(v) => v, Err(e) => return Err(From(e)) }` |
| **`catch/resume`** | `HirCatchNode` → `IKunCatch`，`resume` → `IKunResume`，效应标识标记在 IKun 节点上 |
| **`.await`** | `HirAwaitNode` → 展开为 `perform AsyncWait(future)`，注入协程挂起点标记 |
| **`.awake`** | `HirAwakeNode` → 展开为 `perform AsyncSpawn(future)` |
| **`.block`** | `HirBlockNode` → 展开为 `perform AsyncBlock(future)` |
| **模式匹配** | `HirMatchNode` → 穷尽性检查 → 决策树编译 → `IKunMatch` / `IKunMatchCase` / `IKunJumpTable` |
| **语法糖** | 各种语法糖在此全部消除为基本 IKun 操作 |

### EGraph 的意义

不直接生成线性的 IKun 序列，而是生成 EGraph（等价图）。EGraph 中的每个 e-class 可以包含多个等价节点，为后续优化提供可能性空间。例如 `a + 0` 的 e-class 中同时包含 `Add(a, 0)` 和 `a` 两个等价表示。

> 详见 [pattern-lowering.md](pattern-lowering.md)、[effect-compilation.md](effect-compilation.md)、[async-compilation.md](async-compilation.md)。

---

## 阶段 ⑥：Nyar.Optimizer — 优化与提取

| | |
|:---|:---|
| **位置** | MIR 之后、LIR 之前 |
| **输入** | `EGraph<IKun>` |
| **输出** | `IKunTree`（从等价图中提取的最优程序） |

### 做了什么

- **方言降级**：将领域特定 IKun 节点（如 `IKunShader`、`IKunWeb`）降级为通用节点
- **等价饱和**：应用重写规则，为每个 e-class 填充更多等价节点
- **部分求值**：编译期可求值的表达式被折叠为常量
- **成本模型提取**：`Extractor` 按 `ICostModel` 从每个 e-class 中选择成本最低的节点，串成线性 `IKunTree`

> 详见 Nyar.Optimizer 项目（外部依赖，`Valkyrie.cs` 通过 NuGet 引用）。

---

## 阶段 ⑦：IkunTreeToLirLowerer — LIR 降级

| | |
|:---|:---|
| **位置** | 优化之后、Backend 之前 |
| **输入** | `IKunTree`（线性最优程序） |
| **输出** | `GenerateModule`（Nyar Standard IR） |

### 做了什么

- **指令翻译**：IKun 节点 → `GenerateInstruction` + `GenerateOperand`
- **类型映射**：HIR 类型名 → `GenerateValueType`（`i32 → I32`、`class → ExternRef` 等）
- **调用分派生成**：

| HirDispatchKind | LIR 产物 |
|:---|:---|
| `Static` | `CallStatic "fully.qualified.name"` |
| `Witness` | `CallWitness slotIndex` + witness table 条目注入模块 |
| `Dynamic` | `CallDynamic slotIndex`（通过 TypeInfo 间接调用） |

- **witness table 编码**：将 TypeChecker 阶段生成的 witness table 条目注入 `GenerateModule` 元数据段
- **协程状态机生成**（async 特性在此最终落地）：

| 步骤 | 内容 |
|:---|:---|
| 1. 识别挂起点 | 扫描函数体中的 `IKunCatch(AsyncWait)` 节点 |
| 2. 拆分基本块 | 在每个挂起点处切断基本块 |
| 3. 生成状态枚举 | 每个挂起点一个状态值 |
| 4. 提升局部变量 | 跨挂起点存活的局部变量提升到 `F_Frame` 结构体 |
| 5. 控制流重构 | 生成 `loop + match state { Start → ... → AfterAwait1 → ... → Done }` |

- **GC 位图**：从类型信息提取 `GcPointerFieldIndices`，编码到 `LirTypeDef` 中

### LIR 不做什么

- 不做 ABI 决策（对象布局、调用约定由各后端决定）
- 不编码二进制格式（`.wasm` / `.class` / `.dll` 编码由 Acorn 完成）
- 不做宿主入口包装

> 详见 [lir-lowering.md](lir-lowering.md)、[async-compilation.md](async-compilation.md)。

---

## 阶段 ⑧：Backend — 代码生成

| | |
|:---|:---|
| **位置** | LIR 之后、二进制编码之前 |
| **输入** | `GenerateModule` |
| **输出** | 目标平台数据结构（`NyarModuleData` / `WasmModuleData` / `JvmClassFileData` / `ClrModuleData` 等） |

### 做了什么

各后端独立完成：

- **指令翻译**：`GenerateInstruction` → 目标平台指令（NyarVM opcode / WASM opcode / JVM bytecode / CIL / 原生机器码）
- **对象布局**：字段偏移计算、对齐、内存分配策略
- **调用约定适配**：`CallStatic → call / invokestatic / ...`
- **GC 策略**：NyarVM 用内置 GC，JVM/CLR 用平台 GC，WASM 依赖宿主 GC，Native 用 Boehm 或精确 GC
- **Witness Table 落地**：NyarVM → 函数指针表，JVM → `invokeinterface`，CLR → `callvirt`，WASM → 函数表 + `call_indirect`

| 后端 | 输出格式 | 编码器 | 文档 |
|:---|:---|:---|:---|
| NyarVM | .nyar | Acorn.Nyar | [nyar-vm.md](backends/nyar-vm.md) |
| WASM | .wasm | Acorn.Wasm | [wasm.md](backends/wasm.md) |
| JVM | .class | Acorn.Jvm | [jvm.md](backends/jvm.md) |
| CLR | .dll / .exe | Acorn.Clr | [clr.md](backends/clr.md) |
| Native | .elf / .exe / .dylib | Acorn.Elf / Pe / MachO | [native.md](backends/native.md) |

> 详见 [backends/index.md](backends/index.md)。

---

## 阶段 ⑨：Acorn — 二进制编码

| | |
|:---|:---|
| **位置** | Backend 之后、Packaging 之前 |
| **输入** | 目标平台数据结构 |
| **输出** | `byte[]` |

### 做了什么

将 Backend 生成的数据结构序列化为标准二进制格式。每个格式有唯一的 Acorn 模块负责。Valkyrie 编译器本身不涉及二进制编码的实现。

> 详见 Acorn.cs 项目（外部依赖）。

---

## 阶段 ⑩：Packaging — 入口包装与交付

| | |
|:---|:---|
| **位置** | 管线最末端 |
| **输入** | 主产物字节码 + 元数据 |
| **输出** | `ArtifactSet` |

### 做了什么

- 生成物理入口点（`_start`、`main` 等）
- 注入 imports 契约
- 打包 sidecar 资产（JS glue、manifest、CSS 等）
- 生成调试信息

---

## 多文件编译

上述管线描述的是单文件编译。多文件场景增加两个全局 Pass：

1. **声明收集**（所有文件）：在所有文件 AST 上收集类型、函数、trait 声明，构建全局声明表
2. **拓扑排序**：按 `using` 依赖关系排序文件 → **体分析**（逐文件执行 Pass 3）

trait 推导、witness table 条目、方法分派决议在多文件场景中基于全局声明表执行。

> 详见 [multi-file.md](multi-file.md)。

---

## 增量编译

编译器通过文件指纹（内容哈希）追踪变更。`DependencyGraph` 维护模块依赖关系，脏标记沿依赖边传播。只重编译受影响的模块及其下游依赖。