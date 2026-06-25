# legend.tools

`legend.tools` 是 `legacy vm` 的命令行工具项目。

## 定位

- 面向 `legacy vm` 的工具入口
- 承载脚本与命令环境相关的执行与管理能力
- 作为 `legacy vm` 对外的操作与工作流入口

## 适合承载什么

- 运行 `bat`、`ps1`、`cmd`、`sh` 等脚本与命令环境
- 与 `legacy vm` 相关的执行、调试与管理命令
- 面向传统脚本生态的工具链适配
- 面向 `legacy vm` 用户的命令行交互

## 不适合承载什么

- `nyar` 核心公共协议
- 语言前端分析逻辑
- `Valkyrie` 通用构建器与包管理职责
- 其他框架专用的 `CLI` 工作流

## 与其他项目的关系

- 基于 `nyar` 体系的公共基础设施
- 与 `legion.tools`、`atlas.tools`、`asgard.tools` 同属工具项目
- 各个工具之间职责独立，不互相从属
- `legend.tools` 只负责 `legacy vm` 的工具入口

## 目标

- 让 `legacy vm` 有独立清晰的工具边界
- 为传统脚本与命令环境提供统一入口
- 避免 `legacy vm` 工具逻辑侵入核心库与其他工具链
