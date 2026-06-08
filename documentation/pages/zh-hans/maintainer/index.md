# Valkyrie 编译器内部原理

## 编译管线（一张图）

```
源码(.v)
  │
  ├─ ① Oak.Valkyrie ──────── 文本解码：Lexer → Parser → AST
  ▼
CompilationUnit (AST)
  │
  ├─ ② MetaStager ────────── 元节点消除、宏展开 → Stage 0 AST
  ▼
Stage 0 AST
  │
  ├─ ③ TypeChecker ───────── 三个 Pass：声明收集 → 声明检查 → 体检查
  ▼                           ← trait 结构推导在此发生
SemanticModel                 ← 方法分派决议在此发生
  │                           ← 类继承展开在此发生
  ├─ ④ HirBuilder ────────── AST + SemanticModel → HIR
  ▼
HIR（已解析符号的高层 IR）
  │
  ├─ ⑤ HirToMirLowerer ───── HIR → EGraph<IKun>
  ▼                           ← ? 在此展开为 match
EGraph<IKun>                  ← .await 在此展开为 perform
  │                           ← 模式匹配在此编译为决策树
  ├─ ⑥ Nyar.Optimizer ────── 方言降级、部分求值、成本模型提取
  ▼
IKunTree（最优程序）
  │
  ├─ ⑦ IkunTreeToLirLowerer ─ IKunTree → GenerateModule
  ▼                           ← 协程状态机在此生成
GenerateModule（Nyar Standard IR）
  │
  ├─ ⑧ Backend ───────────── 代码生成：LIR → 目标平台数据结构
  │   ├─ NyarVM  → .nyar
  │   ├─ WASM    → .wasm
  │   ├─ JVM     → .class
  │   ├─ CLR     → .dll/.exe
  │   └─ Native  → .elf/.exe/.dylib
  │
  ├─ ⑨ Acorn ─────────────── 二进制编码 → byte[]
  │
  ├─ ⑩ Packaging ─────────── 入口包装、sidecar 资产
  ▼
ArtifactSet（可执行产物）
```

> **核心约束**：①②③④⑤⑥⑦是语义主线，所有 target 共享。分叉从⑧开始。

## 从哪开始读

### 路径 A：理解编译器全貌（推荐新手）

按数字顺序读：

1. [compilation.md](compilation.md) — 逐阶段详解，每阶段回答"输入是什么、输出是什么、做了什么"
2. [meta-stager.md](meta-stager.md) — 多阶段编程，宏展开机制
3. [type-checker.md](type-checker.md) — 类型检查三 Pass
4. [trait-resolution.md](trait-resolution.md) — trait 结构推导算法
5. [hir-types.md](hir-types.md) — HIR 类型系统
6. [lir-lowering.md](lir-lowering.md) — LIR 降级与代码生成
7. [multi-file.md](multi-file.md) — 多文件编译
8. [backends/](backends/) — 五大后端

### 路径 B：理解某个语言特性如何编译

直接从特性跳入，每个文档都标注了在管线中的位置：

| 想了解 | 看这个 |
|:---|:---|
| trait 如何自动推导 | [trait-resolution.md](trait-resolution.md) |
| `receiver.method()` 如何分派 | [method-dispatch.md](method-dispatch.md) |
| class 继承如何展开 | [class-inheritance.md](class-inheritance.md) |
| `match` 如何编译为跳转 | [pattern-lowering.md](pattern-lowering.md) |
| `?` / `catch` / `resume` 如何降级 | [effect-compilation.md](effect-compilation.md) |
| `.await` / `.awake` / `.block` 如何变成状态机 | [async-compilation.md](async-compilation.md) |
| AWSL 模板如何变成 GGScript IR | [awsl-ir.md](awsl-ir.md) |

### 路径 C：开发新后端

从 [backends/index.md](backends/index.md) 开始，其中描述了后端的统一入口接口和职责边界。然后挑一个已有后端作为参考实现。

## 分层约束

| 层级 | 做什么 | 不做什么 |
|:---|:---|:---|
| HIR | 语言语义：符号、类型、入口 | ABI、宿主入口、文件格式 |
| MIR | 等价变换、部分求值、优化 | target 特定 imports |
| LIR | 调用约定、控制流、codegen 结构 | .wasm/.class/.dll 编码、sidecar |
| Backend | 指令翻译、内存布局、GC | 语义分析、优化、二进制编码 |

## 项目结构

```
Valkyrie.cs/projects/
├── Valkyrie/               CLI 入口
├── Valkyrie.Runtime/       管线编排、AST→IKun 转换
├── Valkyrie.TypeChecker/   类型检查器
├── VoaCore/                核心库
├── VoaRouter/              文件路由
├── VoaEffect/              Effect 系统
├── VoaApi/                 API Routes
├── VoaAuth/                认证
├── VoaI18n/                国际化
├── VoaAnalytics/           埋点
├── VoaSeo/                 SEO
├── Valkyrie.ToolChains/    CLI / DevServer / Compiler / PWA
└── Asgard.Tests/           测试套件
```