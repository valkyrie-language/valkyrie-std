# Native 后端

## 概述

Native 后端将 `GenerateModule` 翻译为原生机器码，输出 `.elf`（Linux）、`.exe`（Windows）或 `.dylib`（macOS）格式。Native 后端需要自行处理内存布局、GC 和调用约定。

## 管线

```
GenerateModule
  │
  ├── Native Backend
  │     ├── 指令翻译：GenerateInstruction → 原生机器码
  │     ├── 对象布局：手动计算字段偏移和内存分配
  │     └── GC 策略：Boehm GC 或精确 GC
  │
  ▼
Native Data (平台特定数据结构)
  │
  ├── Acorn.Elf.Encode (Linux)
  ├── Acorn.Pe.Encode  (Windows)
  └── Acorn.MachO.Encode (macOS)
  │
  ▼
.elf / .exe / .dylib
```

## 指令翻译

Native 后端将 `GenerateInstruction` 序列翻译为对应平台的机器指令。指令选择（instruction selection）和寄存器分配（register allocation）在此层完成。

## 内存布局

| Valkyrie 类型 | Native 布局 |
|:---|:---|
| `structure` | 连续内存块，按对齐手动计算偏移 |
| `class` | 堆分配，头部含 TypeInfo 指针 |
| `enums` / `flags` | 底层整数类型 |
| `union` | 标签 + 最大变体数据 |
| `unite` | 紧凑 tagged union |

## GC 策略

Native 后端可选择两种 GC 策略：

- **Boehm GC**：使用 Boehm 保守式垃圾收集器，无需精确的 GC 位图
- **精确 GC**：使用 `LirTypeDef.GcPointerFieldIndices` 生成精确的根扫描代码，配合自定义 GC 运行时

## 平台适配

| 平台 | 二进制格式 | 编码器 | 调用约定 |
|:---|:---|:---|:---|
| Linux x86_64 | ELF | Acorn.Elf | System V AMD64 ABI |
| Windows x86_64 | PE | Acorn.Pe | Microsoft x64 ABI |
| macOS x86_64 / ARM64 | Mach-O | Acorn.MachO | Apple ABI |

## 入口点

`EntryPolicy` 根据目标平台生成对应的入口符号：

- Linux / macOS：`_start`
- Windows：`main` / `WinMain`

## 与 FFI 的关系

Native 后端支持 `[c("lib", "func")]` 和 `[syscall]` FFI 注解。前者生成对动态链接库导出函数的调用，后者生成直接的系统调用指令。