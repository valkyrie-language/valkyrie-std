# CORS / 限流 / 安全头

跨域、限流与安全相关响应头属于**请求级横切**，在 Atlas 上通过 **Middleware** 进入洋葱管道，而不是 Wire 或 Domain。

## 各自做什么

| 能力 | 典型行为 |
|------|----------|
| **CORS** | 处理预检、写入 `Access-Control-*`；短路径可 `short_circuit` |
| **限流** | 按 IP / 身份 / 路由计数；超限返回 429 类 Result |
| **安全头** | `Content-Security-Policy`、`X-Content-Type-Options` 等出口头 |

它们与 [鉴权](auth.md) 常一起挂在管道外层；顺序由产品 Host / 派生 App 的默认管线决定（见 [洋葱模型](onion-model.md)）。

## 挂载

```text
→ security headers → cors → rate limit → auth → … → Router
```

（顺序可调；原则是越「协议 / 平台」越靠外，越「业务身份」越靠内。）

## 现状

内置中间件目前侧重 exception / request-log / response-log / websocket（见 `middleware_builtin.v`）。CORS、限流、安全头为**扩展点**：实现 `AtlasMiddleware` 步骤并注册进 `MiddlewarePipeline`。方向与 [AOP 与中间件](aop.md) 一致——**新中间件进管道**，不要拓展 Wire 语义去模拟这些横切。

## 相关

- [OpenAPI / 契约](openapi.md)
- [错误追踪](../error-tracing/index.md)
- [Host](../architecture/dap/host.md)
