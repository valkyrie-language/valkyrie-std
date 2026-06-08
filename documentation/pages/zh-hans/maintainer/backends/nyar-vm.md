# NyarVM 后端

## 概述

NyarVM 后端将 `GenerateModule` 直接翻译为 NyarVM 指令，输出 `.nyar` 格式的字节码。NyarVM 是 Valkyrie 的原生运行时，提供 JIT 编译能力。

## 管线

```
GenerateModule
  │
  ├── NyarVM Backend
  │     ├── 指令翻译：GenerateInstruction → NyarVM OpCode
  │     ├── 对象布局：按 NyarVM 对象模型计算字段偏移
  │     └── GC 策略：使用 NyarVM 内置 GC
  │
  ▼
NyarModuleData
  │
  ├── Acorn.Nyar.Encode
  │
  ▼
.nyar (二进制字节码)
```

## 指令映射

NyarVM 后端将 `GenerateInstruction` 一对一或一对多映射为 NyarVM 操作码。由于 GenerateModule 本身就是为 NyarVM 设计的标准 IR，大部分指令无需变换即可直接输出。

## 对象模型

NyarVM 使用统一的堆对象模型：

- `class` → 堆分配对象，头部包含 TypeInfo 指针和 GC 标记位
- `structure` → 值类型，栈分配或内联于父对象
- `union` → 堆分配，头部包含 TypeInfo 指针用于运行时变体判别
- `unite` → 内联 tagged union，值语义

## Witness Table

NyarVM 后端将 witness table 条目编译为函数指针表，存储在模块的元数据段。运行时通过 `(TraitName, SlotIndex)` 二元组索引。

## 调用约定

- `CallStatic` → 直接跳转到目标函数
- `CallWitness` → 通过槽索引从 witness table 加载函数指针后间接调用
- `CallDynamic` → 从对象头部的 TypeInfo 加载 witness table，再按槽索引间接调用

## 多文件支持

NyarVM 后端生成单一的 `.nyar` 模块。多文件项目的模块间引用通过 `[import]` / `[export]` 注解在 packaging 阶段处理，编译为一个整体或分模块发布。