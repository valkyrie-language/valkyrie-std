# SDK Vendor 体系

Valkyrie 的 `sdk` 体系用于承载“宿主平台 / 运行时 / 厂商 API 绑定”，并与 `std` 的跨平台抽象严格分层。它解决的问题不是“如何把某个平台硬编码进标准库”，而是“如何让官方、第三方与 vendor 在不污染 `std` 的前提下，以 zero cost 的方式提供宿主能力”。

## 设计目标

1. `std` 只保留跨平台抽象，不直接依赖 `wx.request`、`fetch`、`HttpClient` 之类宿主名称。
2. `sdk` 负责宿主绑定，允许官方维护，也允许第三方或 vendor 自行维护。
3. 绑定必须发生在编译期，而不是运行时反射、注册表或动态插件查找。
4. 第三方 `sdk vendor` 只要进入依赖闭包，就可以为 `std` 暴露的 port 提供实现。
5. 最终产物只保留静态解析后的具体调用路径，保证 zero cost。

## 主题导览

| 文档 | 说明 |
|:---|:---|
| [分层模型](layering.md) | `std`、`sdk`、vendor 包、编译器装配器的职责边界 |
| [Attrs 与 Port 机制](attrs-and-ports.md) | `[port]`、`[provides]`、底层宿主 attrs 的语义与解析规则 |
| [Manifest 与 Planner](manifest-and-planner.md) | `legion.von`、target profile、依赖闭包、provider 选择 |
| [第三方 Vendor](third-party-vendors.md) | 非官方 `sdk` 的发布、命名、冲突规则与 `wechat` 示例 |
| [Zero Cost 原则](zero-cost.md) | 编译期静态绑定、内联、死代码消除与禁止事项 |

## 一句话原则

- `std` 定义能力抽象。
- `sdk` 提供宿主实现。
- `attrs` 声明 port 与 provider 关系。
- `manifest + planner` 决定哪些 provider 在当前构建中可见。
- 编译器在符号解析期静态完成绑定。

## 为什么不是继续扩张 `std.adaptor.*`

历史上的 `std.adaptor.*` 更像“标准库里按目标硬编码的一组宿主分支”。这种做法在平台数量有限时可用，但它有四个根本问题：

1. `std` 被宿主细节污染。
2. 第三方 vendor 无法独立接入，只能等待官方改 `std`。
3. 同一 `arch` 下的不同宿主没有稳定插槽，例如 browser、Node、`wechat` 都可能落在 `wasm/js` 家族中。
4. target profile、工作区工程名、源码命名空间容易漂移，导致解析规则不一致。

因此，新的设计不再把“宿主选择”当作 `std` 的职责，而是把它提升为一套独立的 `sdk vendor` 体系。

## 最小心智模型

```text
std 抽象能力
    ↓
port 声明
    ↓
provider 声明
    ↓
planner 选择可见 provider
    ↓
编译期静态绑定
    ↓
底层宿主 attrs（js/clr/jvm/c/wasi/...）
```

## 适用场景

- 官方平台 `sdk`：例如 `.NET`、`JVM`、browser、`WASI`
- 社区 `sdk`：例如 `Node`、`Deno`、`Bun`
- vendor `sdk`：例如腾讯 `wechat`、支付宝小程序、Cloudflare Worker、Electron
- 企业内部 `sdk`：例如公司自有 runtime、网关、沙箱宿主

## 非目标

本设计不试图：

1. 在运行时动态切换 provider。
2. 提供 Java 风格 ServiceLoader / .NET 反射式插件系统。
3. 让单个二进制在运行时同时装配多套宿主能力。
4. 让 `std` 自动猜测应该选择哪个 vendor 包。

这些能力都与 zero cost 原则冲突，因此不属于本体系目标。
