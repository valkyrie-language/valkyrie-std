# DAP 机制

**DAP（Domain Adapter Pattern）** 用三个角色收口应用结构：Domain、Adapter、Host。它是组织代码的**指导思想与推荐形状**，不是部署拓扑规定，也不是禁止横切共享。

相对 [应用怎么切：横切、纵切与 DAP](history.md)：切法讨论几何与尺度；本文写三角如何落地，并用熟悉场景举例。

## 三层用语，勿混

| 层 | 指什么 | 例子 |
|----|--------|------|
| **产品 / 工程** | 目录与交付物名 | `my_shop`、`my_forum`、`my_cms`、`my_studio` |
| **DAP 角色** | 概念：谁干什么 | Host / Domain / Adapter（**Host ≠ 路径后缀**） |
| **框架类型** | Host 角色的基座 / 载体 | Atlas：`AtlasHost`；Asgard：`UiHost` / `WindowsUiHost` 等 |

另有一层常被误当成「每个产品都要手写」的东西：**App（`XxxApplication`）**——详见 [App](application.md) / [Host](host.md)，摘要见下节。它按目标平台**自动派生**，很少需要用户自定义；不要把它和 Host 角色、产品根目录混为一谈。

产品名是根；Host 是角色。相对 App 而言，用户默认只需要关心并手写产品侧的 **`XxxHost`**（如 `ShopHost`、`ForumHost`、`CmsHost`），通常建立在框架的 `AtlasHost` / `UiHost` 之上——后者是基座 / 载体，不是「业务不必另造 Host 类型」的借口。四者不要互相当同义词。

## Host 与 App

| | **App（`XxxApplication`）** | **Host（组合根 / DAP 角色）** |
|--|----------------------------|-------------------------------|
| 默认形态 | 按目标平台**自动派生**；很少需要用户自定义 | 运行期组合根：挂 Domain、Wire、管线、生命周期 |
| 业务侧关心吗 | **通常不**；手写 / 覆盖 App 是例外 | **是**：用户默认写 **`XxxHost`**（如 `ShopHost`、`ForumHost`）；Domain / Adapter 挂在其上 |
| 做什么 | 平台入口壳：启动期读参数、装默认中间件 / Wire、注册路由或 GUI，**拼出并交出**组合根 | 持有 Wire、管线、已挂载 Domain，以及启停与请求分发生命周期 |
| Atlas（框架对照） | 仓库里 `app.v` 的 `AtlasApp`：`create_default` / `builder` **返回** `AtlasHost`——这是**框架如何交出 Host 基座**的对照，不是「每个 `my_forum` 都手写一份 App」 | 框架基座是 `AtlasHost`；产品侧在其上写 `ShopHost` / `ForumHost` 等，挂 Domain 与业务组装 |
| 业务工程 | 一般不自建 / 不改 `ForumApplication`；有平台默认即可 | **手写** `ForumHost`、`ShopHost`…；以框架 `AtlasHost` / `UiHost` 为载体，而不是去定制 App |

一句话：**App（`XxxApplication`）按目标平台自动派生、很少自定义；用户默认写 `XxxHost`。** Domain / Adapter 当然也要写，但挂载与 Wire / 管线组装发生在用户的 `XxxHost` 上——不要再教「不必写 `XxxHost`、直接用 `AtlasHost` 就行」。这是职责划分，不是文件夹必须叫 `xxx_host`——根目录仍是产品名（`my_shop/`、`my_forum/`）。

部署形态（单一二进制 server vs 边缘 / serverless 等）如何落在 Application 壳上，见 [App / `XxxApplication`](application.md)；组合根职责与目录约定见 [Host / `XxxHost`](host.md)。

手写自定义 App / 产品侧覆盖 `XxxApplication` 属于**例外路径**（例如特殊启动参数、非默认平台壳），不要当成每个产品的默认作业。

## 三角角色

| 角色 | 含义 | 典型落点 |
|------|------|----------|
| **Domain** | 一块完整业务（或 GUI 能力）边界：编排与内核模型 | `OrderDomain`、`CatalogDomain`、`EditorDomain` |
| **Adapter** | 对 HTTP、DB、云厂商、平台 UI 等的接缝；默认可替换（含 mock / sink / null） | `_controllers`、`_stores`、平台控件包装 |
| **Host** | 组合根角色：配置、Wire、中间件/管线、生命周期 | 产品侧 `ShopHost` / `ForumHost`…；框架基座 `AtlasHost` / Asgard `UiHost` |

