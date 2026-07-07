# Starter：第一支 API

用最小路径把 Atlas 后端跑通：**产品根 → 手写 `XxxHost` → 挂 Domain → 请求进 Host**。`XxxApplication` 按目标平台自动派生，默认不必手写。

## 你要有的形状

| 层 | 例子 | 谁写 |
|----|------|------|
| 产品 / 工程根 | `my_shop/`、`my_forum/`（不是 `shop_host/`） | 你 |
| Host | `ShopHost` / `ForumHost`（建立在 `AtlasHost` 上） | 你 |
| Domain + Adapter | `OrderDomain`、`_controllers`、`_stores` | 你 |
| App | 平台派生的 `XxxApplication` | 框架 / 工具链 |

结构指导思想见 [DAP](../architecture/dap/index.md)、[Host](../architecture/dap/host.md)、[App](../architecture/dap/application.md)。

## 请求怎么走

```text
bytes / AtlasRequest
  →（可选）平台 adaptor
    → AtlasHost.process
      → MiddlewarePipeline
        → Router（method + path → handler_id）
          → HandlerRegistry → Controller
            → AtlasResult → AtlasResponse
```

- 路由与 Controller：[routing-and-controller](../architecture/routing-and-controller.md)
- 请求 / 响应模型：[request-response](../architecture/request-response.md)
- 运行时配置（listen / TLS）：[runtime-config](../architecture/runtime-config.md)

## 最小场景：电商只读订单

示意（目录名随意，职责对齐即可）：

```text
my_shop/
  shop_host.v          # ShopHost：挂 Domain、Wire、管线
  domains/
    order/
      domain.v
      _controllers/    # 例如 GET /orders → OrdersController
      _stores/         # OrderStore 实现
```

1. 在 `ShopHost` 上注册路由：`GET /orders` → 某 `handler_id`。
2. Controller 经 Wire 拿到 `OrderStore`（或 Domain 端口），返回 `AtlasResult::ok_json(...)`。
3. 本地二进制剖面：派生 App 交出 Host 后 `run` / `serve_once`；边缘剖面走 adaptor → `process`（见 [App 部署剖面](../architecture/dap/application.md)）。

框架示例可对照包内 `OrdersController` / `HealthController` 与 `AtlasHost.process` 闭环（[`projects/atlas/readme.md`](../../../projects/atlas/readme.md)）。

## 接着读

| 主题 | 文档 |
|------|------|
| 横切管道 | [Middleware](../middleware/index.md) |
| 鉴权 / 校验 / CORS 等 | middleware 下各专页 |
| 错误与观测 | [错误追踪](../error-tracing/index.md) |
| 数据访问 | [Hermes / Query IR / UpgradePlan](../data-access/index.md) |
| Store / Cache / Queue / EventBus | [architecture 四件套](../architecture/store-cache-queue-eventbus.md)（**仅 Atlas**；Asgard 勿套同名） |
| Wire | [Wire](../wire/index.md) |
