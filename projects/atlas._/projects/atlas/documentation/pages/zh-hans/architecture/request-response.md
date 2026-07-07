# 请求 / 响应模型

Atlas 在 HTTP 字节与业务 Handler 之间使用稳定的请求 / 响应类型；Controller 返回 **`AtlasResult`**，再落到响应上下文。

## 核心类型

| 类型 | 命名空间 | 作用 |
|------|----------|------|
| `AtlasRequest` | `atlas.http` | method、path、headers、query、params、body；WS 相关 `connection_id` / `is_hijacked` |
| `AtlasResponse` | `atlas.http` | status_code、headers、body、content_type |
| `AtlasRouteContext` | `atlas.http` | 管道内可变上下文：request + response + short_circuit / hijack |
| `AtlasResult` | `atlas.core` | Action 统一结果；`apply_to(ctx)` 写入 response |

实现对照：`http.v`、`result.v`。

## `AtlasRequest`

常用字段：

- `method` / `path`
- `headers` / `query` / `params`（`AtlasHeaderPair` 列表）
- `body`
- WebSocket：`connection_id`、`is_hijacked`、`connection_fd`

辅助：`get_header` / `get_query` / `get_param`。

平台 adaptor（如 `atlas.adaptor`）把平台事件或原始 HTTP 变成 `AtlasRequest`，再交给 `AtlasHost.process`。

## `AtlasResult` → 响应

| 工厂 | 典型用途 |
|------|----------|
| `ok` / `ok_json` | 200 |
| `created` | 201 |
| `no_content` | 204 |
| `bad_request` | 400 |
| `unauthorized` / `forbidden` | 401 / 403 |
| `not_found` | 404 |
| `internal_error` | 500 |
| `text` | 任意状态 + text/plain |

失败体当前为简单 JSON 形 `{error:...}`（见 `error_body`）。统一错误约定与 exception 中间件见 [错误追踪](../error-tracing/errors.md)。

Controller 辅助（`controller.v`）：`ok_body` / `created_body` / `fail_body` 等薄包装。

## 管道中的上下文

中间件读写 `AtlasRouteContext`：可改 response、设 `short_circuit`、处理 WS upgrade（`is_hijacked`）。业务 Handler 最终仍以 `AtlasResult` 表达成功 / 失败语义。

```text
Request 字节
  → parse → AtlasRequest
    → process →（中间件）AtlasRouteContext
      → Controller → AtlasResult.apply_to
        → format → 响应字节
```

## 相关

- [路由与 Controller](routing-and-controller.md)
- [运行时配置](runtime-config.md)
- [App 部署剖面](dap/application.md)（adaptor 如何交出 Request）
