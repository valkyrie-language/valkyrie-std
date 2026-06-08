# WASM 后端

## 概述

WASM 后端将 `GenerateModule` 翻译为 WebAssembly 指令，输出 `.wasm` 二进制。目标平台包括浏览器、Node.js、Deno、Bun 和 WASI。

## 管线

```
GenerateModule
  │
  ├── WASM Backend
  │     ├── 指令翻译：GenerateInstruction → WASM 操作码
  │     ├── 对象布局：线性内存中手动管理偏移
  │     └── GC 策略：依赖宿主 GC（JS GC 或 WASM GC 提案）
  │
  ▼
WasmModuleData (使用 Acorn.Wasm.Data)
  │
  ├── Acorn.Wasm.Encode
  │
  ▼
.wasm (二进制)
```

## 指令映射

| GenerateInstruction | WASM 对应 |
|:---|:---|
| 算术/逻辑运算 | WASM 算术/逻辑指令（直接映射） |
| `CallStatic` | `call` 指令（函数索引） |
| `CallWitness` | `call_indirect`（通过函数表） |
| `CallDynamic` | `call_indirect`（通过函数表 + TypeInfo） |
| 内存读写 | `i32.load` / `i32.store` 等 |
| 控制流 | `br` / `br_if` / `block` / `loop` |

## 线性内存布局

WASM 后端在线性内存中手动管理对象布局：

- `structure` → 按对齐要求分配连续内存块
- `class` → 头部含 TypeInfo 偏移量指针 + 字段数据
- `union` / `unite` → tagged union 布局（标签 + 最大变体数据）

GC 位图信息从 `LirTypeDef.GcPointerFieldIndices` 获取，用于生成 GC 根扫描代码。

## Web API 桥接

浏览器 API 通过 `[wasm_import]` 注解声明，WASM 后端生成对应的 import 段。JS 胶水代码（`voa-runtime.js`）提供这些 import 的实现。

详见 [js-ffi.md](../js-ffi.md)。

## 多目标变体

同一 WASM 后端通过 CanonicalTriple 区分不同宿主：

| CanonicalTriple | 目标 |
|:---|:---|
| `wasm32-unknown-browser` | 浏览器 |
| `wasm32-unknown-node` | Node.js |
| `wasm32-unknown-deno` | Deno |
| `wasm32-unknown-bun` | Bun |
| `wasm32-unknown-wasi-wasip1` | WASI Preview 1 |
| `wasm32-unknown-wasi-wasip2` | WASI Preview 2 |

不同宿主的主要差异在 Packaging 阶段处理（生成不同的 JS glue、入口包装）。