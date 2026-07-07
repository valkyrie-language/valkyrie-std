# App / `XxxApplication`

**App（`XxxApplication`）** 是按**目标平台 / 部署形态**自动派生的入口壳：进程或 isolate 怎么起来、平台怎么把控制权交给组合根、该部署目标下有哪些默认接线。用户**很少自定义**；默认作业是写 [`XxxHost`](host.md)。

总览与三角落地见 [DAP 机制](dap.md)。

## 一句话

| | 要点 |
|--|------|
| **是什么** | 平台入口壳，不是产品业务组合根 |
| **谁写** | 框架 / 工具链按目标平台派生；手写覆盖是例外 |
| **管什么** | 启动、平台交接、该部署目标的默认 Wire / 中间件壳、**拼出并交出** Host |
| **不管什么** | Domain 编排、业务 Wire 组装、产品管线选择——那些在 Host |

## 与 Host 的分工

| | **App（`XxxApplication`）** | **Host（`XxxHost`）** |
|--|----------------------------|------------------------|
| 默认 | 按目标平台自动派生 | 用户手写产品组合根 |
| 差异来源 | **部署形态 / 平台运行时** | **产品组装**（Domain、Wire、管线） |
| 换 Cloudflare ↔ 自托管二进制 | 主要换 Application（及平台桥） | 同一 `ShopHost` / `ForumHost` 尽量复用 |
| 换支付渠道 / 加版块 | 不动 | 换 Adapter / 挂新 Domain |

同一产品 Host 可被**不同** Application 交出；二进制 server 与边缘 serverless 的差别，主要落在 Application 层与平台运行时，而不是重写 Domain。

## 部署剖面

部署形态不同，派生出的 Application 壳不同——**目标平台决定壳，不决定业务边界怎么切**。

### 总表

| 部署形态 | Application 壳大致做什么 | 进程 / 生命周期 | 对照 |
|----------|--------------------------|-----------------|------|
| **单一二进制 server** | 读参数与[运行时配置](../runtime-config.md)、装默认中间件 / Wire、`listen` / `accept`，把请求交给 Host | 自托管；进程内**长期驻留** | `create_default` / `builder` → `AtlasHost`，再 `run` / `serve_once` / `run_tls`（`app.v` / `host.v`） |
| **边缘 / 无服务器容器**（如 Cloudflare Workers 一类） | 适配平台托管入口：按请求或短生命周期拉起，把平台事件桥成 Host 可处理的请求 | 平台托管；**按请求 / isolate 短驻留** | `atlas.adaptor.*`：平台 HTTP → `AtlasHost.process`；Cloudflare 等是否出箱即用，以当前 adaptor / deploy profile 为准——**勿当成已全部 shipping** |
| **GUI 桌面 / 多端**（Asgard） | 按 `platform` 派生窗口 / 运行时入口，交出建立在 `UiHost` 等之上的产品 Host | 随端生命周期 | 与 Atlas API 不同流水线；见 Asgard Deploy Profile |

### 剖面 A：单一二进制 server

操作向要点：

1. 装载并校验 `AtlasRuntimeConfig`（listen / TLS）。见 [运行时配置](../runtime-config.md)。
2. 派生 App（或框架对照 `create_default`）交出 Host **基座**；产品 `XxxHost` 挂 Domain、路由、产品管线。
3. `run`：明文 TCP/HTTP 循环；`run_tls`：证书来自配置。
4. 每个接受的连接：解析字节 → `AtlasRequest` → `process` → 格式化响应（见 [请求 / 响应](../request-response.md)）。
5. 进程不退出则 Host 与 Wire 容器长期存活；Cache / Queue / EventBus 等内存实现的生命周期与进程一致。

适合：自托管 VM / 容器里跑一个常驻 API 进程。

### 剖面 B：边缘 / serverless 容器（含 Cloudflare 类）

操作向要点：

1. **没有**产品侧长期 `listen`；由平台在事件到达时拉起 isolate / 实例。
2. Application 壳（adaptor）把平台请求翻译成 `AtlasRequest`（或原始 HTTP 字节经 `process_http`）。
3. 调用**同一**产品 Host 的 `process`（或等价入口），得到 `AtlasResponse`，再映射回平台响应。
4. 实例可能随请求结束而销毁：勿在 Domain 里假设进程内 Queue / 内存 Cache 跨请求一定还在——跨请求状态进 Store / 外部缓存。

适合：按请求计费、由云平台托管入口的 API。具体厂商包（如已有 `atlas.adaptor.azure`）以仓库为准；Cloudflare 等按 profile 增量交付。

### 剖面对照：同一 `ShopHost`

```text
# 自托管二进制
ShopApplication_binary  →  listen/accept（长期）  →  ShopHost.process  →  OrderDomain…

# 边缘 serverless（示意；以实际平台壳为准）
ShopApplication_edge    →  平台入口（短生命周期） →  同一 ShopHost.process  →  同一 OrderDomain…
```

### 换剖面检查清单

| 检查项 | 二进制 | 边缘 / serverless |
|--------|--------|-------------------|
| 谁 `listen` | Application / Host 壳 | 平台 |
| 配置从哪来 | 文件 / 参数 / `AtlasRuntimeConfig` | 平台绑定、密钥、环境 |
| 同一 `XxxHost` 可复用吗 | 是 | 是（目标） |
| Domain / Store 要不要为换云重写 | 否 | 否；只换 adaptor / App 壳 |
| 内存 Queue / Cache 跨请求 | 进程内可用 | 不可假设；外置 |

### Adaptor

| 包 | 职责 |
|----|------|
| `atlas.adaptor` | `process_request`：`AtlasRequest` → `AtlasHost.process` → `AtlasResponse`；`process_http`：原始字节 |
| `atlas.adaptor.azure` 等 | 厂商运行时 → 上述薄桥 |
| `atlas.cloud.*` | **云服务 API**（存储 / 短信等），**不是**部署入口壳 |

Adaptor **不含** VOA 概念，也不替代 Host 上的业务组装。

## 框架对照（不是「每个产品手写 App」）

| 框架 | 对照物 | 说明 |
|------|--------|------|
| Atlas | `app.v` 的 `AtlasApp`：`create_default` / `builder` **返回** `AtlasHost` | 演示框架如何交出 Host **基座**；不是教每个 `my_forum` 都写 `ForumApplication` |
| Atlas 部署桥 | `atlas.adaptor` / `atlas.adaptor.azure` 等 | 见上节 |
| Asgard | 按 `platform` 的入口壳 + `UiHost` 等 | GUI 制品矩阵；产品侧仍写 `StudioHost` 一类 `XxxHost` |

业务工程默认：**不**自建 / 不改 `ForumApplication`；有平台默认壳即可。手写覆盖 App（特殊启动参数、非默认平台壳）是**例外路径**。

## 反例

| 不推荐 | 推荐 |
|--------|------|
| 每个产品手写一份 `XxxApplication` 当默认作业 | 写 `XxxHost`；App 交给平台派生 |
| 把 Domain / 支付规则写进 Application | 业务在 Domain；组装在 Host |
| 为换 Cloudflare / 自托管去改 `OrderDomain` | 换 Application / 平台桥；Host 与 Domain 尽量不动 |
| 把根目录叫 `shop_application/` | 根目录仍是产品名（`my_shop/`） |

## 相关

- [Host / `XxxHost`](host.md) — 用户默认手写的组合根
- [DAP 机制](dap.md) — 三角与目录示意
- [应用怎么切](history.md) — 横切 / 纵切与尺度
- [运行时配置](../runtime-config.md) · [请求 / 响应](../request-response.md)
