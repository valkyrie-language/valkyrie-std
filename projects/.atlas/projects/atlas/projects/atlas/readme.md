# atlas

`atlas` 是后端 API 框架的 **纯 Valkyrie** 实现，对标 C# `Standard.Application.Server`（Olympus.Atlas）原型。

## 定位

- Web API 整合层，不绑定 ORM / 特定云厂商
- System Adapter Pattern：业务 System 与 Controller 分离
- **Wire DI**：`wire field: T` + 编译器生成 `apply_wire` + `AtlasWireContainer`
- **Middleware 管线**：`execute` 洋葱模型 + 内置 exception / request-log / response-log / websocket
- **Controller 闭环**：`AtlasHost.process` → 路由 → handler → `AtlasResult`
- **WebSocket**：帧编解码 + upgrade middleware + handler 分发
- **HTTP/TCP 宿主壳**：`serve_once` / `run` + `AtlasIoBackend`
- **部署桥接**：`AtlasRequest` → `AtlasHost.process`（独立包 `atlas.adaptor`）
- **云服务**：`atlas.cloud` + `atlas.cloud.{vendor}`（直接包装厂商 API）
- 内置横切：Logger / Cache / Queue / EventBus

## Wire DI

```valkyrie
class OrderSystem {
    wire store: OrderStore
}
```

编译器从 `is_wire` 自动生成：

```valkyrie
imply OrderSystem: AtlasWireable {
    micro apply_wire(mut self, container: AtlasWireContainer): unit {
        self.store = container.require_store("OrderStore")
    }
}
```

## 请求闭环

```text
bytes / AtlasRequest
  → parse_http_request
    → AtlasHost.process
      → MiddlewarePipeline (… → websocket → …)
        → WS upgrade: 101 + is_hijacked + handler on_connected
        → else run_terminal: Router → HandlerRegistry → AtlasResult
  → format_http_response
```

WebSocket 升级后宿主保留连接，用 `feed_ws_text` / `feed_ws_bytes`（deframer）投递消息。

## 核心概念

| 概念 | 说明 |
|------|------|
| `wire field: T` | DI 标记（declaration modifier） |
| `AtlasWireContainer` | 注册 / `require_store` / `fill_builtins` |
| `MiddlewarePipeline` | `execute` / `execute_at` 按 priority 执行 |
| `AtlasHandlerRegistry` | `handler_id` → Controller 分发 |
| `AtlasHost.process` | 业务分发核（HTTP / WS upgrade） |
| `AtlasHost.serve_once` / `run` | HTTP 字节宿主壳 |
| `WebSocketEnframer` / `Deframer` | RFC 6455 帧（服务端 unmask） |
| `AtlasWebSocketRouteTable` | path → handler_id |
| `atlas.adaptor` | 平台部署入口桥接（非云服务） |
| `atlas.cloud.*` | 云服务接口与厂商实现 |

## 与 C# 的差异

| C# | 纯 V |
|----|------|
| 反射 `[Wire]` | `wire` modifier + `WireInjector` codegen |
| `MiddlewarePipeline.execute` | 同名，index 递归 `next` |
| `WebSocketMiddleware` + socket hijack | `websocket` middleware + `is_hijacked` |
| `HttpServer` TCP | `AtlasIoBackend`（可挂接 posix / host_contract） |

## 验证

```bash
legion build projects/atlas --target nyar
legion build projects/atlas.cloud --target nyar
legion build projects/atlas.adaptor --target nyar
legion build projects/atlas.adaptor.azure --target nyar
cargo test -p nyar-language wire
```
