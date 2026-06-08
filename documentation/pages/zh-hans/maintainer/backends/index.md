# 后端架构

代码生成后端将统一的 `GenerateModule`（Nyar Standard IR）翻译为目标平台代码。所有后端共享相同的输入接口，在同一个语义主线下分叉。

## 在管线中的位置

```
... → GenerateModule → ⑧ Backend → 目标数据结构 → ⑨ Acorn 编码 → byte[]
```

后端是语义主线（阶段 ①~⑦ 所有 target 共享）结束后的分叉点。从这开始，不同 target 走不同的代码生成路径。

## 统一入口

```csharp
var backend = BackendSelector.Select(targetProfile);
var targetData = backend.Generate(module);
```

`BackendSelector` 根据 `CanonicalTriple` 选择后端。每个后端实现 `ICodeGenBackend`：

```csharp
public interface ICodeGenBackend
{
    object Generate(GenerateModule module);
}
```

返回值为目标平台数据结构（`NyarModuleData`、`WasmModuleData`、`JvmClassFileData` 等）。

## 后端列表

| 后端 | 输出 | 编码器 | 特点 | 文档 |
|:---|:---|:---|:---|:---|
| NyarVM | .nyar | Acorn.Nyar | 原生运行时，JIT 能力 | [nyar-vm.md](nyar-vm.md) |
| WASM | .wasm | Acorn.Wasm | 浏览器 / Node / Deno / Bun / WASI | [wasm.md](wasm.md) |
| JVM | .class | Acorn.Jvm | 利用 JVM 类型系统和 GC | [jvm.md](jvm.md) |
| CLR | .dll / .exe | Acorn.Clr | 利用 CLR 类型系统和 GC | [clr.md](clr.md) |
| Native | .elf / .exe / .dylib | Acorn.Elf / Pe / MachO | 手动内存布局和 GC | [native.md](native.md) |

## 后端负责

- 将 `GenerateInstruction` 序列翻译为目标指令
- 对象内存布局决策（字段偏移、对齐、分配策略）
- 调用约定适配（`CallStatic` / `CallWitness` / `CallDynamic` → 目标平台调用指令）
- GC 策略选择
- Witness Table 落地（函数指针表 / `invokeinterface` / `callvirt` / `call_indirect`）
- 生成目标平台数据结构，交给 Acorn 编码

## 后端不负责

- 语义分析（TypeChecker 阶段已完成）
- 优化（Nyar.Optimizer 阶段已完成）
- 二进制编码（委托 Acorn）
- 入口包装（Packaging 阶段负责）

## 跨后端共享

`CodeGenModuleAdapter` 为各后端提供统一的 LIR 遍历基础设施：

```csharp
public abstract class CodeGenModuleAdapter
{
    protected abstract void EmitInstruction(GenerateInstruction inst);
    protected abstract void EmitCall(GenerateCall call);
    // ...
    public void Traverse(GenerateModule module) { /* 遍历算法 */ }
}
```

后端继承此基类，只需重写各指令的翻译逻辑，不需要自己实现控制流遍历。

## 类型信息在后端的处理

LIR 输出 `LirTypeDef` 表，包含：

| 信息 | 用途 |
|:---|:---|
| 字段列表（名称、偏移、大小） | 内存布局计算 |
| `GcPointerFieldIndices` | GC 根扫描 |
| 底层类型 | 枚举/标志的整数映射 |

各后端根据自身平台特性做出最终布局决策：

| 后端 | 布局策略 |
|:---|:---|
| NyarVM | 使用 VM 内置对象模型 |
| WASM | 线性内存中手动计算偏移 |
| JVM | 映射到 JVM 对象模型，利用 JVM GC |
| CLR | 映射到 CLR 类型系统 |
| Native | 直接计算内存偏移，生成 GC 根扫描代码 |