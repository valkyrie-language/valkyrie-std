# 领域扩展

Valkyrie 通过领域扩展语法支持 ECS、数据模式、异步、模板和 UI 声明等场景。

| 扩展 | 语义 | 说明 |
|:---|:---|:---|
| [ECS](ecs-extension.md) | `component`、`system`、`query`、`entity` | 实体-组件-系统，直接映射 Gnosis ECS |
| [Schema](schema-extension.md) | `class`、`structure`、`enums`、`union`、`service`、`rpc` | 数据模式定义，三维正交 What/How/Where |
| [Async](async-extension.md) | `.await`、`.awake`、`.block`、`future<T>` | 后缀式异步操作 |
| [Template](template-extension.md) | `<% ... %>` 元代码块 | 编译期模板渲染，由 Oak.DejaVu 提供词法支持 |
| [AWSL](awsl-language.md) | XML 风格声明式 UI | VOA 框架 UI 声明语言，编译为 JS 响应式组件 |