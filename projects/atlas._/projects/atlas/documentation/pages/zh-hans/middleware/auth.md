# 鉴权 / 授权

鉴权（你是谁）与授权（你能做什么）在 Atlas 上首先落在 **Middleware 管道**，而不是 Wire 织入或反射 AOP。

## 分工

| | 中间件 | Domain |
|--|--------|--------|
| **鉴权** | 解析凭证（Header / Cookie / 平台身份），建立调用者身份，失败则 `401` / short_circuit | 不解析原始 HTTP 凭证 |
| **授权** | 可做粗粒度关卡（是否登录、是否某角色） | 细粒度业务授权（资源归属、领域规则）可在 Domain（如 `Authz` Domain） |

DAP 示例里的 `Authz` Domain 管**业务权限边界**；管道鉴权中间件管**请求入口身份**。二者可并存，不要互相替代。

## 挂载方式（目标形状）

```text
… → auth middleware → … → Router → Controller → Domain
```

- 未通过：写 `AtlasResult::unauthorized()` / `forbidden()`，或设 `short_circuit`。
- 通过：把身份放入上下文 / Wire 可解析的端口，供 Controller / Domain 使用。

当前仓库**未内置**完整 JWT / OIDC / Session 中间件；方向是**新中间件进管道**（见 [AOP 与中间件](aop.md)），身份存储与校验实现可作为 Wire 端口替换（含测试 mock）。

## 与校验

「令牌格式是否合法」偏鉴权中间件；「业务字段是否满足规则」见 [校验](validation.md)。

## 相关

- [洋葱模型](onion-model.md)
- [错误追踪](../error-tracing/errors.md)
- [DAP](../architecture/dap/dap.md)
