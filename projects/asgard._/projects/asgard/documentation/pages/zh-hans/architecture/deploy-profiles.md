# Deploy Profile

一次开发 ≠ 一个二进制跑全平台。正确模型：

1. **同一业务源码**（workspace 多包）
2. **按 `platform` 出制品**（Asgard/VOA 每平台一份逻辑+UI 制品；Atlas 另出服务制品）
3. **`deploy.profile` 选拓扑**（部署时选用一个或多个制品，而不是改编译语义）

## 三条流水线 / 配置面

| 面 | 配置 | 流水线 | 职责 |
|:---|:---|:---|:---|
| 客户端 GUI | `asgard.config.v` | Asgard / VOA | 按 `platform` AOT；默认 **SSG** 静态页 + hydrated 岛 |
| 服务端 | `atlas.config.von` | Atlas | HTTP / 运行时；可选 **server 岛 HTML 片段**（非 LiveView） |
| 部署拓扑 | `deploy/profiles/*.von` | 编排（CLI `asgard plan`） | 声明要构建哪些制品、如何挂载 |

Asgard/VOA ∥ Atlas：**两条独立流水线**，由 deploy profile 组合，而不是合成一个全平台二进制。

## Profile 契约（最小）

文件：`deploy/profiles/<name>.von`（VON 对象）。

| 字段 | 类型 | 说明 |
|:---|:---|:---|
| `name` | string | profile 名（与文件名一致为宜） |
| `description` | string | 人类可读说明 |
| `status` | `"implemented"` \| `"planned"` | 编排是否已落地 |
| `artifacts` | array | 制品矩阵条目 |
| `artifacts[].pipeline` | `"asgard"` \| `"atlas"` | 哪条流水线 |
| `artifacts[].platform` | string? | Asgard 侧 `platform`（`browser` / `android` / …） |
| `artifacts[].role` | string | 拓扑角色（如 `static-web`、`server-islands`） |
| `artifacts[].output` | string | 预期输出目录（相对 workspace） |
| `artifacts[].status` | string? | 覆盖条目实现状态；默认继承 profile |
| `topology` | object | 部署拓扑提示（CDN / serverless / single-host 等） |

校验规则（`asgard plan` **已实现**）：

- 根必须是对象；`name`、`artifacts` 必填
- `artifacts` 非空；每项须有 `pipeline` + `role` + `output`
- `pipeline` 仅允许 `asgard` / `atlas`
- `pipeline: asgard` 时建议提供 `platform`（缺失则警告）

编排真正调用 `asgard build` / `atlas`：**未实现**（CLI 只校验并打印矩阵）。

## 标准 profile

示例文件：[deploy/profiles/](../../../../deploy/profiles/)。

### `cdn+serverless` — 部分已实现

| 制品 | pipeline | 说明 | 状态 |
|:---|:---|:---|:---|
| 静态 Web | asgard / `browser` | SSG HTML + WASM hydrated 岛 → CDN | **implemented**（构建侧）；编排 stub |
| Server 岛 | atlas | 请求时 HTML 片段（可选） | **planned** |

拓扑：`static → cdn`，`server → serverless`。

### `portable` — planned

单一宿主进程同时提供静态资源 + Atlas（或内嵌 server 岛）。文档契约已有；**构建/打包编排后置**。

| 制品 | pipeline | 说明 | 状态 |
|:---|:---|:---|:---|
| 合并宿主 | asgard + atlas | 单进程 / 单分发包 | **planned** |

## 与「每平台唯一制品」的关系

- **平台维度**：每个 Asgard `platform` 仍是「该平台一份逻辑+UI 制品」（见 [AOT 原则](aot-principles.md)），禁止侧车 `ui.bin`。
- **部署维度**：一次发布可以包含 **多个平台制品 + Atlas 制品**；由 profile 的 `artifacts[]` 描述。
- 禁止把「多平台部署」理解成「一个二进制通吃」。

## CLI

```bash
# 校验 profile 并打印将构建的制品矩阵（不执行构建）
asgard plan --profile deploy/profiles/cdn+serverless.von

# 列出 profiles 目录
asgard plan --list examples/test.fullstack/deploy/profiles

# 也可指向 fullstack 金样例
asgard plan --profile examples/test.fullstack/deploy/profiles/cdn+serverless.von
```

金样例布局：`apps/shell`（Asgard）∥ `apps/atlas`（Atlas）∥ `packages/domain`。

## Atlas：cloud vs adaptor

部署拓扑里的 Atlas 腿不要和云厂商包装混淆：

| 包 | 职责 |
|:---|:---|
| `atlas.adaptor.*` | 部署入口桥接（平台 HTTP → `AtlasHost.process`）；与 serverless / portable 宿主相关 |
| `atlas.cloud.*` | 厂商云端口（Blob/SMS/…）；**不是** deploy profile 的「制品流水线」本身 |

## 实现状态总表

| 项 | 状态 |
|:---|:---|
| Profile VON 契约 + 示例 | **implemented** |
| `asgard plan` 校验 / `--list` / 矩阵打印 | **implemented** |
| 按矩阵编排 `asgard build` / Atlas | **planned** |
| `cdn+serverless` 静态腿 | 构建侧 **implemented**；编排 **planned** |
| `portable` 单宿主打包 | **planned** |
| `IslandKind::Server` 请求片段 | 枚举 + 客户端跳过已留位；渲染管线 **planned** |

## 相关文档

- [GUI 统一编译架构](gui-compilation.md)
- [平台 target 表](platform-targets.md)
- [Island 架构](../../../../../../../../documentation/pages/zh-hans/guides/island-architecture.md)
- [金样例 `test.fullstack`](../../../../../../../../examples/test.fullstack/readme.md)
- [`atlas.adaptor`](../../../../../../../../projects/atlas._/projects/atlas/projects/atlas.adaptor/readme.md) / [`atlas.cloud`](../../../../../../../../projects/atlas._/projects/atlas/projects/atlas.cloud/readme.md)
