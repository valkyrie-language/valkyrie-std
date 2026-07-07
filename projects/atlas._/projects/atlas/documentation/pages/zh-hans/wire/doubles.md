# 非真实 Wire：mock、sink、null

业务代码里的 `wire` 字段声明的是**端口形状**（需要什么样的协作对象），不是某一家真实实现。测试、fuzz、本地演练时，在容器里换成**非真实**实现即可；System / Controller **一行都不用改**。

## 三种常见非真实实现

| 种类 | 行为 | 典型用途 |
|------|------|----------|
| **mock** | 返回随机或可编排的假数据；读有样、写可记可不落真实库 | 单元/集成测试、属性测试、演示数据 |
| **sink** | 调用照单全收，静默成功（或记入内存黑洞），不对外报错 | 压测热路径、关掉副作用、只关心调用方逻辑 |
| **null** | 任意使用即失败（断言 / panic / 明确错误） | 证明某条路径「不该碰到」该依赖；收紧测试面 |

三者都实现与生产相同的端口类型（或同一套 wire 可解析的接口），差别只在**容器注册了哪一个实例**。

```text
生产：  container.register(OrderStore → PostgresOrderStore)
测试：  container.register(OrderStore → MockOrderStore)   // 假数据
       container.register(OrderStore → SinkOrderStore)   // 静默
       container.register(OrderStore → NullOrderStore)   // 一碰即爆

OrderSystem { wire store: OrderStore }  ← 源码不变
```

## 为何能做到「零改业务代码」

Wire 把「谁实现端口」留在宿主/`AtlasWireContainer` 边界。生成的 `apply_wire` 只向容器 `require`，不写死 `new Postgres…`。因此：

- fuzz：挂 mock，喂随机输入，业务图照常走；
- 单测某条分支：其余依赖用 sink，避免噪声失败；未预期触达的依赖用 null，一碰就爆，测试立刻红；
- 集成测：一部分端口真实、一部分 mock/sink，仍只改组容器的代码。

若业务方法内部直接 `new` 真实客户端，上述替换全部失效——这正是端口必须 `wire` 的原因之一。

## 选用直觉

- 路径**应该**用到依赖，且要看返回值 → **mock**
- 路径**可能**调用依赖，但本次断言不关心副作用 → **sink**
- 路径**不应该**调用依赖 → **null**（误用即失败，比静默成功更安全）

同一套测试套件里可以混用：例如「下单」测真实校验逻辑时，支付端口 sink、库存 mock、审计 null（证明没走审计旁路）。

## 和空依赖、缺失注册的区别

| | 非真实 Wire | 容器里根本没注册 |
|--|-------------|------------------|
| 意图 | 明确的测试替身 | 配置错误 |
| 行为 | mock/sink/null 的契约行为 | 成熟实现应硬失败；示例容器对 Store 返回 empty 属于缺口 |
| 业务源码 | 不改 | 不改（但测试/部署应修容器） |

null Wire 是**故意提供的爆炸实现**；「忘了 register」不是 null，不应靠 empty 糊弄过去。

## 实现状态

产品契约：端口可替换为 mock / sink / null，业务 `wire` 声明保持稳定。具体类型命名与是否已有标准库替身随端口演进；`atlas.cloud` 一侧已有 Null 风格占位可作参考，Store 等业务端口的标准三替身以工具/测试包落地为准。