```text
App（XxxApplication：按目标平台自动派生，很少自定义）
  └── Host（角色：组合根；用户写 XxxHost，如 ShopHost / ForumHost）
        │     └── 框架基座：AtlasHost / UiHost …
        └── Domains…          ← 业务边界
              ├── 编排与模型（内核）
              └── Adapters（_controllers / _stores / 平台适配…）
```

- **Atlas**：HTTP API 上的 Domain + Adapter（路由进 Controller，持久化进 Store）；产品侧写 `ShopHost` / `ForumHost` 等，建立在 `AtlasHost` 之上。框架侧可用 `create_default` / `builder` 对照「如何交出 `AtlasHost` 基座」。
- **Asgard**：GUI / 多端能力按 Domain 收口，Win / Web / 移动等平台差异进 Adapter；产品侧 Host 建立在 `UiHost` 等之上。

命名可用 `XxxDomain`、`domains/xxx/`；组合根命名可用 `XxxHost`。横切共享库、统一中间件管道都可以存在；纵切 Domain 只是常见默认，不是唯一合法形状（详见 history）。

## 一 Host 挂多个 Domain

一个进程 / 一个入口通常只对应一个 Host 角色实例（由平台默认 App 交出，或例外时由自定义 App 拼出）；Host 负责把多个 Domain 装起来，而不是自己实现业务。

| 场景 | 产品 / 工程 | 组合根（用户写） | 框架基座 | Domains（示例） |
|------|-------------|------------------|----------|-----------------|
| 电商 API（Atlas） | `my_shop` | `ShopHost` | `AtlasHost` | `Catalog`、`Cart`、`Order`、`Payment`、`Account` |
| 论坛 API（Atlas） | `my_forum` | `ForumHost` | `AtlasHost` | `Thread`、`Post`、`Moderation`、`Notify` |
| 后台 CMS（Atlas） | `my_cms` | `CmsHost` | `AtlasHost` | `Content`、`Media`、`Authz`、`Audit` |
| 多端 GUI（Asgard） | `my_studio` | `StudioHost` | `UiHost` 等 | `Shell`、`Editor`、`Inspector`、`Settings` |

Host 角色里常见内容：读配置、Wire 组装端口、挂中间件/管线、注册各 Domain 的路由或 GUI 入口、启停生命周期。

Domain 里常见内容：用例编排、内核模型与规则、对外端口定义（「需要什么能力」）。

Adapter 里常见内容：HTTP handler、DB/对象存储实现、第三方支付/短信、某端 UI 控件——以及测试用的 mock / sink / null。

## 目录形状（示意）

根目录永远是**产品名**（`my_shop/`、`my_forum/`…），**不要** `forum_host/`、`shop_host/` 这类路径。以下只是示意，不是强制规范。

默认作业是手写 **`XxxHost`**（产品侧组合根），并在其上挂 **Domain / Adapter**；**不必**为每个产品手写 / 定制 `XxxApplication`（App 由目标平台派生）。框架的 `AtlasHost` / `UiHost` 是基座，不是替代用户 `XxxHost` 的默认答案。入口文件若出现，表示组合根挂载点或例外时的引导壳；**不必**出现 `host.v` 路径后缀，更不要据此以为必须 `*_host/` 目录。

### 电商（Atlas HTTP API）

```text
my_shop/
  shop_host.v             # ShopHost：挂 Domain、Wire、管线（建立在 AtlasHost 上）
  domains/
    catalog/
      domain.v            # 上架、检索、定价规则
      _controllers/       # GET /products …
      _stores/            # 商品表 / 搜索索引
    cart/
      domain.v
      _controllers/
      _stores/
    order/
      domain.v            # 下单、状态机
      _controllers/
      _stores/
    payment/
      domain.v
      _controllers/
      _stores/            # 支付渠道 Adapter（可换 mock）
  # App（XxxApplication）按目标平台自动派生——默认不必手写
```

场景一瞥：

