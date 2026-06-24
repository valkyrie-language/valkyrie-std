# 迁移路线

## 迁移目标

从现有“`std` 直接按目标分支调用 `std.adaptor.*`”的模式，迁移到：

1. `std` 保持现有稳定函数入口
2. `sdk` / `std.adaptor.*` / vendor 包提供 `host_provider`
3. `bind` 指的是底层宿主绑定属性，由 `nyar` 收集处理
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
3. 新增宿主能力必须先确定 `host_contract / bind / host_provider` 语义边界

这一步的目标不是马上删除旧代码，而是阻止架构继续恶化。

## 阶段 2：标注现有 `std` 入口

为现有高频能力标注 `host_contract` 身份，但不改路径：

- `std.console.write`
- `std.console.write_line`
- `std.net.request`
- `std.timer.sleep_ms`
- `std.storage.get_text`

这一步只增加 `host_contract` 语义，不新增 `std.host_contract.*` 目录或命名体系。

## 阶段 3：把旧 adaptor 转成 `host_provider`

将现有宿主包逐步改造成 `host_provider` 提供方：

- `std.adaptor.clr` 提供 `console` / `net` / `timer`
- `std.adaptor.jvm` 提供 `console` / `net`
- `std.adaptor.wasm` 提供 browser 相关 `host_provider`
- `std.adaptor.nyar` 提供 `nyarvm` 相关 `host_provider`

此时旧包名继续保留，而且应作为发行版默认 `sdk` 集合的一部分。

## 阶段 4：把选择逻辑移出 `std`

把现有 `std` 源码里的宿主分支替换成稳定入口调用，再由 `host_provider` 候选过滤决定实际实现，而底层宿主调用细节继续由 `bind` 属性承载。

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

在构建系统中增加 `host_provider` 选择逻辑：

1. 根据 `sdk-vendor` / target / publish / 有效依赖闭包过滤 `sdk`
2. 对每个 `host_contract` 从源码中的 `[host_provider("...")]` 收集候选实现
3. 在冲突时要求继续收窄有效依赖闭包
4. 在缺失时给出稳定诊断

这里不再引入 manifest 级 `host_providers` 摘要字段，`host_provider` 与底层 `bind` 一样都由 `nyar` 从源码属性收集。

## 阶段 6：清理历史命名

当 `host_provider` 机制稳定后，再逐步考虑命名收敛：

- `std.adaptor.*` 迁移为 `sdk.*`
- `std.adaptor.clr` 迁移为 `sdk.dotnet`
- `std.adaptor.wasm` 细分为 `sdk.browser` / `sdk.node` / 第三方 vendor

这一步只是命名清理，不应影响“发行版默认 `sdk` 仍然存在”这一事实。

## 兼容策略

### 编译器兼容

迁移期允许同时存在：

- 旧式 `std.adaptor.*`
- 新式 `host_contract / bind / host_provider`

但新增能力只允许走新式设计。

### 文档兼容

文档应明确标注：

- 哪些页面描述的是历史结构
- 哪些页面描述的是目标架构
- 哪些工程仍处于迁移中

### 诊断兼容

若某个能力仍然走旧分支，应给出迁移提示，而不是默默接受：

- 建议新增 `host_contract`
- 建议把当前宿主实现改写为 `host_provider`

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
2. `host_provider` 选择完全由 planner 与有效依赖闭包接管
3. 第三方 vendor 可以独立发布并接入
4. 最终产物不残留运行时绑定层
5. 后端不再承担任何 `host_provider` 兜底逻辑

## 当前进度

截至本轮，已经落地以下迁移：

1. `std.console` / `std.net` / `std.io.time` / `std.io.fs` 的第一批入口已改为 `host_contract`，移除了这些文件里的 `match arch`
2. `std.adaptor.clr` / `std.adaptor.jvm` / `std.adaptor.wasm` / `std.adaptor.nyar` / `std.adaptor.windows` / `std.adaptor.linux` / `std.adaptor.macos` 已补入第一批 `host_provider`
3. `std contract` 涉及字符串时继续以 `utf8` 为稳定入口；浏览器侧 `js_builtin` 仍保持宿主真实字符串语义，显式转换只能出现在 provider 代码里，不能落到 `bind` 层
4. `std.adaptor.wasip1` 与 `std.adaptor.wasip2` 已从默认工作区依赖中退出，新增单一 `std.adaptor.wasi` 作为 `WASI component model` 收口入口
5. `sdk-vendor` 继续保留宿主元数据，但不再声明 `host_providers` 摘要；`host_provider` 与 `bind` 统一由源码属性收集
6. `valkyrie.rs` 已同步接入 `sdk-vendor` manifest 解析，并把 `wasi` ABI 收敛为单一口径，相关解释器与测试也已同步更新

下一批继续推进：

1. 为 `std.adaptor.wasi` 补齐 `net` / `fs` 等 provider，而不是只保留时间入口
2. 在 `legion` planner 中把 `host_contract` / `host_provider` 的源码收集与候选过滤真正接起来
3. 清理文档中仍残留的 manifest `host_providers` 旧表述
