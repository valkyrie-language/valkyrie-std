# Host / `XxxHost`

**Host** 是 DAP 的**组合根角色**：挂 Domain、Wire、中间件/管线，管业务组装的生命周期。用户默认手写 **`XxxHost`**（如 `ShopHost`、`ForumHost`）；Domain / Adapter 挂在其上。

[`XxxApplication`](application.md) 按目标平台派生、很少自定义；Host 才是产品侧默认作业。总览见 [DAP 机制](dap.md)。

## 一句话

| | 要点 |
|--|------|
| **是什么** | DAP **角色 / 概念**，不是路径品牌 |
| **谁写** | 用户默认写 `XxxHost` |
| **挂什么** | Domains、Wire、管线 / 中间件选择、启停与分发生命周期 |
| **基座** | Atlas：`AtlasHost`；Asgard：`UiHost` / `WindowsUiHost` 等 |

根目录永远是**产品名**（`my_shop/`、`my_forum/`），**不要** `forum_host/`、`shop_host/`。

## 四层勿混

| 层 | 指什么 | 例子 |
|----|--------|------|
| **产品 / 工程** | 目录与交付物名 | `my_shop`、`my_forum` |
| **DAP 角色** | Host / Domain / Adapter | 组合根是 Host 角色 |
| **产品 Host 类型** | 用户写的组合根 | `ShopHost`、`ForumHost` |
| **框架基座** | Host 角色的载体 | `AtlasHost`、`UiHost` |

相对 App：用户默认只关心并手写 `XxxHost`。框架基座不是「业务不必另造 Host 类型」的借口——在 `AtlasHost` / `UiHost` 之上写产品 Host，再挂 Domain。

## 职责

| Host 里常见 | 不该塞进 Host |
|-------------|---------------|
| 读配置、Wire 组装端口 | 下单 / 发帖等用例编排 |
| 挂中间件 / 管线（产品侧选择） | 支付渠道、DB、某端 UI 控件实现 |
| 注册各 Domain 的路由或 GUI 入口 | 内核模型与业务规则 |
| 启停与请求 / 事件分发生命周期 | 「将来某 Domain 单独部署」的运维拓扑 |

```text
App（XxxApplication：按目标平台派生）
  └── XxxHost（用户写：ShopHost / ForumHost …）
        │     └── 框架基座：AtlasHost / UiHost …
        └── Domains…
              ├── 编排与模型
              └── Adapters
```

## 与 Application

| | App | Host |
|--|-----|------|
| 换自托管二进制 ↔ 边缘 serverless | 主要换壳 | **同一** `XxxHost` 尽量复用 |
| 加 `Payment` Domain / 换 Store | 不动 | 在 Host 上挂 / 改 Wire |
| 跨平台（Atlas API vs Asgard GUI） | 各自平台壳 | 仍是「产品组合根」同一角色；基座不同（`AtlasHost` vs `UiHost`） |

差别在部署入口的，写在 [App / `XxxApplication`](application.md)；差别在产品组装的，留在 Host。

## 场景

### 电商 `my_shop` → `ShopHost`

| | |
|--|--|
| 工程根 | `my_shop/`（不是 `shop_host/`） |
| 组合根 | `ShopHost`（建立在 `AtlasHost` 上） |
| Domains | `Catalog`、`Cart`、`Order`、`Payment`… |
| App | 平台派生；默认不必手写 `ShopApplication` |

下单：`ShopHost` 转发到 `OrderDomain`；端口由 Wire 注入；HTTP / 落库 / 支付实现在 Adapter。

### 论坛 `my_forum` → `ForumHost`

| | |
|--|--|
| 工程根 | `my_forum/` |
| 组合根 | `ForumHost` |
| Domains | `Thread`、`Post`、`Moderation`、`Notify`… |

发帖在 `PostDomain`；推送实现可换 mock / sink——换的是 Adapter，不是把 Host 改成「论坛上帝对象」。

### 多端 GUI `my_studio` → `StudioHost`

产品 Host 建立在 `UiHost` 等之上；端差异进平台 Adapter。Host 只组装哪些 Domain 进当前端。

## 反例：业务堆进 Host

| | 堆进 Host | DAP 形状 |
|--|-----------|----------|
| 结构 | 入口里直接写下单、发帖、权限 | Host 组合；业务在 Domain |
| 换支付 / 换端 | 入口与全局状态一起抖 | 换 Adapter |
| 测试 | 起整组合根才能测一条用例 | Domain + mock Adapter |

```text
# 不推荐
host.handle("/checkout") → 读库 → 扣库存 → 调支付 → 写订单

# 推荐
ShopHost → OrderDomain.checkout(ports)
```

## 相关

- [App / `XxxApplication`](application.md) — 平台入口壳与部署形态
- [DAP 机制](dap.md) — 三角、目录示意、一 Host 多 Domain
- [应用怎么切](history.md) — 横切 / 纵切与尺度
- [Wire](../../wire/wire.md) · [Middleware](../../middleware/index.md)
