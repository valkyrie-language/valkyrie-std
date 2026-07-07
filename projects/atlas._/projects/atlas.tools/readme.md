# atlas.tools

`atlas.tools` 是后端框架 `Atlas` 的命令行工具项目。

## 定位

- 面向 `Atlas` 框架的 `CLI`
- 作为后端工程的创建、构建与运维入口
- 承载 `Atlas` 框架相关的工具链工作流

## 适合承载什么

- `Atlas` 项目初始化与脚手架
- 开发、构建、调试、部署等命令
- 后端框架工程约定与本地开发流程
- 面向 `Atlas` 用户的命令行交互
- （planned）数据绑定：`RegenBindings` / `SchemaDiff` → `UpgradePlan` → 一次性 Apply——见 [数据访问文档](../atlas/documentation/pages/zh-hans/data-access/index.md)。
- 论证展开同目录：`upgrade-plan` / `schema-static-query-check` / `migrations-antipattern` / `query-ir`。

## 不适合承载什么

- `nyar` 核心公共部分
- 通用语言前端分析
- 与 `Atlas` 无关的通用包管理核心能力
- 其他框架或运行时家族的专用工具逻辑（含 **yyds** 数据库生态工具）
- **migrations-first** 工具链：不把「维护 / 回放 migrations 文件链 / 版本表」做成一等公民工作流（见 [migrations 回放](../atlas/documentation/pages/zh-hans/data-access/migrations-antipattern.md)）

## 与其他项目的关系

- 基于 `nyar` 体系的公共基础设施
- 与 `asgard.tools`、`legend.tools`、`legion.tools` 同属工具项目
- 各个工具之间职责独立，不互相从属
- `atlas.tools` 只负责 `Atlas` 的工具入口

## 目标

- 让 `Atlas` 的工程工具边界独立清晰
- 避免后端框架工具逻辑侵入核心库与其他工具链
- 为后端框架提供稳定的开发与交付入口
