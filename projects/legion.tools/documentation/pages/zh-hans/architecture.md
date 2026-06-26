# 架构

## 目标

本文描述 `legion.tools` 的内部模块职责。

`workflow.md` 负责说明 `legion.tools` 如何编排外部调用链；本文只回答一个问题：

- `legion.tools` 内部各个源码模块分别负责什么

本文同时区分：

- 当前实现主要集中在哪里
- 长期应该拆成什么目录结构

## 目标结构

长期来看，`legion.tools/source` 更合理的结构应为：

- `app.v` 或 `cli.v`：最薄的顶层命令分发入口
- `commands/build.v`：`build` 命令入口与编排
- `commands/publish.v`：`publish` 命令入口与编排
- `commands/pack.v`：`pack` 命令入口与编排
- `cli_args.v`：命令行参数解析与共享 CLI 参数 helper
- `paths.v`：路径归一、路径拼接、项目目录与输出目录解析
- `requests.v`：`BuildRequest` 等共享请求结构
- `host_bridge.v`：宿主桥与外部执行器声明
- `manifest.v`：`legion.von` / `legions.von` 读取与清单建模
- `build_context.v`：目标归一化、依赖图、构建上下文生成
- `build_planner.v`：源码闭包收集、编译计划、后端执行请求与快照

它们的关系应理解为：

```text
app.v / cli.v
    -> commands/build.v
    -> commands/publish.v
    -> commands/pack.v
    -> cli_args.v
    -> paths.v
    -> requests.v
    -> host_bridge.v
    -> manifest.v
    -> build_context.v
    -> build_planner.v
```

## 当前状态

