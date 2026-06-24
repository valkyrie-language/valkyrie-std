# Manifest 与 Planner

## 设计定位

特性标注只声明“`host_contract` 与 `host_provider` 的关系”，并不决定当前构建能看见哪些实现。这个职责属于：

1. `legion.von`
2. target profile
3. planner
4. 第三方构建器的默认 `sdk` 注入策略
5. 选中实现后的宿主绑定属性由 `nyar` 在后续阶段单独收集处理

因此，`sdk vendor` 的核心原则是：

> 源码声明语义，`sdk-vendor` 声明 `sdk` 身份，planner 基于有效依赖闭包自动装配；若需要锁版本、测试版本或覆盖默认注入，则通过显式依赖收窄候选闭包。

## 为什么 target 选择不能写进源码

target 是构建环境信息，而不是源码语义。

若把 target 选择写进函数声明，就会出现：

1. 同一份源码必须重复嵌入大量平台矩阵
2. 第三方 `sdk` 包很难复用
3. 一个 `host_provider` 既要声明能力，又要内嵌发布逻辑
4. 语言层与构建系统层混在一起

因此，`host_provider` 的“是否参与当前构建”必须由 manifest、planner 与第三方构建器共同判定。

## Manifest 应表达什么

### 包身份

每个 `sdk` 或 vendor 包必须有稳定包名：

```von
{
    name: "tencent.wechat.sdk"
}
```

### 依赖关系

`sdk` 包自己必须显式声明依赖的抽象包或工具包：

```von
dependencies: {
    "std": "workspace"
}
```

这条规则只约束 `sdk` 包本身，不要求应用项目每次都显式把它写进 `dependencies`。

### `sdk-vendor` 元数据

`sdk` 的适用范围不应塞进通用 `build`，而应使用独立字段：

```von
sdk-vendor: {
    kind: "third-party-sdk",
    targets: ["wasm32-unknown-browser-wasm"],
    publish: ["mini-game"]
}
```

这里的含义是：

- `kind` 说明它是官方、发行版默认还是第三方 `sdk`
- `targets` / `publish` 说明它适用哪些装配场景
- 真正的实现关系不再写入 manifest 摘要，而是完全以源码中的 `[host_provider("...")]` 为准

如果后续 target 模型支持更细粒度的 vendor / specification，也应继续放在 `sdk-vendor` 侧表达，而不是写进源码特性标注。

## 什么是有效依赖闭包

planner 不应只看“项目显式写在 `dependencies` 里的包”，而应计算当前构建真正可见的有效依赖闭包：

1. 项目显式依赖
2. 工作区或发行版默认携带的 `std.adaptor.*`
3. 当前第三方构建器按平台隐式注入的默认 `sdk`
4. 这些包继续展开后的传递依赖

因此，“应用项目没写 `tencent.wechat.sdk`”并不等于“当前构建看不见 `tencent.wechat.sdk`”。

对 `wechat`、`unity` 这类第三方平台，默认 `sdk` 通常由平台方自己的构建器注入；只有在以下情况才建议应用项目显式写出：

1. 锁定特定版本
2. 测试候选版本
3. 覆盖构建器默认注入
4. 同一平台下显式切换不同 `sdk` 变体

## Planner 的职责

planner 需要在现有“收集所有依赖源码”的基础上，再增加一层“可见 `host_provider` 过滤”。

当前最小职责如下：

1. 解析当前项目 manifest
2. 确定当前 `CanonicalTarget`
3. 从显式依赖、发行版默认依赖和构建器注入规则计算有效依赖闭包
4. 过滤出与当前 target / publish 匹配的 `sdk` 包
5. 把这些包中的 `host_provider` 声明暴露给符号解析器
6. 若候选集唯一，则该实现进入后续 `nyar` 宿主绑定处理阶段

## 推荐装配流程

```text
项目 manifest
    ↓
target profile / publish format
    ↓
第三方构建器注入默认 sdk
    ↓
有效依赖闭包
    ↓
按 `sdk-vendor` / target / publish / abi 过滤 `sdk` 包
    ↓
收集 `host_provider` 声明
    ↓
为每个 `host_contract` 计算候选集
    ↓
冲突检查
    ↓
唯一绑定
```

## `host_provider` 可见性规则

### 规则 1：只在当前有效依赖闭包中查找

`host_provider` 必须来自当前构建的有效依赖闭包，不能从 workspace 任意扫描。

理由：

1. 保证构建可重复
2. 避免不同 vendor 包互相污染
3. 允许第三方构建器隐式注入默认 `sdk`
4. 保持“显式依赖 + 隐式注入”统一进入同一套候选集

### 规则 2：必须通过 target 过滤

即使某个 `host_provider` 在有效依赖闭包里，只要它不适用当前 target，就视为不可见。

### 规则 3：必须通过 publish 过滤

