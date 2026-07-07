# 洋葱模型

## 什么是洋葱模型

**洋葱模型**描述多层中间件嵌套时，请求与响应如何穿行：

- **向内**：从最外层中间件走到最内层（最终常是路由后的业务 Handler）；
- **向外**：业务结束（或中途短路）后，再按相反顺序经过各层的「离开」逻辑。

每一层在调用内层（`next`）**之前**做进入手续，在 `next` **返回之后**做离开手续——因此计时、事务、日志开关可以写在同一个中间件函数里，成对出现。

```text
请求 ──► A 进入 ──► B 进入 ──► C 进入 ──► Handler
响应 ◄── A 离开 ◄── B 离开 ◄── C 离开 ◄── Handler
```

若在 B 进入后短路（不调用更内层）：

```text
请求 ──► A 进入 ──► B 进入（决定不 next）
响应 ◄── A 离开 ◄── B 离开
```

A 仍然会离开；C 与 Handler 不会执行。这正是鉴权失败、限流拒绝时的常见形状。

## 和「纯 before 列表」的差别

只注册一串 `onRequest` / `onResponse` 回调时，进入与离开是两份列表，顺序与错误路径要靠规范文档对齐。洋葱模型把一对进出绑在同一层的同一段控制流上：`next` 像洋葱的「往里挖一刀」，返回则「往外退一层」。

异步场景下，`next` 往往是异步的：外层 `await next()`，内层的等待与错误沿 Promise/效应栈传回外层，外层的 `finally` 式离开逻辑仍能运行——这也是现代 HTTP 中间件实现普遍采用洋葱叙事的原因。

## 在 Atlas 里

Atlas 用 `MiddlewarePipeline` 实现请求级洋葱：

| 概念 | Atlas |
|------|--------|
| 一层中间件 | `AtlasMiddleware { name, priority }` |
| 管道 | `MiddlewarePipeline`；`add` 后按 `priority` 排序 |
| 从外到内执行 | `execute` → `execute_at(0)` 递增 index |
| 调用内层 | 当前中间件经 `atlas_invoke_middleware` 处理，再进入 `execute_at(index+1)` |
| 最内层业务 | index 越界时 `host.run_terminal(ctx)`（路由 → handler） |
| 短路 | `ctx.short_circuit` 为真则不再深入 |

```text
execute(ctx, host)
  → execute_at(0)
       → 中间件₀ → execute_at(1)
            → …
                 → run_terminal（业务）
            ← …
       ← 中间件₀ 返回路径上的逻辑（由该中间件实现）
```

内置示例（名称与 priority 以默认组装为准）：`request-log`、`exception`、`response-log`、`websocket` 等，均作为管道中的一层，而不是业务 Handler 内的复制粘贴。

中间件若需要 logger、鉴权服务等协作对象，通过 [Wire](../wire/wire.md) 注入；管道负责**顺序与洋葱穿行**，容器负责**端口实例**。AOP 对照见 [AOP 与中间件](aop.md)；Filter → middleware 的演化见 [从历史到中间件](history.md)。
