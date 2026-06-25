# valkyrie

`valkyrie` 是 `nyar.language` 体系中的 `Valkyrie` 语言前端入口。

## 定位

- 面向 `Valkyrie` 语言的解析、语义建模与前端分析
- 负责把 `Valkyrie` 语言语义接入 `nyar` 元优化体系
- 作为 `Valkyrie` 到 `nyar` 公共语义层之间的正式前端桥接

## 适合承载什么

- `Valkyrie` 语法解析与语法树
- 名称解析、类型系统、约束检查等前端逻辑
- 语言级诊断、入口识别与前端语义建模
- 把 `Valkyrie` 语义映射到 `nyar` 可优化语义对象的前端逻辑

## 不适合承载什么

- `nyar` 核心 `OA / EGraph / PE` 基础设施本身
- 其他语言前端共享的公共协议
- 目标家族专用的运行时、编码与打包实现
- 把 `Valkyrie` 内部的私有分层直接升级为整个体系的公共契约

## 与其他项目的关系

- `projects/nyar`：提供元优化核心与公共协议
- `projects/nyar.language`：提供多语言前端组织方式
- `projects/nyar.language/source/*`：与 `bash`、`bat`、`powershell` 等前端并列存在

## 目标

- 让 `Valkyrie` 作为 `nyar` 体系上的一个前端长期演进
- 共享 `nyar` 的元优化能力，而不是把 `Valkyrie` 变成体系唯一真相
- 保持 `Valkyrie` 前端与核心元优化层分离，避免重新长出新的统一大 `IR`
