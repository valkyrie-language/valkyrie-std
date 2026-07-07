# nyar.language 文档

`nyar.language` 负责 `nyar` 体系中的多语言前端组织，以及语言前端如何接入 `nyar` 元优化体系。

## 目录

- [nyar 元优化体系](./meta-optimization.md)
- [前端契约](./frontend-contract.md)
- [工作流](./workflow.md)
- [源码布局](./source-layout.md)

## 范围

- 说明 `nyar.language` 在整个 `valkyrie.v` / `nyar` 体系中的定位
- 说明多语言前端如何接入并共享 `nyar` 的 `OA / EGraph / PE`
- 说明 `projects/nyar.language/source/*` 的组织方式与边界

## 不在本文档内展开的内容

- `nyar` 元优化核心本身的完整定义
- 具体某个目标家族的 backend input 与编码细节
- 具体 VM 家族的运行时约束
- 标准库与 adaptor 的完整绑定表

## 与 `nyar` 文档的区别

- `projects/nyar/documentation/pages/zh-hans`：定义 `nyar` 元优化核心
- `projects/nyar.language/documentation/pages/zh-hans`：定义语言前端如何接入该核心
