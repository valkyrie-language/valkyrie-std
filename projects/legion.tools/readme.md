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

## 工作流位置

`legion.tools` 自己知道并组织如下调用链：

```text
用户 / CI
    -> legion.tools
    -> source/valkyrie
    -> nyar
    -> target family / runtime / packaging
```

在这条链路里：

- `source/valkyrie` 负责前端解析、绑定、类型检查与诊断
- `nyar` 负责 `OA / EGraph / PE` 元优化核心
- `legion.tools` 负责把创建、构建、测试、运行、打包、发布等工作流编排起来

## 工具层边界

`legion.tools` 应负责：

- 项目创建与初始化
- workspace、依赖与配置解析
- 调用 `source/valkyrie` 执行前端分析
- 串联构建、测试、运行、打包、发布工作流
- 组织缓存、产物目录与交付记录

`legion.tools` 不应负责：

- 重新实现一套 `Valkyrie` parser、binder 或 type checker
- 自己维护一套平行的优化主线
- 自己定义 `OA / EGraph / PE` 核心协议
- 把工具层临时状态抬升成语言语义事实

## 目标

- 为 `Valkyrie` 提供统一、稳定的工程入口
- 保持构建与包管理职责清晰
- 避免工具层反向污染核心库与前端分析层
- 优先整合现有工作流，而不是继续膨胀出一大堆平行实现
