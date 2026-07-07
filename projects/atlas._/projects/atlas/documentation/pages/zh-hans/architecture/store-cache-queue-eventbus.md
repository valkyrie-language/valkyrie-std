# Store / Cache / Queue / EventBus

这四个词是 **Atlas 后端** 在 Wire 容器上的运行时端口 / 内置横切。**Asgard（GUI）不得用同一套名字指同一套类型**——两边概念严格分开。

实现对照：`systems.v`、`wire.v`、`app.v` 默认 `use_cache` / `use_queue` / `use_event_bus`；Store 示例 `OrderStore` + `register_store` / `require_store`。

## 硬切：Atlas vs Asgard

| 概念 | Atlas | Asgard |
|------|-------|--------|
| **Store** | Domain 持久化**端口 / Adapter**（如 `OrderStore`）；经 Wire 注入 | **不用此名**指 Atlas 那套；GUI 状态与平台持久化另叙事，禁止把 UI 状态叫成 Store 混进 Atlas 文档 |
| **Cache** | `MemoryAtlasCache` 等键值横切，挂在 `AtlasWireContainer` | **非** `AtlasCache`；禁止把帧缓存 / 资源缓存叫成 Atlas Cache |
| **Queue** | `MemoryAtlasQueue` 后台投递 | **非** Atlas Queue |
| **EventBus** | `InMemoryAtlasEventBus` 进程内事件 | **非** Atlas EventBus；UI 事件 / 输入事件另论 |

一句话：**同名不同世界**。写 Asgard 文档与示例时，不要盗用 Store / Cache / Queue / EventBus 来指 Atlas 的 Wire 内置类型。

## Atlas：各自干什么

| | 职责 | 典型落点 |
|--|------|----------|
| **Store** | 「这块业务数据怎么读写」的端口；实现可换 DB / 内存 / mock | Domain 的 `wire store: T`；`_stores/` Adapter |
| **Cache** | 短生命周期或热点数据的键值缓存 | 容器 `use_cache`；业务按需读取 |
| **Queue** | 异步投递 / 后台任务入口（内存实现为示意） | 容器 `use_queue` |
| **EventBus** | 进程内发布 / 订阅 | 容器 `use_event_bus` |

Store 属于 **DAP Adapter 面**（可替换接缝）；Cache / Queue / EventBus 是框架提供的**横切基础设施**，默认可由 App 壳装进容器，产品 Host 再决定 Domain 是否依赖它们。

## 与数据访问

- **Hermes / Query IR / UpgradePlan**：schema 与查询真源、升级计划——见 [data-access](../data-access/index.md)。
- **Store**：业务端口形状；具体是否经 Hermes 查库由 Adapter 实现决定，不要把 Store 与「migrations 回放 ORM」混为一谈。

## 测试替身

Wire 的 mock / sink / null 适用于端口替换（含 Store）。见 [非真实 Wire](../wire/doubles.md)。

## 相关

- [Wire](../wire/wire.md)
- [DAP · Adapter](dap/dap.md)
- [Host](dap/host.md)