当前磁盘上的实现仍然主要集中在 [_.v](file:///e:/RiderProjects/valkyrie.v/projects/legion.tools/source/_.v)。

也就是说，下面这些职责现在事实上还混在一个总入口文件里：

- 命令入口
- 参数解析
- build / publish / pack 流程编排
- workspace 与单项目分发
- 宿主桥调用

这在原型阶段是可接受的，但长期会让 `_.v` 重新膨胀成新的命令层 `god object`。

## 目标模块职责

## `app.v` 或 `cli.v`

`app.v` 或 `cli.v` 应是 `legion.tools` 的最薄顶层入口。

它应只负责：

- 注册命令名
- 把命令分发到 `commands/*`
- 处理最外层的 `--help`、`--version` 等入口行为

它不应负责：

- 命令内部逻辑
- 构建目标选择
- build / publish / pack 的细节流程
- 具体宿主桥调用

换句话说，它应始终保持为“路由层”。

## `commands/build.v`

`commands/build.v` 应是 `build` 命令的唯一入口。

它应负责：

- 解析 `build` 子命令参数
- 识别单项目构建还是 workspace 构建
- 调用 `manifest.v` 读取清单
- 调用 `build_context.v` 生成构建上下文
- 调用 `build_planner.v` 生成编译计划与执行请求
- 调用 `host_bridge.v` 或等价执行边界完成后端执行

它不应负责：

- 清单字段底层解析
- 依赖图算法实现
- 源码闭包扫描实现
- `publish` 或 `pack` 的专属流程

## `commands/publish.v`

`commands/publish.v` 应是 `publish` 命令的唯一入口。

它应负责：

- 解析 `publish` 子命令参数
- 读取与选择 `publish` 目标
- 在需要时先组织 build 验证，再进入发布流程
- 调用打包与发布所需的宿主桥边界

它不应负责：

- 复制一整套 `build` 命令实现
- 重新实现 manifest 解析或 compile plan 建模

## `commands/pack.v`

若 `pack` 继续存在，`commands/pack.v` 应只负责打包入口。

它应负责：

- 解析 `pack` 子命令参数
- 读取清单中的打包目标
- 组织 package output 目录与打包请求

它不应负责：

- 顶层命令路由
- 一整套前端或优化逻辑

## `cli_args.v`

`cli_args.v` 应承载命令行参数解析相关的共享逻辑。

适合放在这里的内容包括：

- 子命令参数扫描
- `--target`、`--output`、`--verbose` 等共享参数解析
- `--help`、`--version` 的参数层 helper
- 参数尾段收集与基础校验

不适合放在这里的内容包括：

- 目录解析与路径归一
- 请求结构定义
- 具体命令的大段编排流程

## `paths.v`

`paths.v` 应承载与文件系统路径相关的共享逻辑。

适合放在这里的内容包括：

- 路径归一
- 路径拼接
- 项目目录解析
- 输出目录默认值与目录派生

不适合放在这里的内容包括：

- 参数扫描
- 清单建模
- 编译计划建模

## `requests.v`

`requests.v` 应承载命令层共享的数据请求结构。

适合放在这里的内容包括：

- `BuildRequest`
- `PublishSelection`
- 其他跨命令复用的轻量请求或选择结果结构

不适合放在这里的内容包括：

- 大段流程代码
- 参数解析算法
- 宿主桥声明

## `host_bridge.v`

`host_bridge.v` 应承载工具层到外部宿主或执行器的桥接声明。

适合放在这里的内容包括：

- `clr_source_compile_project()`
- `clr_host_pack_project()`
- 其他宿主桥声明

不适合放在这里的内容包括：

- 顶层命令逻辑
- 清单解析
- 构建上下文与编译计划算法

## `manifest.v`

`manifest.v` 是清单与配置输入层。

它当前负责：

- 读取 `legion.von` 与 `legions.von`
- 把 `VON` 文本解析为结构化对象
- 建模 `LegionProjectManifest`、`LegionWorkspaceManifest`
- 解析 `build`、`publish`、`dependencies`、`auto_link`
- 处理 workspace 级 `auto_link` 默认值

它不应负责：

- 命令行参数解析
- 构建目标选择策略
- 依赖图拓扑排序
- 编译计划与后端执行

`manifest.v` 的责任边界应该停在“把清单变成稳定数据结构”。

## `build_context.v`

`build_context.v` 是构建上下文归一层。

它当前负责：

- 把短目标名归一化为 `CanonicalTarget`
- 识别 `arch_tag`、`abi`、`backend_family`
- 计算项目名、输出根目录与目标输出目录
- 根据 manifest 与请求生成一个或多个 `LegionBuildContext`
- 构建依赖图并做循环依赖检查
- 生成依赖顺序与直接依赖列表

它不应负责：

- 清单底层解析
- 源码文件扫描
- 编译计划快照输出
- 宿主桥执行

这一层的重点是“把输入请求和清单约束收敛成统一构建上下文”。

## `build_planner.v`

`build_planner.v` 是计划与执行桥接层。

它当前负责：

- 搜集项目与依赖包的源码闭包
- 构建 `LegionCompilePlan`
- 构建 `LegionBackendExecutionRequest`
- 写出 compile plan、backend request、backend result 快照
- 根据执行模式触发具体后端执行器
- 返回统一的 `LegionBackendExecutionResult`

它不应负责：

- CLI 命令分发
- 清单解析
- 顶层 build/publish 策略

这一层是内部最接近“执行边界”的模块，但它仍然应聚焦在计划与执行请求，不应回流成前端语义层。

## 目标依赖方向

当前较健康的依赖方向应保持为：

- `app.v` / `cli.v` 依赖 `commands/*`
- `app.v` / `cli.v` 依赖 `cli_args.v`
- `app.v` / `cli.v` 依赖 `paths.v`
- `app.v` / `cli.v` 依赖 `requests.v`
- `commands/*` 依赖 `manifest.v`
- `commands/*` 依赖 `build_context.v`
- `commands/*` 依赖 `build_planner.v`
- `commands/*` 依赖 `host_bridge.v`
- `commands/*` 依赖 `cli_args.v`
- `commands/*` 依赖 `paths.v`
- `commands/*` 依赖 `requests.v`
- `build_context.v` 依赖 `manifest.v` 暴露的数据结构
- `build_planner.v` 依赖 `build_context.v` 暴露的 `LegionBuildContext`

不应出现的方向包括：

- `manifest.v` 反向依赖 `commands/*` 或 `app.v`
- `build_context.v` 反向依赖 `build_planner.v`
- `build_planner.v` 反向驱动 CLI 分发逻辑
- `host_bridge.v` 反向承载命令编排逻辑

## 当前源码对应关系

当前实现还没有完全拆成 `commands/*.v`，所以磁盘上的对应关系仍是：

- [_.v](file:///e:/RiderProjects/valkyrie.v/projects/legion.tools/source/_.v)
- [manifest.v](file:///e:/RiderProjects/valkyrie.v/projects/legion.tools/source/manifest.v)
- [build_context.v](file:///e:/RiderProjects/valkyrie.v/projects/legion.tools/source/build_context.v)
- [build_planner.v](file:///e:/RiderProjects/valkyrie.v/projects/legion.tools/source/build_planner.v)

## 长期维护要求

- 逐步把 `_.v` 收敛成最薄入口
- `build`、`publish`、`pack` 逐步迁移到 `commands/*.v`
- 参数解析优先迁移到 `cli_args.v`
- 路径处理优先迁移到 `paths.v`
- 共享请求结构优先迁移到 `requests.v`
- 宿主桥声明优先迁移到 `host_bridge.v`
- 清单协议继续留在 `manifest.v`
- 上下文归一化继续留在 `build_context.v`
- 计划与执行桥接继续留在 `build_planner.v`
- 新功能优先落到正确层级，不要继续往 `_.v` 堆积
- 不把某个模块膨胀成新的 `god object`
