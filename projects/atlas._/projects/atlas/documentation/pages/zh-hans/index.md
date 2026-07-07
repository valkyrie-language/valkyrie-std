# Atlas 框架文档

**Atlas** 是 Valkyrie 上的后端 Web API 框架（纯 V 实现）。CLI 入口见 [`atlas.tools`](../../../atlas.tools/readme.md)。

本目录为 Atlas 文档的 **canonical 位置**（详细讨论写在这里，包内 `readme` 只保留摘要与链接）。

## 入门

- [Starter：第一支 API](starter/index.md)

## 架构

- [DAP](architecture/dap/index.md)（Domain Adapter Pattern）
- [应用怎么切：横切、纵切与 DAP](architecture/dap/history.md)
- [DAP 机制](architecture/dap/dap.md)
- [App / `XxxApplication`](architecture/dap/application.md)（含部署剖面）
- [Host / `XxxHost`](architecture/dap/host.md)
- [路由与 Controller](architecture/routing-and-controller.md)
- [请求 / 响应模型](architecture/request-response.md)
- [运行时配置](architecture/runtime-config.md)
- [Store / Cache / Queue / EventBus](architecture/store-cache-queue-eventbus.md)（**仅 Atlas**；Asgard 勿套同名）

## 数据访问

- [总览：Hermes、绑定与升级](data-access/index.md)
- [Query IR](data-access/query-ir.md)
- [Schema Upgrade Plan](data-access/upgrade-plan.md)
- [schema 静态 query 检查](data-access/schema-static-query-check.md)
- [migrations 回放](data-access/migrations-antipattern.md)

## Wire

- [从 IoC/DI 到 Wire](wire/history.md)
- [Wire 机制](wire/wire.md)
- [非真实 Wire：mock / sink / null](wire/doubles.md)
- [Wire 与代数效应](wire/effects.md)

## Middleware

- [总览](middleware/index.md)
- [从历史到中间件](middleware/history.md)
- [洋葱模型](middleware/onion-model.md)
- [AOP 与中间件](middleware/aop.md)
- [鉴权 / 授权](middleware/auth.md)
- [校验](middleware/validation.md)
- [OpenAPI / 契约](middleware/openapi.md)
- [CORS / 限流 / 安全头](middleware/cors-rate-limit-security.md)

## 错误追踪

- [总览](error-tracing/index.md)
- [错误与 Result](error-tracing/errors.md)
- [日志 · 指标 · 追踪](error-tracing/logging-metrics-tracing.md)

## 相关

- 包实现摘要：[`projects/atlas/readme.md`](../../projects/atlas/readme.md)
- 工具链：[`atlas.tools`](../../../atlas.tools/readme.md)
