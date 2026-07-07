# bash

`bash` 是 `nyar.language` 体系中的 `Bash` 前端入口。

## 定位

- 面向 `Bash` / `POSIX shell` 脚本的解析与前端分析
- 内置 `coreutils` 等常用命令能力的语言级建模与前端约束
- 负责把 shell 语义接入 `nyar` 元优化体系
- 作为 `Bash` 语言到 `nyar` 公共语义层之间的前端桥接

## 适合承载什么

- `Bash` 语法解析与语法树
- 名称、作用域、命令解析等前端语义分析
- `coreutils` 等常用命令能力的内置语义入口与标准命令建模
- shell 脚本的前端诊断与约束检查
- 把 `Bash` 语义映射到 `nyar` 可优化语义对象的前端逻辑

## 不适合承载什么

- `nyar` 核心 `OA / EGraph / PE` 基础设施本身
- 其他语言前端的共享抽象
- 目标家族专用的后端编码与运行时细节
- 把 `Bash` 私货抬升成所有语言的公共前提

## 与其他项目的关系

- `projects/nyar`：提供元优化核心与公共协议
- `projects/nyar.language`：提供多语言前端组织方式
- `projects/nyar.language/source/*`：与其他语言前端并列存在

## 目标

- 让 `Bash` 脚本成为 `nyar` 体系中的正式前端
- 让常用 `coreutils` 能以稳定语义而不是脆弱文本约定被前端识别
- 共享 `nyar` 的元优化能力，而不是重复造一套 shell 专属优化管线
- 保持 `Bash` 前端边界清楚，不反向污染核心层
