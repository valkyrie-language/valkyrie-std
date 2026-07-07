# Middleware

请求进入业务 Handler 之前（以及返回之后），往往要统一做鉴权、日志、跨域、限流、协议升级、契约校验等。Atlas 用 **中间件管道**承接这类横切（AOP 在 Web 上的落点），而不是反射代理织入，也不是 Wire。

## 文档

- [从历史到中间件](history.md)
- [洋葱模型](onion-model.md)
- [AOP 与中间件](aop.md)
- [鉴权 / 授权](auth.md)
- [校验](validation.md)
- [OpenAPI / 契约](openapi.md)
- [CORS / 限流 / 安全头](cors-rate-limit-security.md)

错误体、日志、指标与追踪见 [错误追踪](../error-tracing/index.md)（管道可挂载；语义在该目录讲述）。

包内实现摘要见 [`projects/atlas/readme.md`](../../../projects/atlas/readme.md)。
