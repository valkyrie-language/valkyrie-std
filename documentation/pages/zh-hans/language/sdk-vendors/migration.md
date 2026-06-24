# 迁移路线

## 迁移目标

从现有“`std` 直接按目标分支调用 `std.adaptor.*`”的模式，迁移到：

1. `std` 保持现有稳定函数入口
2. `sdk` / `std.adaptor.*` / vendor 包提供 `fill`
3. 项目侧 `sdk.bind` 负责选择实现
4. planner 负责过滤可见 `sdk`
5. 编译器在语义层静态绑定

## 为什么要渐进迁移

现有工程中已经存在大量：

- `std.adaptor.clr`
- `std.adaptor.jvm`
- `std.adaptor.wasm`
- `std.adaptor.nyar`

如果一次性全部推翻，会导致：

1. 现有项目大面积失效
2. 文档与代码长时间脱节
3. 编译器难以定位回归来源

因此需要分阶段迁移。

## 阶段 1：冻结旧模型

先禁止继续扩张旧模式：

1. 新能力不再直接在 `std` 中写 `match arch`
2. 新宿主不再新增为 `std` 内部分支
3. 新增宿主能力必须先确定 `port / bind / fill` 语义边界

这一步的目标不是马上删除旧代码，而是阻止架构继续恶化。

## 阶段 2：标注现有 `std` 入口

为现有高频能力标注 `port` 身份，但不改路径：

- `std.console.write`
- `std.console.write_line`
- `std.net.request`
- `std.timer.sleep_ms`
- `std.storage.get_text`

这一步只增加 `port` 语义，不新增 `std.port.*` 目录或命名体系。

## 阶段 3：把旧 adaptor 转成 `fill`

将现有宿主包逐步改造成 `fill` 提供方：

- `std.adaptor.clr` 提供 `console` / `net` / `timer`
- `std.adaptor.jvm` 提供 `console` / `net`
- `std.adaptor.wasm` 提供 browser 相关 `fill`
- `std.adaptor.nyar` 提供 `nyarvm` 相关 `fill`

此时旧包名继续保留，而且应作为发行版默认 `sdk` 集合的一部分。

## 阶段 4：把选择逻辑移出 `std`

把现有 `std` 源码里的宿主分支替换成稳定入口调用，再由 `bind` 决定实际实现。

例如把：

```v
<% match arch %>
```

替换成：

```v
std.net.request(req)
```

此时 `std` 仍然使用原路径，但不再自己决定具体宿主是谁。

## 阶段 5：planner 接管选择

在构建系统中增加 `fill` 选择逻辑：

1. 根据 `sdk-vendor` / target / publish / 有效依赖闭包过滤 `sdk`
2. 对每个 `port` 建立候选 `fill` 集
3. 在冲突时要求显式 `sdk.bind`
4. 在缺失时给出稳定诊断

## 阶段 6：清理历史命名

当 `fill` 机制稳定后，再逐步考虑命名收敛：

- `std.adaptor.*` 迁移为 `sdk.*`
- `std.adaptor.clr` 迁移为 `sdk.dotnet`
- `std.adaptor.wasm` 细分为 `sdk.browser` / `sdk.node` / 第三方 vendor

这一步只是命名清理，不应影响“发行版默认 `sdk` 仍然存在”这一事实。

## 兼容策略

### 编译器兼容

迁移期允许同时存在：

- 旧式 `std.adaptor.*`
- 新式 `port / bind / fill`

但新增能力只允许走新式设计。

### 文档兼容

文档应明确标注：

- 哪些页面描述的是历史结构
- 哪些页面描述的是目标架构
- 哪些工程仍处于迁移中

### 诊断兼容

若某个能力仍然走旧分支，应给出迁移提示，而不是默默接受：

- 建议新增 port
- 建议把当前宿主实现改写为 `fill`

## 推荐优先级

建议按下列顺序迁移：

1. `console`
2. `net`
3. `timer`
4. `storage`
5. `crypto`

因为这些能力：

- 宿主差异明显
- 第三方 vendor 需求最强
- 最能体现 `sdk vendor` 体系价值

## `wechat` 作为迁移试点

`wechat` 非常适合作为试点场景：

1. 它不是官方标准宿主
2. 它有强烈 vendor 属性
3. 它与 browser 同属 `js/wasm` 家族，但 API 并不等价
4. 它天然能暴露旧模型的不足

如果 `wechat` 能不修改 `std` 接入成功，说明新模型成立。

## 迁移完成的判据

当满足以下条件时，可视为迁移完成：

1. `std` 不再直接按宿主分支调用具体平台 API
2. `bind` 选择由项目清单与 planner 统一接管
3. 第三方 vendor 可以独立发布并接入
4. 最终产物不残留运行时绑定层
5. 后端不再承担任何 `fill` 兜底逻辑
