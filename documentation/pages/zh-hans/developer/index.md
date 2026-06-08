# 参与贡献

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
│   ├── Valkyrie.Interpreter/       # 运行时（ValkyrieRuntime、增量编译、热重载）
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

## 26 个项目的职责

| 项目 | 职责 |
|:---|:---|
| **Asgard** | VOA 全栈框架：编译器、开发服务器、SSG |
| **Asgard.Api** | VOA API 定义和共享契约 |
| **Legion** | 包管理器核心（依赖解析、构建编排、安全审计） |
| **Legion.Registry** | 注册表抽象基类和工厂 |
| **Legion.Registry.Conda** | Conda 注册表适配器 |
| **Legion.Registry.Jsr** | JSR 注册表适配器 |
| **Legion.Registry.Maven** | Maven 注册表适配器 |
| **Legion.Registry.Npm** | NPM 注册表适配器 |
| **Legion.Registry.Nuget** | NuGet 注册表适配器 |
| **Legion.Registry.Valhalla** | Valhalla 注册表适配器 |
| **Valhalla** | 注册表共享核心库 |
| **Valhalla.Client** | 下载、安装、锁文件校验 |
| **Valhalla.Config** | 配置模型 |
| **Valhalla.Server** | HTTP 服务端 |
| **Valkyrie** | 核心工作区服务 |
| **Valkyrie.Compiler** | 新编译主线：HIR→MIR→LIR→多目标 |
| **Valkyrie.Formatter** | 代码格式化 |
| **Valkyrie.Highlight** | 语法高亮 |
| **Valkyrie.Interpreter** | 运行时（ValkyrieRuntime、增量编译、热重载） |
| **Valkyrie.LSP** | 语言服务器协议 |
| **Valkyrie.Linter** | 静态代码检查 |
| **Valkyrie.Tests** | 语言/编译器测试 |
| **Asgard.Tests** | VOA 框架测试 |
| **Legion.Tests** | 包管理器测试 |
| **Valhalla.Tests** | 注册表测试 |

## 构建

```bash
dotnet build
dotnet test
```

## 关键设计文档

- [架构详解](architecture.md)
- [Target Contract Spec](target-contract-spec.md)

## 开发环境

- .NET SDK
- Rider 或 VS Code
- 同级目录需有 Oak.cs、Acorn.cs、NyarVM.cs

## 代码审查清单

- [ ] 遵循 [编码规范](coding-conventions.md)
- [ ] 遵循 [依赖规则](dependency-rules.md)
- [ ] 编写测试覆盖新功能
- [ ] 全部现有测试通过
- [ ] 文档注释完整（中文，XML 文档注释格式）
- [ ] 无 console.log / TODO 残留
