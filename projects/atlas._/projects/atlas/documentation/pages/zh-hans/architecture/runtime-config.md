# 运行时配置

**运行时配置**描述进程如何听端口、是否 TLS 等宿主壳参数。它属于**部署 / Application 壳**一侧的输入，不是 Domain 业务规则。

## `AtlasRuntimeConfig`

生成 / 加载对照：`config_generated.v`（`ConfigInjector` 生成物，勿手改生成文件本身）。

| 块 | 字段 | 默认（概念） |
|----|------|----------------|
| `listen` | `host`、`port` | `0.0.0.0:8080` |
| `tls` | `enabled`、`cert_path`、`key_path`、`min_version` | 默认关闭 TLS |

`validate`：端口合法；若启用 TLS 则证书与密钥路径非空。  
`tls_config`：映射到 `std.network.tls.TlsConfig`，供 `AtlasHost.run_tls` 一类入口使用。

`load_runtime_config(source)`：从配置文本装载（当前为示意级解析）；产品侧应以工具链 / 派生 App 的正式配置源为准。

## 与 App / Host 的边界

| | 运行时配置 | Host（`XxxHost`） |
|--|------------|-------------------|
| 管什么 | 听哪、TLS 否、平台壳默认参数 | Domain、Wire、产品管线、路由组装 |
| 谁消费 | 派生 `XxxApplication` / 二进制 `run`/`run_tls` | 用户手写的组合根 |
| 换 Cloudflare ↔ 自托管 | 配置与 Application 壳一起变 | 同一 Host 尽量不动 |

详见 [App](dap/application.md)、[Host](dap/host.md)。

## 二进制剖面下的典型用法

1. 装载 / 校验 `AtlasRuntimeConfig`。
2. App 派生或框架 `create_default` / `builder` 交出带 Wire / 默认中间件的 Host 基座。
3. 产品 `XxxHost` 挂 Domain 与路由。
4. `run`（明文）或 `run_tls(config.tls_config())` 长期驻留。

边缘 / serverless 剖面通常**不**由产品进程自己 `listen`；配置项随平台（绑定、密钥、环境变量）进入派生 Application，再 `process` 单次请求。见部署剖面专节。

## 相关

- [请求 / 响应模型](request-response.md)
- [错误追踪 · 日志](../error-tracing/logging-metrics-tracing.md)
