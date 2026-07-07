# nyar 文档

`nyar` 文档只负责说明元优化核心本身，不负责具体语言前端的组织方式。

## 范围

- `OA` 如何替代统一大 `IR`
- `EGraph` 如何作为共享优化体系替代传统 `pass pipeline`
- `PE` 如何承担静态化与特化，并挤压传统 `lowering`
- `nyar` 核心公共协议与长期边界

## 不在这里展开的内容

- 某个具体语言前端的目录组织
- 某个具体前端如何解析、绑定和产生诊断
- 工具层如何组织 `CLI` 工作流

## 与 `nyar.language` 的区别

- `projects/nyar/documentation/pages/zh-hans`：写 `nyar` 元优化核心
- `projects/nyar.language/documentation/pages/zh-hans`：写多语言前端如何接入 `nyar`

## 原则

`nyar` 是内核，不是某个语言的私有后端。
