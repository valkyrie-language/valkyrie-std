# AOP 与中间件

**AOP（Aspect-Oriented Programming，面向切面）** 关注横切：日志、鉴权、事务、指标、超时——要在**一批调用的周围**统一织入前后逻辑。Atlas 里这类需求落在 **中间件管道**，而不是 Wire，也不是给每个业务方法套运行时代理。

## AOP 在做什么

```text
调用业务方法前 → 切面逻辑（鉴权、计时、开事务…）
    → 真正的业务方法
调用后 / 异常时 → 切面逻辑（提交/回滚、打点、统一改写错误…）
```

织入方式历史上包括：编译期字节码增强、运行时代理、中间件洋葱模型、显式装饰器。共同目标是少在每个业务方法里复制同一段 try/finally。

反射式 IoC 容器常与 AOP 捆绑（Bean 已被代理包装），容易让人以为「注入」和「切面」是同一机制。对象端口组装见 [Wire 历史](../wire/history.md)；请求横切见下文与 [洋葱模型](onion-model.md)。

## 和 Wire 的分工

| | 中间件 / AOP 落点 | Wire |
|--|-------------------|------|
| 提问 | 「这类请求/调用前后统一做什么？」 | 「这个组件依赖哪个端口实现？」 |
| 作用点 | 请求管道、调用边界 | 字段 / 对象组装 |
| 换测试策略 | 调整管道或测试用中间件 | 换 mock / sink / null |

Wire 接端口；中间件包请求。中间件需要的 logger、鉴权服务等，仍可通过 Wire 注入进中间件实现——管道 ≠ 容器。

## Atlas 里怎么落地

| AOP 常见需求 | Atlas 落点 |
|--------------|------------|
| Around / before / after 一批入口 | `MiddlewarePipeline.execute` / `execute_at`；链末 `host.run_terminal` |
| 切面注册顺序 | `AtlasMiddleware { name, priority }`；`host.use_middleware` |
| 短路 | `ctx.short_circuit` |
| 统一异常 | 内置 `exception` 中间件 |
| 请求/响应日志 | 内置 `request-log` / `response-log` |
| 协议升级 | 内置 `websocket` |
| 方法级自动代理 | **不是**默认模型；横切上提为请求中间件 |

```text
HTTP / AtlasRequest
  → MiddlewarePipeline（洋葱：日志、异常、websocket…）
      → Router → Handler
          → System 上 wire 字段已接好
```

```text
execute → execute_at(0) → … → run_terminal（业务）→ 各层返回路径
```

几何与短路见 [洋葱模型](onion-model.md)；Filter → middleware 的演化见 [从历史到中间件](history.md)。

## 刻意不做的形态

- 运行时代理包装每一个业务方法；
- 在 Wire 容器里顺带织切面；
- 用中间件代替 Wire（解决不了「字段依赖哪一个实现」）。

鉴权、CORS、限流、事务等未内置能力，方向仍是**新中间件进管道**（或更细的路由级过滤器），而不是拓展 Wire 语义去模拟 AOP。
