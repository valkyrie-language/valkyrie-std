# 错误与 Result

业务与管道应通过 **`AtlasResult`**（及写入后的 `AtlasResponse`）表达失败，而不是让未捕获异常泄漏成无结构的连接断开。

## 状态码与工厂

| 工厂 | 码 | 说明 |
|------|----|------|
| `bad_request` | 400 | 入站不合法（常与[校验](../middleware/validation.md)一起） |
| `unauthorized` | 401 | 未认证 |
| `forbidden` | 403 | 已认证但无权限 |
| `not_found` | 404 | 路由或资源不存在 |
| `internal_error` | 500 | 未预期失败 |
| 成功态 | 200 / 201 / 204 | `ok` / `ok_json` / `created` / `no_content` |

实现对照：`result.v` 中 `error_body` 目前写入简单 JSON 形 `{error:...}`。产品可在此约定上收敛统一错误 envelope（字段名、错误码、追踪 id），并与 [OpenAPI](../middleware/openapi.md) 对齐。

## Exception 中间件

内置 `exception` 步骤（`middleware_builtin.v`）：在下游执行后，若 `status_code >= 500`，则用 `AtlasResult::internal_error()` 覆盖响应，避免把原始 5xx 细节无约束地透出。

它**不替代**业务显式返回的 `bad_request` / `unauthorized`；那些应在 Controller / 鉴权中间件里主动构造。

## 推荐约定

1. Domain 返回领域错误 → Controller 映射为合适的 `AtlasResult`。
2. 管道鉴权 / 校验失败 → 直接 Result，short_circuit。
3. 真正未预期 → 交给 exception 中间件与[日志 / 追踪](logging-metrics-tracing.md)，对外统一 500 体。

## 相关

- [请求 / 响应模型](../architecture/request-response.md)
- [日志 · 指标 · 追踪](logging-metrics-tracing.md)
