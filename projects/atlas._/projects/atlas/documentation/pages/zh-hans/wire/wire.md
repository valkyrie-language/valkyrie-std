# Wire 机制

## 什么是 Wire

**Wire** 是 Atlas 对「依赖如何进入 System / Controller」的产品说法：在类型上用 `wire` 标出协作字段，由编译器生成注入逻辑，再在宿主边界用容器把实例填进去。

相对 [从 IoC/DI 到 Wire](history.md) 的词汇：

| 概念 | 在 Atlas 里 |
|------|-------------|
| IoC | 对象图不由业务 `new` 整棵拼出，而由宿主/`AtlasHost` 在处理请求前接线 |
| DI | 依赖从外部写入 `wire` 字段（生成代码调用容器 `require_*`） |
| Wire | 声明语法（`wire` 字段）+ 注入协议（`AtlasWireable` / `apply_wire`）+ 容器（`AtlasWireContainer`） |

对标关系（机制相似，实现不同）：C# 侧常见 `[Wire]` 属性 + 扫描；Valkyrie / Atlas 侧是 **`wire` declaration modifier + `WireInjector` 代码生成**，**不靠运行时反射扫描字段**。

## 声明：`wire` 字段

```valkyrie
class OrderSystem {
    wire store: OrderStore
}
```

`wire` 表示：这个字段是协作端口，应由注入补齐，而不是在业务方法里临时 `new OrderStore`。一个类型上可以有多个 `wire` 字段；未标记的字段仍按普通字段处理。

## 注入协议：`AtlasWireable` 与 `apply_wire`

无反射时，注入不能靠「运行时读字段表」。Atlas 约定实现 `AtlasWireable`：

```valkyrie
trait AtlasWireable {
    micro apply_wire(mut self, container: AtlasWireContainer): unit
}
```

编译器（`WireInjector`）根据 `is_wire` 字段生成例如：

```valkyrie
imply OrderSystem: AtlasWireable {
    micro apply_wire(mut self, container: AtlasWireContainer): unit {
        self.store = container.require_store("OrderStore")
    }
}
```

业务作者写声明；**接线代码是生成物**。这与 Route / Middleware 等 injector 同一哲学：改源头声明，再生成，而不是手维护一份易漂移的注册表。

## 容器：`AtlasWireContainer`

容器在宿主侧持有可注入实例，并在 `apply_wire` / `wire_system` 时提供给 System。

今日实现里可见的能力包括：

- 注册与查询键（`register_key` / `contains`）；
- 内建横切：`logger` / `cache` / `queue` / `event_bus`（`fill_builtins` 填进 `AtlasSystem`）；
- 示例级 Store 端口：`register_store` / `require_store`（当前以 `OrderStore` 为样例形状）。

`AtlasHost` 持有 `container`，可在构建宿主时 `use_container`；处理请求、构造 System/Controller 时走 `wire_system` 或各 Controller 的 `wire(...)` 入口，把容器中的实例接到业务对象上。

容器的**产品方向**是：按端口/类型提供协作对象，供生成的 `apply_wire` 拉取。当前仓库里通用类型注册仍偏示例与内建四件套，后续应扩成任意 `wire field: T` 可解析，而不是长期绑死某一个 Store 类型——但**声明用 `wire`、注入用生成 `apply_wire`** 这条主线不变。

## 在请求路径上的位置

```text
AtlasHost（持有 AtlasWireContainer）
    │
    ▼
process / handler 分发
    │
    ├─ wire_system / Controller.wire(container)
    │     → apply_wire / fill_builtins
    │
    ▼
System / Controller 业务方法
    （使用已注入的 store / logger / …）
```

Wire 解决的是**对象从哪来**；路由、中间件、Hermes / Query IR 解决的是请求怎么进、数据怎么查。与语言**代数效应**的分工见 [Wire 与代数效应](effects.md)；请求横切见 [Middleware · AOP](../middleware/aop.md)。

## 非真实实现（mock / sink / null）

测试与 fuzz 不改业务源码，只在容器里换端口实现：

| | 行为 |
|--|------|
| **mock** | 随机或编排的假数据 |
| **sink** | 静默吞掉调用 |
| **null** | 一碰即失败 |

详见 [非真实 Wire](doubles.md)。

## 和「手写传入」的关系

构造时手动传入依赖，仍是合法 DI，适合极小例子或测试。Wire 要解决的是框架尺度上的重复与遗漏：每个 Controller/System 都手写一遍组装，容易漏接、难统一换实现（例如测试替身、云上不同缓存）。`wire` + 容器 + 生成注入，把「缺依赖」变成「声明了但容器没提供」的显式失败点（实现成熟后应是硬错误；示例容器对缺失 Store 仍可能返回 empty，属成熟度缺口，不是「允许默默空依赖」的产品承诺）。

## 和数据访问的关系

- Hermes schema、`RegenBindings`、Query IR：定义**数据长什么样、怎么查**；
- Wire：定义**谁持有访问端口**（如 store / 客户端）并在请求边界注入。

可以 `wire` 一个由绑定生成的 Store/仓储端口，再在方法里发 Hermes query。schema / Query IR 描述数据与查询；Wire 只负责把端口实例接到 System / Controller 上，容器也不用来登记表结构。

## 明确不在范围

- 运行时反射扫描程序集找 `[Wire]`；
- 把 Wire 做成与业务无关的通用超级 IoC 产品（`AtlasWireContainer` 服务的是 Web API 宿主边界）；
- 用 Wire 代替中间件、路由或鉴权模型。
