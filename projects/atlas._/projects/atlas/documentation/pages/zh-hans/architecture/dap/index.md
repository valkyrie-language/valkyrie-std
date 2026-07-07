# DAP

**DAP（Domain Adapter Pattern）** 是 Atlas 与 Asgard 共用的应用结构指导思想：在 **低耦合、高内聚** 下组织 Host、Domain 与 Adapter。横切或纵切都可以；文档中的切法是推荐叙事，**不是强制规定**。

业务能力边界叫做 **Domain**（避免「System」歧义）。App（`XxxApplication`）按目标平台自动派生、很少自定义；用户默认写 **`XxxHost`**（并在其上挂 Domain / Adapter）。

- [应用怎么切：横切、纵切与 DAP](history.md)
- [DAP 机制](dap.md)
- [App / `XxxApplication`](application.md)（部署剖面：二进制 / 边缘 serverless / adaptor）
- [Host / `XxxHost`](host.md)

同级架构页（非 DAP 目录）：[路由与 Controller](../routing-and-controller.md)、[请求 / 响应](../request-response.md)、[运行时配置](../runtime-config.md)、[Store / Cache / Queue / EventBus](../store-cache-queue-eventbus.md)。

入门：[Starter](../../starter/index.md)。

包内实现摘要见 [`projects/atlas/readme.md`](../../../../../projects/atlas/readme.md)。
