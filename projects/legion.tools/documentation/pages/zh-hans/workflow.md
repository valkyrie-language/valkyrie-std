# 工作流

## 目标

本文定义 `legion.tools` 视角下的 `Valkyrie` 工程工作流。

重点说明三件事：

- `legion.tools` 如何作为开发者与 `CI` 的统一入口
- `legion.tools` 如何调用 `source/valkyrie` 与 `nyar`
- `legion.tools` 应整合哪些流程，以及绝不能越过哪些边界

本文描述的是长期工作流结构，不等同于“当前所有代码都已经拆完”。

## 调用链

`legion.tools` 自己知道并组织如下调用链：

```text
用户 / CI
    -> legion.tools
    -> app.v / cli.v
    -> commands/build.v | commands/publish.v | commands/pack.v
    -> source/valkyrie
    -> nyar
    -> target family / runtime / packaging
```

在这条链路里：

- `source/valkyrie` 负责前端解析、绑定、类型检查与诊断
- `nyar` 负责 `OA / EGraph / PE` 元优化核心
- `legion.tools` 负责把创建、构建、测试、运行、打包、发布等工作流编排起来

当前实现中，这些命令逻辑仍主要集中在 `source/_.v`；但长期应迁移到 `commands/*.v`。

## 命令层结构

长期建议的命令层结构如下：

- `app.v` 或 `cli.v`：最薄的命令路由层
- `commands/build.v`：`build` 命令编排
- `commands/publish.v`：`publish` 命令编排
- `commands/pack.v`：`pack` 命令编排
- `cli_args.v`：命令行参数解析与共享 CLI 参数 helper
- `paths.v`：路径归一、项目目录与输出目录解析
- `requests.v`：`BuildRequest` 等共享请求结构
- `host_bridge.v`：宿主桥与外部执行器声明

## `legion.tools` 负责什么

`legion.tools` 应负责：

- 项目创建与初始化
- workspace、依赖与配置解析
- 调用 `source/valkyrie` 执行前端分析
- 串联构建、测试、运行、打包、发布工作流
- 组织缓存、产物目录与交付记录

它的职责是编排，不是重新实现语义。

更具体地说：

- 顶层入口负责命令分发
- `commands/*` 负责各自子命令编排
- `cli_args.v` 负责参数解析
- `paths.v` 负责路径相关 helper
- `requests.v` 负责共享请求结构
- 构建上下文与编译计划应继续交给更下层模块
- 宿主桥调用应收口在独立桥接层，而不是散落在多个命令文件里

## `legion.tools` 不负责什么

`legion.tools` 不应负责：

- 重新实现一套 `Valkyrie` parser、binder 或 type checker
- 自己维护一套平行的优化主线
- 自己定义 `OA / EGraph / PE` 核心协议
- 把工具层临时状态抬升成语言语义事实

一旦工具层开始复制前端或核心层实现，后续维护成本会急剧上升。

同样不应做的还有：

- 把所有命令继续长期堆在 `_.v`
- 让 `publish` 直接复制一整份 `build` 流程
- 让宿主桥声明混回命令编排层

## 输入与输出

`legion.tools` 的典型输入包括：

- workspace 清单
- 项目配置
- 依赖信息
- 构建、测试、发布等命令参数

`legion.tools` 的典型输出包括：

- 构建计划
- 执行中的工作流状态
- 产物目录与交付记录
- 面向开发者与 `CI` 的诊断汇总

## 设计要求

- 与 `source/valkyrie` 之间保持清晰接口
- 与 `nyar` 之间保持清晰调用边界
- 与 `build_context.v`、`build_planner.v` 之间保持清晰模块边界
- 新工作流优先整合现有实现
- 不新增平行 parser、平行 binder、平行 optimizer
- 不让工具层变成新的语义核心
- 优先把命令逻辑拆入 `commands/*.v`，而不是继续膨胀 `_.v`

## 长期目标

- 为 `Valkyrie` 提供统一、稳定的工程入口
- 保持构建与包管理职责清晰
- 避免工具层反向污染核心库与前端分析层
- 优先整合现有工作流，而不是继续膨胀出一大堆平行实现
