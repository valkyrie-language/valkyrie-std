# JVM 后端

## 概述

JVM 后端将 `GenerateModule` 翻译为 JVM 字节码，输出 `.class` 文件。利用 JVM 的对象模型和 GC，Valkyrie 类型映射为 JVM 类。

## 管线

```
GenerateModule
  │
  ├── JVM Backend
  │     ├── 指令翻译：GenerateInstruction → JVM 字节码指令
  │     ├── 对象布局：利用 JVM 类模型
  │     └── GC 策略：利用 JVM GC（无需手动管理）
  │
  ▼
JvmClassFileData (使用 Acorn.Jvm.Data)
  │
  ├── Acorn.Jvm.Encode
  │
  ▼
.class (二进制)
```

## 类型映射

| Valkyrie 类型 | JVM 映射 |
|:---|:---|
| `class` | JVM class |
| `structure` | JVM class（值语义通过 `with` 方法实现） |
| `enums` / `flags` | JVM enum |
| `union` / `unite` | 密封类 + 记录类 |
| `trait` | JVM interface |
| 原始类型（`i32` 等） | JVM 原始类型 |

## 指令映射

| GenerateInstruction | JVM 对应 |
|:---|:---|
| 算术/逻辑运算 | JVM 算术/逻辑指令 |
| `CallStatic` | `invokestatic` |
| `CallWitness` | `invokeinterface`（通过接口分派） |
| `CallDynamic` | `invokeinterface`（通过 TypeInfo 查找） |
| 内存读写 | 字段访问 `getfield` / `putfield` |
| 控制流 | JVM 跳转指令 |

## Witness Table 在 JVM 上

JVM 后端利用 JVM 的 `invokeinterface` 指令实现 witness table 分派。trait 编译为 JVM interface，每个 impl 编译为对应的类实现该 interface。`CallWitness` 直接映射为 `invokeinterface`。

## 入口点

`EntryPolicy` 为 JVM 后端生成标准的 `public static void main(String[] args)` 入口方法，调用编译后的 Valkyrie 入口函数。

## GC 集成

JVM 后端完全依赖 JVM GC，不需要在生成代码中插入 GC 根扫描或内存管理指令。Valkyrie 的 `class` 类型直接享受 JVM 的自动内存管理。