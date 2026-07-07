# `std.adaptor.jvm`

Valkyrie JVM 平台 SDK — 提供 Java 运行时 API 绑定，编译为 JVM 字节码（`.class`）。
## 📋 目标三元组
| 目标三元组                | 架构 | 供应商 | OS      | ABI  | 说明                            |
|:---------------------------|:-----|:--------|:--------|:-----|:--------------------------------|
| `jvm-unknown-linux-gnu`    | jvm  | unknown | linux   | gnu  | Linux x64 JVM（OpenJDK/Oracle）|
| `jvm-unknown-darwin`       | jvm  | unknown | darwin  | —   | macOS JVM                       |
| `jvm-unknown-windows-msvc` | jvm  | unknown | windows | msvc | Windows JVM                     |
| `jvm-unknown-android`      | jvm  | unknown | android | —   | Android Dalvik/ART              |

> **三元组格式**：`<arch>-<implementation>-<specification>-<abi>`（遵循 LLVM/Rust 标准）
> JVM 是跨平台运行时，同一字节码可在所有平台运行，三元组主要影响 JNI 调用约定。
> JVM 目标的三元组中 `arch` 固定为 `jvm`，因为 JVM 字节码与物理架构无关。
### 映射到 Nyar CompilationTarget

| 三元组                    | Arch | ABI | API  | OS      | Environment |
|:---------------------------|:-----|:----|:-----|:--------|:------------|
| `jvm-unknown-linux-gnu`    | Jvm  | JVM | Java | Linux   | Native      |
| `jvm-unknown-darwin`       | Jvm  | JVM | Java | macOS   | Native      |
| `jvm-unknown-windows-msvc` | Jvm  | JVM | Java | Windows | Native      |

### 与其他目标的区别

| 特性       | CLR             | JVM                       | WASI         |
|:------------|:----------------|:--------------------------|:-------------|
| 📦 输出格式 | `.dll` / `.exe` | `.class`                  | `.wasm`      |
| 🏃 运行时  | .NET Runtime    | JVM (OpenJDK)             | Wasmtime     |
| 📁 文件系统 | ✅ `System.IO`  | ✅ `java.io` / `java.nio` | ✅ WASI fd   |
| 🌐 网络     | ✅ `System.Net` | ✅ `java.net`             | ✅ WASI sock |
| 🔍 反射     | ✅             | ✅                       | ❌          |
| 🎯 互操作  | P/Invoke        | JNI                       | WASI imports |
| 🧵 多线程  | ✅             | ✅                       | ❌          |
| 📚 标准库  | BCL             | JDK                       | WASI minimal |

## 📦 包内容
```
std.adaptor.jvm/
├── legion.von              # 包清单
├── README.md               # 本文件
└── source/
    ├── console/_.v         # 控制台（对齐 std.console）
    ├── io/{fs,time}.v      # 文件系统/时间（对齐 std.io）
    ├── net/http.v          # HTTP（对齐 std.net）
    ├── math/basic.v        # 数学（对齐 std.math）
    ├── math/random/Random.v
    ├── text/Utf{8,16}Text.v
    ├── collection/…
    ├── system.v
    └── thread.v
```

## 🔧 绑定概念

### `[jvm("fully.qualified.Class", "methodName")]` 属性
Java 方法通过 `[jvm]` 属性声明，编译时映射为 JVM 常量池方法引用（Methodref）：

```v
[jvm("java.lang.System", "out.println")]
micro jvm_println(value: string): void

[jvm("java.lang.Math", "abs")]
micro jvm_math_abs(value: f64): f64

[jvm("java.io.File", "exists")]
micro jvm_file_exists(path: string): bool
```

### 文件说明

| 文件                   | 绑定类型 | 副作用   | 覆盖 API       |
|:-----------------------|:---------|:----------|:---------------|
| `console/_.v`          | `[jvm]`  | ✅ 有    | 控制台输入输出 |
| `io/fs.v`              | `[jvm]`  | ✅ 有    | 文件/目录操作  |
| `net/http.v`           | `[jvm]`  | ✅ 有    | HTTP 请求      |
| `math/basic.v`         | `[jvm]`  | ❌ 纯函数 | 数学函数       |
| `math/random/Random.v` | `[jvm]`  | ✅ 有    | 随机数         |
| `text/Utf16Text.v`     | `[jvm]`  | ❌ 纯函数 | UTF-16 code unit |
| `text/Utf8Text.v`      | `[jvm]`  | ❌ 纯函数 | UTF-8 标量（codePointCount） |
| `thread.v`             | `[jvm]`  | ✅ 有    | 线程操作       |

## 🎯 使用场景

- 🎯 服务端 Java 应用（Spring Boot 后端逻辑）
- 📱 Android 游戏脚本
- 🔧 大数据处理（Hadoop/Spark UDF）
- 🎮 Minecraft 插件（Bukkit/Spigot）
## ⚙️ 编译命令

```bash
# 编译为 JVM 字节码
vcc build --target jvm

# 运行产出
java Module
```

## 📌 状态
🚧 占坑阶段，JDK API 绑定待实现完整覆盖。
⚙️ JvmBackend 的 `EmitCallFromInstruction` 写入 methodref 索引为 0（占位符），跨函数调用尚未实现常量池解析。
⚙️ JvmBackend 的 `EmitJumpFromInstruction` 写入跳转偏移为 0（占位符），分支偏移尚未计算。
⚙️ Acorn.Jvm.Decode 的属性解码为 stub（始终返回 null），无法完成 round-trip。
