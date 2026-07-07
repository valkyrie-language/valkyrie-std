# 工作流

## 目标

本文定义 `nyar.language` 视角下的前端工作流边界，重点说明：

- `source/valkyrie` 如何作为 `Valkyrie` 前端本体存在
- `nyar` 如何作为统一元优化核心参与后续流程
- 语言前端如何在不感知具体工具层实现的前提下接入后续链路

## 核心原则

- `source/*` 负责语言前端
- `nyar` 负责 `OA / EGraph / PE` 元优化核心
- 工具层若存在，也只能通过稳定接口调用前端与核心层

各层必须协作，但不能互相越权。

## `Valkyrie` 的正式调用链

`Valkyrie` 的长期调用链应固定为：

```text
source/valkyrie（AST → HIR → MIR → ExecutableModule 适配）
    -> nyar.analyzer
    -> nyar.optimizer
    -> nyar.emitter（各 lane 消费 ExecutableModule）
    -> 产物 → nyar.vm.*（仅消费，不依赖 language）
```

更准确地说：

```text
工具层 / 上层入口（legion.tools）
    -> projects/nyar._/projects/nyar.language/source/valkyrie
    -> nyar.analyzer → nyar.optimizer → nyar.emitter
    -> target family artifact / nyar.vm.*
```

类型与类名写全称（如 `ExecutableModule`、`ExecutableInstruction`），禁止 `Exec` / `ExecModule` 等简写。`body_source` / `clr_body_lowering` / type-name 特判旁路**不是**正式架构。

## 工具层负责什么

若存在独立工具层，它应负责：

- 创建与初始化 `Valkyrie` 项目
- 解析 workspace、依赖与配置
- 调用 `source/valkyrie` 执行前端分析
- 串联构建、测试、运行、打包、发布工作流
- 组织缓存、产物目录与交付记录

它的职责是编排，不是重新实现语义。

## 工具层不负责什么

工具层不应负责：

- 重新实现一套 `Valkyrie` parser、binder 或 type checker
- 自己维护一套平行的优化主线
- 自己定义 `OA / EGraph / PE` 核心协议
- 把工具层临时状态抬升成语言语义事实

一旦工具层开始复制前端或核心层实现，后续维护成本会急剧上升。

## `source/valkyrie` 负责什么

`projects/nyar.language/source/valkyrie` 应负责：

- `Valkyrie` 源码解析
- 名称解析与类型检查
- 语言级约束闭合
- 诊断生成
- 把前端语义接入 `nyar`

它不负责项目创建、依赖安装、缓存编排或发布工作流。

## `nyar` 在工作流中的位置

`nyar` 是 `source/*` 前端之后、target family 之前的共享元优化核心。

这意味着：

- 不同语言前端都应在这里汇合
- 共享优化知识应优先沉淀在这里
- 工具层调用的应是这条既有链路，而不是旁路复制一套能力

## 设计要求

- 工具层与 `source/valkyrie` 之间应保持清晰接口
- `source/valkyrie` 与 `nyar` 之间应保持清晰语义入口
- 工具层升级不应破坏前端与元优化核心的边界
- 前端升级不应要求工具层重写一大批平行逻辑

## 长期约束

- 新工作流优先整合现有实现
- 不新增平行 parser、平行 binder、平行 optimizer
- 不让工具层变成新的语义核心
- 不让语言前端反过来承担工程工作流职责
