# 错误追踪

本目录讲述 **错误语义** 与 **可观测性**（日志、指标、追踪）。中间件可以挂载 exception / request-log 等步骤，但「错误如何表达、如何被看见」在这里定义。

## 文档

- [错误与 Result](errors.md)
- [日志 · 指标 · 追踪](logging-metrics-tracing.md)

## 与 Middleware 的分工

| | Middleware | 错误追踪（本目录） |
|--|------------|-------------------|
| 管什么 | 何时、以何顺序执行横切步骤 | 错误体约定、状态码、日志 / 指标 / 追踪语义 |
| 例子 | 注册 `exception`、`request-log` | `AtlasResult` 失败工厂；结构化日志字段；span 边界 |

管道总览见 [Middleware](../middleware/index.md)。
