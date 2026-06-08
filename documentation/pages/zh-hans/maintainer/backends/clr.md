# CLR 后端

## 概述

CLR 后端将 `GenerateModule` 翻译为 .NET CIL（Common Intermediate Language），输出 `.dll` 或 `.exe` 程序集。利用 CLR 的类型系统和 GC。

## 管线

```
GenerateModule
  │
  ├── CLR Backend
  │     ├── 指令翻译：GenerateInstruction → CIL 指令
  │     ├── 对象布局：利用 CLR 类型系统
  │     └── GC 策略：利用 CLR GC
  │
  ▼
ClrModuleData (使用 Acorn.Clr.Data)
  │
  ├── Acorn.Clr.Encode
  │
  ▼
.dll / .exe (二进制程序集)
```

## 类型映射

| Valkyrie 类型 | CLR 映射 |
|:---|:---|
| `class` | .NET class |
| `structure` | .NET readonly struct |
| `enums` / `flags` | .NET enum |
| `union` / `unite` | 抽象基类 + 嵌套子类 |
| `trait` | .NET interface |
| 原始类型 | .NET 原始类型（`Int32`、`Double` 等） |

## 指令映射

| GenerateInstruction | CIL 对应 |
|:---|:---|
| 算术/逻辑运算 | CIL 算术/逻辑指令 |
| `CallStatic` | `call` |
| `CallWitness` | `callvirt`（通过接口分派） |
| `CallDynamic` | `callvirt`（通过 TypeInfo） |
| 内存读写 | `ldfld` / `stfld` |
| 控制流 | CIL 分支指令 |

## Witness Table 在 CLR 上

CLR 后端类似 JVM 后端，利用 CLR 的虚方法分派机制。trait 编译为 .NET interface，`CallWitness` 映射为对 interface 方法的 `callvirt` 调用。

## 入口点

`EntryPolicy` 为 CLR 后端生成 `Main` 入口方法。

## `[clr]` FFI 支持

Valkyrie 的 `[clr("Type", "Method")]` 注解允许直接调用 .NET 方法。CLR 后端为这些调用生成 `call` 指令，不经过桥接层。

详见 [js-ffi.md](../js-ffi.md)。

## GC 集成

CLR 后端完全依赖 .NET GC，Valkyrie 的 `class` 类型直接映射为托管对象，享受 .NET 自动内存管理。