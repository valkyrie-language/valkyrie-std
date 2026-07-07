# OpenAPI / 契约

OpenAPI（及同类 HTTP 契约）在 Atlas 文档口径里归 **Middleware / 管道侧**：描述并约束「请求如何进、响应如何出」，而不是 Domain 内核模型。

## 管什么

| 契约侧 | 业务侧 |
|--------|--------|
| 路径、方法、参数、状态码、媒体类型 | Domain 用例与规则 |
| 与路由表、校验、错误体形状对齐 | Store / 支付等 Adapter 实现 |

契约应与 [路由](../architecture/routing-and-controller.md)、[校验](validation.md)、[错误体](../error-tracing/errors.md) 一致，避免三套真相。

## 目标形状（未全部 shipping）

1. **源**：路由注册 + Controller / Result 约定，或独立契约文件。
2. **产物**：OpenAPI 文档（给客户端与网关）。
3. **运行时**：可选中间件——开发期暴露 `/openapi.json`，或按契约做入站校验。

当前仓库**没有**完整的开箱 OpenAPI 生成器；本节固定**归属与目标形状**，实现随工具链推进。扩展点仍是管道挂载 + 生成物，而不是把契约逻辑写进 Domain。

## 与 Adaptor / 多剖面

不同 Application 剖面（二进制 vs 边缘）共享同一套 HTTP 契约与同一 `XxxHost` 路由时，契约文档应描述 **Host.process 所见的 HTTP 面**，而不是某云厂商专有事件格式（厂商格式由 adaptor 翻译）。见 [App](../architecture/dap/application.md)。

## 相关

- [CORS / 限流 / 安全头](cors-rate-limit-security.md)
- [Middleware 总览](index.md)
