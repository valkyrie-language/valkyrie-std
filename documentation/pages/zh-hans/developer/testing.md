# 测试指南

## 测试分层

```
┌──────────────────────────────────┐
│         E2E 端到端测试            │  ← 真实项目编译运行
├──────────────────────────────────┤
│     集成测试（多模块交互）         │  ← TypeChecker + Converter
├──────────────────────────────────┤
│        单元测试（单个模块）         │  ← Lexer / Parser / Scope
└──────────────────────────────────┘
```

## Valkyrie 项目测试

Valkyrie 项目（`.v` 源码）使用 `legion test` 命令进行测试，测试代码放在项目的 `test/` 目录中。

### 测试目录约定

每个项目 SHALL 支持 `test/` 目录，其中的 `.v` 文件为测试源码：

```
my-project/
├── legion.von
├── source/
│   └── main.v          # 实现代码
└── test/
    ├── simple_test.v   # 测试文件
    └── bench_test.v    # 基准文件
```

### 测试标注

测试函数通过 `[test]` attribute 或 `test` modifier 标注，二者等价：

```v
# attribute 形式
[test]
micro easy_if_1() -> unit {
    let max = if a > b { a } else { b }
}

# modifier 形式（与 attribute 完全等价）
test micro easy_if_2() -> unit {
    let max = if a > b { a } else { b }
}
```

### 基准标注

`[benchmark]` attribute 标注的函数为基准测试用例，被 `legion bench` 识别：

```v
[benchmark]
micro easy_if_3() -> unit {
    # 基准测试逻辑
}
```

### 测试块

`tests` 声明用于复杂测试场景，内部环境等同于 class body：

```v
tests `test block` {
    field: Typing = default
    method() -> unit { }
    domain {
        field
        method()
    }
}
```

### 编译宏变量

编译时注入两个只读宏变量，可在测试代码中通过 `@build_type` / `@build_mode` 读取：

| 变量 | 取值 | 说明 |
|:---|:---|:---|
| `@build_type` | `"build"` / `"test"` / `"benchmark"` / `"coverage"` | 当前编译类型 |
| `@build_mode` | `"development"` / `"production"` | 当前构建模式 |

### 测试专用依赖

`legion.von` 的 `dependencies` 中支持 `test: true` 标志，声明该依赖仅在 `legion test` / `legion bench` / `legion coverage` 模式下可见：

```von
dependencies: {
    "some_name": {
        version: true,
        test: true,
    }
}
```

### 运行测试

```bash
# 默认在 NyarVM 中执行测试
legion test

# 指定项目
legion test examples/test.if_expression

# 过滤测试名
legion test --filter easy_if

# 多 target 测试
legion test --target nyar --target clr
legion test --target all                # 展开为 nyar, clr, jvm, node

# 多 target 逗号分割
legion test --target nyar,clr,jvm

# 详细输出
legion test --verbose
```

### 多 Target 测试

`legion test` 支持 `--target` 参数指定执行目标，对每个 target 编译产物后通过对应 Runner 执行：

| Target | Runner | 说明 |
|:---|:---|:---|
| `nyar` | NyarVmRunner | 进程内加载字节码（无外部依赖） |
| `clr` | ClrRunner | 通过 `dotnet exec` 执行 .NET 程序集 |
| `jvm` | JvmRunner | 通过 `java -cp` 执行 JVM 类文件 |
| `node` | NodeRunner | 通过 `node` 执行 WASM 产物 |

每个 target 的编译产物输出到 `.cache/test/<target>/` 独立目录，与最终部署产物 `dist/` 隔离。

不可用的 target（如未安装对应运行时）会被自动跳过并输出警告。

### 外部 Runner 配置

Runner 的命令路径可通过以下方式配置，优先级由高到低：

1. 命令行参数 `--runner clr=C:\custom\dotnet.exe`
2. `legion.von` 的 `[runner]` 段
3. 环境变量 `LEGION_RUNNER_CLR`（大写 target 名）
4. PATH 自动检测

`legion.von` 的 `[runner]` 段示例：

```von
[runner]
{target: "clr", command: "dotnet", args: ["exec", "{artifact}"]}
{target: "jvm", command: "java", args: ["-cp", "{classpath}", "{entry}"]}
{target: "node", command: "C:\\Program Files\\nodejs\\node.exe", args: ["{artifact}"]}
```

### 运行基准测试

```bash
# 默认运行 3 次
legion bench

# 指定运行次数
legion bench --runs 10

# 指定 target
legion bench --target nyar --target clr

# 详细输出
legion bench --verbose
```

### 运行覆盖率检查

```bash
# 检查语法特性覆盖
legion coverage
# 别名
legion cov
```

## .NET C# 测试项目

### 核心测试项目

### Valkyrie.Tests

| 测试集 | 内容 |
|:---|:---|
| `LexerTests` | 词法分析单元测试 |
| `ParserTests` | 语法分析 + FFI 属性测试 |
| `TypeCheckerTests` | 类型检查单元测试 |
| `FormatterTests` | 格式化集成测试 |
| `PackageManagerTests` | Legion 单元测试 |
| `E2ETests` | Native 目标端到端测试 |

### Asgard.Tests

| 测试集 | 内容 |
|:---|:---|
| `AwslReactiveCompilerTests` | AWSL 编译到 JS 的响应式编译 |
| `AwslSsrRendererTests` | AWSL 服务端渲染 |
| `ModuleDceTests` | 死代码消除 |
| `PwaGeneratorTests` | PWA Service Worker 生成 |
| `VoaCompilerTests` | VOA 完整编译流程 |

### Legion.Tests

| 测试集 | 内容 |
|:---|:---|
| `CondaRegistryTests` | Conda 适配器测试 |
| `CredentialProviderTests` | 凭据自动发现 |
| `JsrRegistryTests` | JSR 适配器测试 |
| `MavenRegistryTests` | Maven 适配器测试 |
| `NpmRegistryTests` | NPM 适配器测试 |
| `NuGetRegistryTests` | NuGet 适配器测试 |
| `PackageCacheTests` | 缓存功能测试 |
| `RegistrySourceManagerTests` | 注册表源管理 |
| `VendorAuthStoreTests` | 认证令牌存储 |
| `VendorManagerTests` | Vendor 管理 |

### Valhalla.Tests

| 测试集 | 内容 |
|:---|:---|
| `Ed25519AuthMiddlewareTests` | Ed25519 认证中间件 |
| `PackageNameTests` | 包名解析与验证 |
| `ValhallaClientTests` | 客户端功能 |
| `ValhallaConfigTests` | 配置加载 |
| `ValhallaDigestTests` | SHA-256 承诺文件 |
| `ValhallaE2ETests` | 端到端（发布→验证→下载） |
| `ValhallaIncarnationTests` | 化身计数器 |
| `ValhallaInstallerTests` | 安装器功能 |
| `ValhallaLockFileTests` | protoswap.lock 生成与校验 |
| `ValhallaLockFileValidationTests` | 锁文件安全校验 |

## 运行 .NET 测试

```bash
# 全部测试
dotnet test

# 指定项目
dotnet test projects/Valkyrie.Tests/
dotnet test projects/Asgard.Tests/
dotnet test projects/Legion.Tests/
dotnet test projects/Valhalla.Tests/

# 并行运行
dotnet test --parallel
```

## 编写 .NET 测试

- 测试文件放在对应 `Tests` 目录
- 测试方法命名：`{方法名}_{场景}_{预期}`
- 使用 `[Fact]` 和 `[Theory]` 属性
- Arrange → Act → Assert 三段式