- 下单：`OrderDomain` 编排库存校验与建单；HTTP 进 `_controllers`；落库进 `_stores`；调支付走 `Payment` 端口（实现可替换）。
- 换支付渠道：改 `payment` 的 Adapter，不改 `OrderDomain` 内核。
- 组装：在 `ShopHost` 上挂上述 Domain（组合根）；不必去定制 `ShopApplication`。

### 论坛（Atlas HTTP API）

```text
my_forum/
  forum_host.v            # ForumHost：组合根（建立在 AtlasHost 上）
  domains/
    thread/               # 版块、主题
    post/                 # 发帖、回复
    moderation/           # 举报、封禁
    notify/               # 站内信 / 推送 Adapter
  # App 按目标平台自动派生；根目录是 my_forum/，不是 forum_host/
```

- 发帖：`PostDomain` 写内容并触发 `Notify` 端口；推送实现（邮件 / 站内 / sink）是 Adapter。
- 审核：`ModerationDomain` 独立边界，不必塞进 `Post` 的 Store 细节里。
- 组装：在 `ForumHost` 上挂 Domain；不必手写 `ForumApplication`。

### 后台 CMS（Atlas，可选对照）

```text
my_cms/
  cms_host.v              # CmsHost
  domains/
    content/              # 草稿、发布流
    media/                # 上传、CDN Adapter
    authz/                # 角色与资源权限
    audit/                # 操作审计
```

内容发布与权限、审计分 Domain；对象存储 / CDN 差异留在 `media` 的 Adapter。

### 多端 GUI（Asgard）

```text
my_studio/
  studio_host.v           # StudioHost（建立在 UiHost 等之上）
  domains/
    shell/                # 窗体、导航壳
    editor/               # 编辑能力（内核与快捷键等）
      _adapters/
        win/
        web/
    inspector/
    settings/
  # App 按目标平台自动派生——默认不必手写
```

- 同一 `EditorDomain` 内核；Win / Web 控件与快捷键映射进平台 Adapter。
- Host（如 `StudioHost`）只组装哪些 Domain 进当前端，不把编辑规则写进组合根。

## 反例：业务堆进 Host

| | 堆进 Host | DAP 形状 |
|--|-----------|----------|
| 结构 | 组合根里直接写下单、发帖、权限、渲染 | Host 组合；业务在各自 Domain |
| 改支付 / 换端 | 入口文件与全局状态一起抖 | 换对应 Adapter；内核与其它 Domain 少动 |
| 测试 | 起整组合根才能测一条用例 | Domain + mock Adapter 单测 |
| 协作 | 所有人挤同一入口 | 按 Domain 目录并行 |

短例（电商下单）：

```text
# 不推荐：Host 角色内联一切
host.handle("/checkout") → 读库 → 扣库存 → 调支付 → 写订单 → 发邮件

# 推荐：Host 只转发到 Domain
ShopHost → OrderDomain.checkout(ports)
           ports.catalog / ports.payment / ports.mail   # Wire 注入的 Adapter
```

「将来某 Domain 单独部署」是部署决策，不是写成 Domain 的前提。

## 与 Wire、Middleware

| 概念 | 管什么 |
|------|--------|
| **Wire** | 端口怎么注入（Domain 要的能力 ↔ 具体 Adapter） |
| **Middleware** | 请求级横切（鉴权、日志、限流等管线） |
| **DAP** | 代码按什么业务 / 能力边界收口 |

请求几何（中间件）与业务几何（Domain）可并存：例如统一鉴权中间件挂在 Host 管线，下单规则仍在 `OrderDomain`。细节见各自专题文档，此处不展开。

## 指导思想，非强制规定

推荐默认（可偏离，评审里说清即可）：

- 新业务优先独立 Domain，而不是堆进 Host 角色；
- Adapter 与内核分离，便于测试替身；
- App（`XxxApplication`）按目标平台自动派生，很少自定义；用户默认写 `XxxHost`，并在其上挂 Domain / Adapter（相对 App，只需要关心 Host）；
- 不为「模块化」强行拆多进程；将来某 Domain 独立部署是部署决策，不是 DAP 前提；
- Host / Domain / Adapter 是角色，不是强制路径命名；根目录用产品名（`my_shop/`…）；产品侧写 `ShopHost` / `ForumHost` 等，框架 `AtlasHost` / `UiHost` 只是基座 / 载体。

目标是可维护、可测试、职责清楚，不是制造分布式复杂度，也不是禁止横切共享库。
