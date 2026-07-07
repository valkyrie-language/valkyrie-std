# 前端契约

## 目标

`nyar.language` 的职责不是把所有语言揉成一个前端，而是给所有语言前端一套统一接入 `nyar` 的契约。

这套契约要保证两件事：

- 前端可以自由演进，不被统一大 `IR` 卡死
- 多语言又能共享同一套 `nyar` 元优化体系

## 目录组织

当前语言前端统一放在（相对 `projects/nyar._`）：

- `projects/nyar.language/source/bash`
- `projects/nyar.language/source/bat`
- `projects/nyar.language/source/powershell`
- `projects/nyar.language/source/valkyrie`

仓库绝对路径形如 `valkyrie.v/projects/nyar._/projects/nyar.language/source/*`。后续新增语言时，也应按同样方式接入。

Valkyrie（源码后缀 `.v`，与语言名同一事物）的 AST/CST 归属 **`std.data.text.valkyrie`**，由 `nyar.language` 前端消费；**不要**再维护平行包 `std.data.text.v`。正式同构主线继续进入 `nyar.analyzer` → `nyar.optimizer` → `nyar.emitter`，中性输入为 **`ExecutableModule`**（全称，禁止 `Exec` / `ExecModule`）。

## 每个前端负责什么

每个语言前端至少负责：

- 源码解析
- 基本语义建模
- 语言级约束检查
- 诊断生成
- 把前端结果接入 `nyar` 的 `OA` 语义入口

前端内部可以：

- 自己分 `AST / HIR / MIR`
- 只保留 `AST + binder`
- 使用解释式前端
- 使用图结构、树结构或对象模型

这些都允许，因为它们只是前端私有实现。

## 每个前端不负责什么

每个前端都不应承担：

- `nyar` 核心 `OA / EGraph / PE` 的定义权
- 其他语言的共享协议设计
- target family 专用 backend input
- 编码、打包、运行契约等交付逻辑

前端不得把自己的私有假设抬升为整个体系的公共前提。

## 前端接入 nyar 的最小要求

一个语言前端若要正式接入 `nyar`，至少需要明确：

- 自己如何把语义表达为 `OA`
- 哪些优化规则可直接进入公共 `EGraph`
- 哪些语义可通过 `PE` 提前静态化
- 哪些开放语义必须在进入 target family 之前闭合

这四件事比“前端内部到底分几层”更重要。

## 共享优化的原则

跨语言共享优化时，应优先遵守以下顺序：

1. 先尝试写成 `OA` 层共享语义规则
2. 再尝试写成 `EGraph` 等价变换
3. 再尝试写成 `PE` 静态化或特化逻辑
4. 最后才考虑某个前端私有的过渡性变换

这样做的目的是让优化知识尽量沉淀在 `nyar` 核心，而不是散落在每个语言前端里。

## 与 target family 的边界

前端只负责把语言语义接入 `nyar`，不直接决定：

- 目标文件格式
- 宿主入口包装
- sidecar 内容
- 运行时家族交付细节

这些工作应由 `nyar` 后续的 family 边界、运行时家族和交付层负责。

## `Valkyrie` 与工具层

`projects/nyar.language/source/valkyrie`（即 `valkyrie.v/projects/nyar._/projects/nyar.language/source/valkyrie`）是 `Valkyrie` 语言前端本体（源码后缀 `.v`；AST/CST 在 `std.data.text.valkyrie`）。

任何面向 `Valkyrie` 的上层工具都应建立在这个前端之上，承担工程入口与工作流编排职责：

- 创建项目
- 调用前端分析
- 串联构建、测试、打包与发布工作流
- 组织缓存、依赖与交付流程

工具层不应自己再复制一套 `Valkyrie` 前端实现，也不应把工作流编排膨胀成新的语义实现层。

正确关系是：

- `source/valkyrie` 负责语言前端
- 工具层负责整合工作流
- 二者共同建立 `Valkyrie` 的开发者入口，但职责不能混淆

## 长期维护要求

- 新增前端时，优先复用现有 `OA / EGraph / PE` 基础设施
- 不为单一前端单独复制一套长期优化主线
- 不允许因为某个语言特例而破坏整个体系的边界
- 前端文档必须清楚写明自己的定位、边界与接入方式
- 工具层应优先整合现有前端与核心工作流，而不是重复实现同一能力
