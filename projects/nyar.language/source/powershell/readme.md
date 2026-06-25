# powershell

`powershell` 是 `nyar.language` 体系中的 `PowerShell` 前端入口。

## 定位

- 面向 `PowerShell` 脚本与命令模型的解析与前端分析
- 负责把 `PowerShell` 语义接入 `nyar` 元优化体系
- 作为 `PowerShell` 到 `nyar` 公共语义层之间的前端桥接

## 适合承载什么

- `PowerShell` 语法解析与语法树
- 命令绑定、管道语义、对象流分析等前端逻辑
- `PowerShell` 脚本的前端诊断与约束检查
- 把 `PowerShell` 语义映射到 `nyar` 可优化语义对象的前端逻辑

## 不适合承载什么

- `nyar` 核心 `OA / EGraph / PE` 基础设施本身
- 其他语言前端共享的公共抽象
- 目标家族专用的 backend input 与编码细节
- 把 `PowerShell` 的宿主假设抬升成整个体系的核心前提

## 与其他项目的关系

- `projects/nyar`：提供元优化核心与公共协议
- `projects/nyar.language`：提供多语言前端组织方式
- `projects/nyar.language/source/*`：与 `bash`、`bat`、`valkyrie` 等前端并列存在

## 目标

- 让 `PowerShell` 成为 `nyar` 体系中的正式前端
- 共享 `nyar` 的元优化能力，而不是单独维护一套命令式脚本优化框架
- 保持对象流与宿主模型只在前端范围内解释，不反向污染核心层
