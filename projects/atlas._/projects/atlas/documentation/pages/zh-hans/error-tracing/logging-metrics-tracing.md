# 日志 · 指标 · 追踪

错误要能**被看见**：同一套「错误追踪」叙事下，日志、指标与分布式追踪互补。管道里的 `request-log` / `response-log` 是挂载点；字段与语义在本页约定。

## 日志

| 来源 | 现状 |
|------|------|
| `ConsoleAtlasSystemLogger` | 系统内置 Logger（`systems.v`） |
| `request-log` 中间件 | 记录 method + path |
| `response-log` 中间件 | 下游完成后记一条完成日志 |

目标形状：结构化字段（request id、路由、状态码、耗时、错误码），与 [错误与 Result](errors.md) 的 envelope 可互指。产品可通过自定义中间件替换或增强内置 log 步骤。

## 指标

对标常见后端：请求计数、延迟直方图、错误率、按路由 / 状态码维度。Atlas **尚未**内置 metrics 导出；扩展方式仍是中间件或 Host 生命周期钩子采集，再推到外部系统。不要把指标采集写进 Domain 用例。

## 追踪

目标形状：每个入站请求一个根 span；中间件边界与 Domain 调用可嵌套子 span；错误 Result 带上 trace / span id 便于与日志关联。当前无完整 tracing SDK 绑定；文档固定**归属在错误追踪目录**，实现随观测栈推进。

## 与 Middleware

```text
request-log → … →（业务）→ … → response-log
exception 包裹下游，统一 5xx 外观
```

观测**语义**（记什么、如何关联错误）在本目录；**是否挂载、顺序**在 [Middleware](../middleware/index.md)。

## Asgard

GUI 侧的帧耗时、渲染诊断**不是** Atlas 的 request-log / EventBus / Logger 同款叙事。勿把本页的 Atlas 观测类型名套到 Asgard。

## 相关

- [错误与 Result](errors.md)
- [Store / Cache / Queue / EventBus](../architecture/store-cache-queue-eventbus.md)（Atlas 专有；与观测无关勿混名）
