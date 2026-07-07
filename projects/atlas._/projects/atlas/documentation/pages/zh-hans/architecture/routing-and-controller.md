# 路由与 Controller

Atlas 用**显式路由表** + **handler_id** 分发到 Controller，不做反射扫描程序集。

## 闭环

```text
AtlasRequest (method, path)
  → AtlasRouter.match_route
    → handler_id + path params
      → AtlasHandlerRegistry.invoke
        →（编译期）atlas_invoke_handler
          → Controller action → AtlasResult
```

实现对照：`router.v`、`handler_registry.v`、`routes_generated.v`、示例 `OrdersController` / `HealthController`。

## 路由

`AtlasRouter` 注册 `method + path → handler_id`：

| API | 含义 |
|-----|------|
| `map` / `get` / `post` / `put_route` / `delete_route` | 注册一条路由 |
| `match_route` | 匹配；支持路径段参数（pattern 与实际 path 分段对齐） |

路径参数进入 `AtlasRequest.params`（匹配时 `extract_params`）。未命中则业务侧通常落到 404（由宿主 / Result 约定处理）。

产品侧常见做法：在 `XxxHost`（或生成的 `atlas_register_routes`）里把各 Domain 的 HTTP 入口挂上，而不是在 Application 里堆业务路由。

## Handler 与 Controller

- **handler_id**：稳定字符串键，注册进 `AtlasHandlerRegistry`。
- **Controller**：入站 Adapter；从 Wire 容器取 Domain / Store，返回 [`AtlasResult`](request-response.md)。
- **wire**：Controller 可提供 `wire(container)`，在分发前接好依赖（见 [Wire](../wire/wire.md)）。

示例（概念对齐包内订单 Controller）：

```text
GET /orders  →  handler_id "orders.get"
                 → OrdersController.get_orders
                 → 检查 OrderStore 是否就绪
                 → AtlasResult::ok_json(...)
```

健康检查同理：`HealthController` 提供 live / ready 一类 action，仍走同一套路由 → handler → Result。

## 与 DAP

| 角色 | 路由 / Controller 落点 |
|------|------------------------|
| **Host** | 注册路由、挂管线、持有 registry |
| **Domain** | 用例编排；不直接解析 HTTP |
| **Adapter** | `_controllers` 把 HTTP 转成 Domain 调用；`_stores` 等出站 |

详见 [DAP 机制](dap/dap.md)、[Host](dap/host.md)。

## 相关

- [请求 / 响应模型](request-response.md)
- [Starter](../starter/index.md)
- [Middleware](../middleware/index.md)
