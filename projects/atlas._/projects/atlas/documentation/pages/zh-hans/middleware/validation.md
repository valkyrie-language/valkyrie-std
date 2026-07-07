# 校验

入站数据校验回答：请求是否满足契约形状与字段约束。Atlas 将其视为**请求横切**的一部分，默认叙事是进 **Middleware**（或紧贴 Controller 的入站 Adapter），而不是塞进 Wire。

## 落点

| 落点 | 适合 |
|------|------|
| **校验中间件** | 跨路由的通用规则：Content-Type、体大小、共享 DTO 形状 |
| **Controller / 入站 Adapter** | 与单一 action 强绑定的字段检查 |
| **Domain** | 业务不变量（「库存不能为负」），不是 HTTP 字段格式 |

失败时返回 `AtlasResult::bad_request(...)`（或统一错误体，见 [错误追踪](../error-tracing/errors.md)），避免把非法输入打进 Domain 编排。

## 与 OpenAPI / 契约

契约（OpenAPI）描述「允许的形状」；校验中间件 / 生成代码按契约执行。见 [OpenAPI / 契约](openapi.md)。

## 现状

框架尚未提供开箱即用的注解式校验器；扩展方式与其它横切相同——**实现中间件并挂入管道**，或在 Controller 内显式校验。方向说明见 [AOP 与中间件](aop.md)。

## 相关

- [鉴权 / 授权](auth.md)
- [请求 / 响应模型](../architecture/request-response.md)
- [路由与 Controller](../architecture/routing-and-controller.md)
