# legion.tools

`legion.tools` 是建立在 `Valkyrie` 前端之上的工程入口、工作流编排器与包管理工具。

## 定位

- 作为 `Valkyrie` 的主要工具入口
- 基于 `projects/nyar.language/source/valkyrie` 前端组织开发者工作流
- 同时承担构造器、工程编排与包管理职责
- 承载项目构建、测试、打包与发布相关工作流

## 适合承载什么

- `Valkyrie` 项目的创建、构建与工程编排
- 包依赖管理、安装、更新与工作区流程
- 面向开发者的命令行交互与工程入口
- 与 `Valkyrie` 构建交付相关的工具链能力
- 串联现有前端、编译与交付能力，而不是复制它们的实现

## 不适合承载什么

- `nyar` 核心公共协议本身
- 具体语言前端分析逻辑
- 单一运行时家族的专用执行器逻辑
- 其他框架专用的 `CLI` 业务流程
- 再实现一套与 `source/valkyrie` 平行的 `Valkyrie` 前端

## 与其他项目的关系

- 基于 `nyar` 体系的公共基础设施
- 与 `legend.tools`、`atlas.tools`、`asgard.tools` 同属工具项目
- 各个工具之间职责独立，不互相从属
- `projects/nyar.language/source/valkyrie`：提供 `Valkyrie` 语言前端
- `legion.tools`：基于该前端整合工作流，而不是重复实现语义层

## 文档

- [工作流](./documentation/pages/zh-hans/workflow.md)
- [架构](./documentation/pages/zh-hans/architecture.md)

## 目标

- 为 `Valkyrie` 提供统一、稳定的工程入口
- 保持构建与包管理职责清晰
- 避免工具层反向污染核心库与前端分析层
- 优先整合现有工作流，而不是继续膨胀出一大堆平行实现