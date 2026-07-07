# atlas

`atlas` 是后端 API 框架的 **纯 Valkyrie** 实现，对标 C# `Standard.Application.Server`（Olympus.Atlas）原型。

## 定位

- Web API 整合层，不内嵌某一种 ORM 运行时、不绑定特定云厂商
- **DAP（Domain Adapter Pattern）**：业务 **Domain** 与 Adapter 分离（低耦合、高内聚；横切/纵切皆可，非强制）。见 [DAP](../../documentation/pages/zh-hans/architecture/dap/index.md)、[历史脉络](../../documentation/pages/zh-hans/architecture/dap/history.md)、[DAP 机制](../../documentation/pages/zh-hans/architecture/dap/dap.md)、[App](../../documentation/pages/zh-hans/architecture/dap/application.md)、[Host](../../documentation/pages/zh-hans/architecture/dap/host.md)。
- **Wire**：`wire field: T` + 编译器生成 `apply_wire` + `AtlasWireContainer`（见 [Wire 文档](../../documentation/pages/zh-hans/wire/index.md)）
- **Middleware 管线**：`execute` 洋葱模型 + 内置 exception / request-log / response-log / websocket（见 [Middleware 文档](../../documentation/pages/zh-hans/middleware/index.md)）
- **Controller 闭环**：`AtlasHost.process` → 路由 → handler → `AtlasResult`（见 [路由与 Controller](../../documentation/pages/zh-hans/architecture/routing-and-controller.md)、[请求 / 响应](../../documentation/pages/zh-hans/architecture/request-response.md)）
- **WebSocket**：帧编解码 + upgrade middleware + handler 分发
- **HTTP/TCP 宿主壳**：`serve_once` / `run` + `AtlasIoBackend`（运行时配置见 [runtime-config](../../documentation/pages/zh-hans/architecture/runtime-config.md)）
- **部署桥接**：`AtlasRequest` → `AtlasHost.process`（独立包 `atlas.adaptor`；剖面见 [App](../../documentation/pages/zh-hans/architecture/dap/application.md)）
- **云服务**：`atlas.cloud` + `atlas.cloud.{vendor}`（直接包装厂商 API；**不是**部署入口）
- **Store / Cache / Queue / EventBus**：Atlas Wire 内置横切与持久化端口——见 [专页](../../documentation/pages/zh-hans/architecture/store-cache-queue-eventbus.md)。**Asgard 不得套用同名指同一套类型。**
- 入门：[Starter](../../documentation/pages/zh-hans/starter/index.md)；错误与观测：[错误追踪](../../documentation/pages/zh-hans/error-tracing/index.md)

## 数据访问

Atlas **不绑**某一种 ORM 运行时；不做 **migrations-first** ORM。  
**Hermes** = schema 真源 + 默认 query 语言（**SQL 亦可**）；库为 MySQL / PostgreSQL / SQLite；**与 yyds 无关**。  
升级：目标 vs 当前 → **UpgradePlan** → 有限编辑 → 一次性 Apply（**不是** migrations 回放）。

详细讨论（canonical）：

- [数据访问总览](../../documentation/pages/zh-hans/data-access/index.md)
- [Query IR](../../documentation/pages/zh-hans/data-access/query-ir.md)
- [Schema Upgrade Plan](../../documentation/pages/zh-hans/data-access/upgrade-plan.md)
- [schema 静态 query 检查](../../documentation/pages/zh-hans/data-access/schema-static-query-check.md)
- [migrations 回放](../../documentation/pages/zh-hans/data-access/migrations-antipattern.md)

工具入口见 [`atlas.tools`](../../../atlas.tools/readme.md)。

## Wire

**Wire**（实现 DI / IoC 的产品机制）：`wire field: T` + 编译器生成 `apply_wire` + `AtlasWireContainer`。  
从 IoC/DI 到 Wire 的说明见：

- [从 IoC/DI 到 Wire](../../documentation/pages/zh-hans/wire/history.md)
- [Wire 机制](../../documentation/pages/zh-hans/wire/wire.md)
- [非真实 Wire：mock / sink / null](../../documentation/pages/zh-hans/wire/doubles.md)
- [Wire 与代数效应](../../documentation/pages/zh-hans/wire/effects.md)
- [Middleware · AOP](../../documentation/pages/zh-hans/middleware/aop.md)

```valkyrie
class OrderSystem {
    wire store: OrderStore
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
| `wire field: T` | Wire 依赖声明（见 [Wire 机制](../../documentation/pages/zh-hans/wire/wire.md)） |
| `AtlasWireContainer` | Wire 容器：注册 / `require_store` / `fill_builtins` |
| `MiddlewarePipeline` | 请求级洋葱管道（见 [Middleware 文档](../../documentation/pages/zh-hans/middleware/index.md)） |
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
