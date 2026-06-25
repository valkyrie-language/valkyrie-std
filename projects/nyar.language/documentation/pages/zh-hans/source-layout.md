# 源码布局

## 目标

本文定义 `projects/nyar.language/source/*` 的长期目录布局与共享约束。

核心要求只有一句话：

- 语言前端可以多样化实现
- 但必须以统一方式归档在 `source/*`
- 并通过统一契约接入 `nyar`

## 当前目录

当前前端目录包括：

- `projects/nyar.language/source/bash`
- `projects/nyar.language/source/bat`
- `projects/nyar.language/source/powershell`
- `projects/nyar.language/source/valkyrie`

后续新增语言时，应保持同样的一级目录结构。

## 一级目录规则

每个语言使用一个独立目录，目录名直接对应语言或前端身份。

例如：

- `bash`
- `bat`
- `powershell`
- `valkyrie`

不要在一级目录里混入：

- target family 名称
- VM 家族名称
- 打包器或工具层名称

这些概念属于别的边界。

## 每个语言目录至少应包含什么

每个语言目录至少应有：

- `readme.md`
- 源码目录
- 前端测试目录或等价测试入口
- 文档或设计记录入口

其中 `readme.md` 至少要写明：

- 该前端的定位
- 它适合承载什么
- 它不适合承载什么
- 它如何接入 `nyar`

## 允许的内部差异

不同语言前端内部可以完全不同：

- 有的前端分 `AST / HIR / MIR`
- 有的前端只保留轻量语法树与语义模型
- 有的前端更偏解释式
- 有的前端更偏静态编译式

这些差异都允许，因为它们只是前端私有实现细节。

## 不允许的退化

以下情况应长期禁止：

- 把某个前端的私有中间层升级为全体系共享契约
- 在 `source/*` 下混入 target family 专用 backend 实现
- 在 `source/*` 下混入工程工具层的大量编排逻辑
- 因为单一语言特例而破坏整体目录约束

## 与工具层的关系

`source/valkyrie` 是 `Valkyrie` 前端本体。

任何上层工具若要整合工作流，都不应驻扎到 `source/valkyrie` 目录里，也不应在工具层再复制一套语言前端实现。

同理，其他语言若未来有各自工具入口，也应遵守：

- 前端留在 `source/*`
- 工具留在工具项目
- 不把目录职责混写

## 与 `nyar` 的关系

`source/*` 是语言接入层，`nyar` 是共享元优化核心。

因此：

- 语言源码布局属于 `nyar.language`
- `OA / EGraph / PE` 核心定义属于 `nyar`
- 二者通过契约连接，而不是通过共享一堆杂糅目录连接

## 长期维护要求

- 新前端接入时先补 `readme.md`
- 新前端接入时明确其与 `nyar` 的语义入口
- 前端目录命名保持稳定、直接、可预测
- 前端目录只承载前端，不承载越界职责