像 `wechat` 这种平台不能只按 `arch == wasm32` 判断；若 publish format 不匹配，也必须视为不可见。

### 规则 4：默认自动参与装配

只要某个 `sdk` 包进入有效依赖闭包，且其 `sdk-vendor` 与当前 target / publish 匹配，planner 就应自动把它纳入候选集。

### 规则 5：默认不猜测优先级

多个 `host_provider` 同时可见时，planner 不按包名、目录名、时间戳或导入顺序猜测优先级。

此时不再引入额外项目级 `bind` 配置，而是要求通过显式依赖、锁版本或构建器默认注入策略把候选集收窄到唯一实现。

## 推荐的 `legion.von` 形态

### 第三方 `sdk` 包

```von
{
    name: "tencent.wechat.sdk",
    description: "腾讯维护的 WeChat Mini Game SDK",
    dependencies: {
        "std": "workspace"
    },
    sdk-vendor: {
        kind: "third-party-sdk",
        targets: ["wasm32-unknown-browser-wasm"],
        publish: ["mini-game"]
    }
}
```

### 应用项目

```von
{
    name: "my-wechat-game",
    dependencies: {
        "std": "workspace"
    },
    build: [
        {
            target: "wasm32-unknown-browser-wasm",
            publish: ["mini-game"]
        }
    ]
}
```

这里故意不显式写 `tencent.wechat.sdk`。默认情况下，腾讯自己的微信小游戏构建器应当按平台把它注入当前构建的有效依赖闭包。

如果要锁版本或测试候选版本，才显式改写为：

```von
{
    name: "my-wechat-game",
    dependencies: {
        "std": "workspace",
        "tencent.wechat.sdk": "1.2.3"
    },
    build: [
        {
            target: "wasm32-unknown-browser-wasm",
            publish: ["mini-game"]
        }
    ]
}
```

### 冲突时的应用项目

只有在多个 `host_provider` 同时命中时，才需要通过显式依赖收窄候选集：

```von
{
    name: "my-wechat-game",
    dependencies: {
        "std": "workspace",
        "tencent.wechat.sdk": "1.2.3",
        "sdk.browser.net": "workspace"
    },
    build: [
        {
            target: "wasm32-unknown-browser-wasm",
            publish: ["mini-game"]
        }
    ]
}
```

### 发行版默认 `sdk`

发行版还应继续携带一组官方默认 `sdk`，典型就是现有的 `std.adaptor.*`：

```von
{
    name: "std.adaptor.wasm",
    dependencies: {
        "std": "workspace"
    },
    sdk-vendor: {
        kind: "distribution-default",
        targets: ["wasm32-unknown-browser-wasm"],
        publish: ["web"]
    }
}
```

这样即使用户没有单独引入第三方 `sdk`，也仍然能依赖发行版自带默认实现完成普通应用开发。

## 第三方平台的边界

对像 `wechat`、`unity` 这样的第三方平台，还需要额外强调一条边界：

- `sdk` 只负责能力绑定
- `legion` 只负责通用编译与中间产物输出
- 平台工程组织、打包、预览、上传与发布由平台方自己的第三方构建器处理
- 这个构建器不是 `legion` 插件，只是共享 `nyar` 的基础 build 体系

## 与 target profile 的关系

target profile 可以提供“默认需要哪些能力族”的建议，但不应直接硬编码成具体 vendor 包。

应该允许：

- `browser` 目标默认需要 `net`、`console`、`timer` 能力
- `mini-game` 发布格式需要 `request`、`storage`、`login` 等额外能力

不应该直接写死：

- `browser -> sdk.browser`
- `mini-game -> tencent.wechat.sdk`

前者属于能力族建议，后者则把官方目标模型与特定厂商强耦合。

## Publish format 的作用

像 `wechat` 这样的宿主往往不只是 target 问题，还和发布格式相关：

- 同样是 `wasm/js` 族
- browser web app 与 mini game 的宿主 API 完全不同

因此，planner 过滤 `sdk` / `host_provider` 时，至少要考虑：

1. `arch`
2. `abi`
3. `vendor`
4. `specification`
5. `publish format`

这也是为什么单纯按 `arch == wasm32` 分支永远不够。

## 诊断要求

planner 相关错误应该把“为什么这个 `host_provider` 不可见”说清楚：

- 未进入有效依赖闭包
- target 不匹配
- publish format 不匹配
- 候选闭包未被收窄到唯一实现
- 多个 `host_provider` 冲突

## 迁移原则

旧系统若仍然存在 `std` 直接依赖 `std.adaptor.*` 的逻辑，应分三步迁移：

1. 先把现有 `std` 入口标注为 `host_contract`
2. 再把旧 adaptor 声明成 `host_provider`
3. 最后把选择逻辑迁移到 planner 与有效依赖闭包筛选

只有这样，planner 才能真正接管装配，而不是继续为历史结构擦屁股。
