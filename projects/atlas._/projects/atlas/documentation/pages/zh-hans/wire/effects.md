# Wire 与代数效应

Valkyrie 已有**代数效应**（`raise` / `catch` / `resume`）：调用点声明能力需求，外层 handler 满足并可恢复执行。Atlas 仍然提供 **Wire**。二者解决的问题不同，叠在一起用，而不是互相替代。

## 代数效应在做什么

效应描述的是**执行过程中的能力请求**：

```text
业务计算走到某步
    → raise Get / Log / Await / …
    → 外层 catch 处理
    → 可选 resume 回断点继续
```

类型上常见 `T / E`：要么得到正常值 `T`，要么产生效应 `E`。`.await`、`yield` 等也可脱糖为效应。handler 的作用域是**动态的控制流边界**（谁在调用栈外层 catch），不是「对象构造时填好的字段表」。

效应适合：可恢复的交互式能力、局部改写控制流、把「要不要真的打日志 / 要不要挂起」留给外层策略。

语言设计见仓库内 Valkyrie 文档：`documentation/pages/zh-hans/maintainer/effect-system.md`，用户向概述见 `documentation/pages/zh-hans/language/effect-system/index.md`。

## Wire 在做什么

Wire 描述的是**对象图怎么组装**：System / Controller **持有哪些协作端口**，实例从容器来，在请求进入业务方法之前已经接好。

```text
AtlasHost 持有 AtlasWireContainer
    → apply_wire / wire_system
    → OrderSystem.store 已是某个 OrderStore 实现
    → 业务方法直接用 self.store
```

没有「每读一次库就 raise 一次 Store」的义务；端口是字段，生命周期跟对象/请求组装策略走。mock / sink / null 等非真实实现也是换容器里的实例，见 [非真实 Wire](doubles.md)。

## 为什么有了效应还要 Wire

| | 代数效应 | Wire |
|--|----------|------|
| 提问方式 | 「这一步要不要、如何获得某能力？」 | 「这个对象长期依赖谁？」 |
| 绑定时机 | 执行到 `raise` 时，由当前 catch 链回答 | 构造/请求边界 `apply_wire` 时回答 |
| 典型载体 | 操作与恢复（Get/Put/Log/Await…） | 服务端口实例（store、cache、client…） |
| 换实现 | 换 handler / 换 catch 策略 | 换容器注册（含 mock/sink/null） |
| 与 HTTP 宿主 | 可包在中间件或局部 catch | 与 `AtlasHost` 容器、每请求/每宿主组装对齐 |

若只用效应表达「所有依赖」：

- 每个业务方法都要在签名或调用约定里带上一长串效应，或依赖外层隐式 handler，**对象边界变糊**；
- Controller/System 作为长期存在的应用组件，其「有一个 OrderStore」更自然是**结构字段**，而不是每次调用临时 raise；
- 测试替身（尤其 null「一碰即爆」、sink「整段静默」）用容器换实例更直接；用效应则要保证整棵调用树上的 catch 都换成测试 handler，边界更容易漏；
- Atlas 请求模型已经有明确的宿主组装点（`AtlasHost` + container）；Wire 贴合该边界，效应不必也不该承担「框架级对象图 DI」。

若只用 Wire、取消效应：

- 异步挂起、可恢复日志探测、局部策略性能力仍要另造一套回调或参数穿透；
- 语言里已有的 `T / E`、async 脱糖会与框架脱节。

因此：**效应管「算到一半要能力」；Wire 管「组件上场前依赖已接好」。** Atlas Web API 里，持久端口走 Wire；真正的代数能力（含语言级 await 等）仍可在方法体里 `raise`，由外层或运行时 handler 处理——两套机制叠用。

## 叠用时的大致形状

```text
请求进入 AtlasHost
    → Wire：注入 store / logger 端口（真实或 mock/sink/null）
    → 调用 System 方法
         → 方法内可 raise Await / 其它效应
         → 语言/运行时 catch 与 resume
         → 方法通过已 wire 的 store 读写作业务 IO
```

业务作者很少需要二选一：对「换数据库实现、换测试替身」用 Wire；对「挂起、可恢复效应操作」用效应。把 Store 做成每次 `raise GetStore` 再 resume 实例，一般既绕又难与宿主生命周期对齐，不是 Atlas 的默认叙事。

## 和「host 不需要 DI 容器」的关系

语言侧 host/sdk 能力可用特性在编译期解析，那是**平台绑定**另一条线，不否定应用框架在请求边界使用 Wire。Atlas 的 Wire 服务的是**应用对象图**，不是替代效应，也不是替代 host 特性解析。
