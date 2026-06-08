# 项目介绍

Valkyrie 是 Nyar 组织的语言前端与工具链项目，为 Gnosis 元游戏引擎提供编译、运行、包管理和全栈 Web 开发能力。

## 四个核心产品

| 产品 | 职责 | 一句话 |
|:---|:---|:---|
| **Valkyrie 语言** | 领域特定语言 | ECS 原生语言，`component`/`system`/`widget` 是一等公民 |
| **VCC** | 编译与运行 | 源码 → `HIR/MIR/LIR` → 多目标产物 → 运行 |
| **Legion** | 包管理器 | 多注册表依赖管理、安全审计、脚本执行 |
| **VOA** | 全栈 Web 框架 | 约定优于配置，前后端统一语言，Island 架构 |
| **Valhalla** | 自建注册表 | Ed25519 身份认证，二进制不可变存储 |

## 在 Nyar 生态中的定位

Valkyrie 是语言前端和管线编排层，依赖 Nyar 组织的三大基础设施：

| 基础设施 | 职责 | Valkyrie 如何使用 |
|:---|:---|:---|
| **Oak** | 一切文本编解码 | Oak.Valkyrie 提供 Lexer + Parser，解析 `.v` 源码为 AST |
| **Acorn** | 一切二进制编解码 | Acorn.Nyar 编码 `.nyar` 字节码；Acorn.Wasm 编码 `.wasm` |
| **Nyar** | 一切分析与优化 | EGraph 饱和优化、IKun IR、多后端代码生成、NyarVM 运行时 |

## 编译管线全景

```
源码 .v
  │
  ↓  Oak.Valkyrie：文本解码
  │  Lexer.Tokenize() → Parser.Parse()
  │
  AST（Oak.Valkyrie AST）
  │
  ↓  Valkyrie.Interpreter：语义分析 + 运行
  │  ValkyrieRuntime → 编译/分析/执行
  │
  ↓  Valkyrie.Compiler：统一编译主线
  │  HIR -> MIR(EGraph) -> Extract -> LIR(Nyar Standard IR)
  │
  ↓  Nyar / Acorn：多目标生成与编码
  │  ├─ NyarVM Backend  →  NyarModuleData   →  Acorn.Nyar  →  .nyar
  │  ├─ WASM Backend    →  WasmModuleData   →  Acorn.Wasm  →  .wasm
  │  ├─ JVM Backend     →  JvmClassFileData →  Acorn.Jvm   →  .class
  │  ├─ CLR Backend     →  ClrModuleData    →  Acorn.Clr   →  .dll
  │  └─ Native Backend  →  Native Data      →  Acorn.Elf/Pe/MachO
  │
  ↓  Valkyrie.Compiler.Packaging
  │  ArtifactSet + Host Contract
  │
```

## 项目结构

```
Valkyrie.cs/
├── projects/
│   ├── Asgard/                     # VOA 全栈框架（编译器、开发服务器、SSG）
│   ├── Asgard.Api/                 # VOA API 定义
│   ├── Legion/                     # 包管理器核心
│   ├── Legion.Registry/            # 注册表抽象基类
│   ├── Legion.Registry.Conda/      # Conda 注册表适配器
│   ├── Legion.Registry.Jsr/        # JSR 注册表适配器
│   ├── Legion.Registry.Maven/      # Maven 注册表适配器
│   ├── Legion.Registry.Npm/        # NPM 注册表适配器
│   ├── Legion.Registry.Nuget/      # NuGet 注册表适配器
│   ├── Legion.Registry.Valhalla/   # Valhalla 注册表适配器
│   ├── Valhalla/                   # 注册表共享核心
│   ├── Valhalla.Client/            # 注册表客户端
│   ├── Valhalla.Config/            # 注册表配置
│   ├── Valhalla.Server/            # 注册表服务端
│   ├── Valkyrie/                   # 核心工作区服务
│   ├── Valkyrie.Compiler/          # 编译主线：HIR→MIR→LIR→多目标
│   ├── Valkyrie.Formatter/         # 代码格式化
│   ├── Valkyrie.Highlight/         # 语法高亮
│   ├── Valkyrie.Interpreter/       # 运行时（ValkyrieRuntime、热重载）
│   ├── Valkyrie.LSP/               # 语言服务器协议
│   ├── Valkyrie.Linter/            # 静态代码检查
│   ├── Valkyrie.Tests/             # 语言/编译器测试
│   ├── Asgard.Tests/               # VOA 测试
│   ├── Legion.Tests/               # 包管理测试
│   └── Valhalla.Tests/             # 注册表测试
├── tools/
│   ├── vcc/                        # VCC CLI（编译与运行）
│   ├── legion/                      # Legion CLI（包管理命令）
│   └── asgard/                      # Asgard CLI（VOA 构建/开发服务器）
├── examples/
│   └── runtime/
│       └── voa-runtime.js          # VOA 前端运行时
├── documentation/                  # 本文档
└── Valkyrie.slnx
```

## 设计哲学

### 编译器独立设计

VCC 是一个独立的编译器工具，不依赖任何包管理器。它直接使用 `vendors` 目录中的依赖进行编译。Legion 作为包管理器调用 VCC 作为编译后端，两者职责严格分离。

### ECS 原生语言

`component`、`system`、`widget`、`plugin` 是一等公民语法，不需要继承基类或实现接口：

| 传统语言 | Valkyrie |
|:---|:---|
| `class Position : IComponent` | `component Position { x: f32; y: f32 }` |
| `class MovementSystem : SystemBase` | `system MovementSystem { ... }` |
| `world.Query<Position, Velocity>()` | `query all = Query.all(Position, Velocity)` |

### 前端复用，不自建解析器

Valkyrie 不自建 Lexer/Parser/优化器，全部消费 Oak、Nyar、Acorn 的能力。

### 双版本号体系

| 版本类型 | 格式 | 用途 |
|:---|:---|:---|
| **SemanticVersion** | `major.minor.patch` | 程序化版本比较 |
| **YearlyVersion** | `yearly.major.minor.patch` | 面向人类可读版本号 |

YearlyVersion 消除预发布标记歧义：`yearly=0` 预研版，`major=0` 测试版，`major>0` 稳定版。
