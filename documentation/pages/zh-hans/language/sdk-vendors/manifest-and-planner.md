# Manifest 与 Planner

## 设计定位

特性标注只声明“port 与 provider 的关系”，并不决定当前构建能看见哪些 provider。这个职责属于：

1. `legion.von`
2. target profile
3. planner
4. 依赖闭包与发布格式过滤

因此，`sdk vendor` 的核心原则是：

> 源码声明语义，清单声明适用范围，planner 负责装配。

## 为什么 target 选择不能写进源码

target 是构建环境信息，而不是源码语义。

若把 target 选择写进函数声明，就会出现：

1. 同一份源码必须重复嵌入大量平台矩阵
2. 第三方 vendor 包很难复用
3. 一个 provider 既要声明能力，又要内嵌发布逻辑
4. 语言层与构建系统层混在一起

因此，provider 的“是否参与当前构建”必须由 manifest 与 planner 判定。

## Manifest 应表达什么

### 包身份

每个 `sdk` 或 vendor 包必须有稳定包名：

```von
{
    name: "tencent.wechat.sdk.net"
}
```

### 依赖关系

provider 包必须显式声明依赖的抽象包或工具包：

```von
dependencies: {
    "std": "workspace"
}
```

### 适用目标

provider 包应通过 `build` 条目声明支持的 target 或发布矩阵：

```von
build: [
    {
        target: "wasm32-unknown-browser-wasm",
        publish: ["mini-game"]
    }
]
```

如果后续 target 模型支持更细粒度的 vendor / specification，也应继续放在 manifest 侧表达，而不是写进源码特性标注。

## Planner 的职责

planner 需要在现有“收集所有依赖源码”的基础上，再增加一层“可见 provider 过滤”。

当前最小职责如下：

1. 解析当前项目 manifest
2. 确定当前 `CanonicalTarget`
3. 计算依赖闭包
4. 过滤出与当前 target 匹配的 `sdk vendor` 包
5. 把这些包中的 provider 声明暴露给符号解析器

## 推荐装配流程

```text
项目 manifest
    ↓
workspace 依赖闭包
    ↓
按 target / publish / abi 过滤 sdk 包
    ↓
收集 provider 声明
    ↓
为每个 port 计算候选集
    ↓
冲突检查
    ↓
唯一绑定
```

## Provider 可见性规则

### 规则 1：只在当前依赖闭包中查找

provider 必须来自当前项目的依赖闭包，不能从 workspace 任意扫描。

理由：

1. 保证构建可重复
2. 避免不同 vendor 包互相污染
3. 保证项目显式依赖才生效

### 规则 2：必须通过 target 过滤

即使某个 provider 在依赖闭包里，只要它不适用当前 target，就视为不可见。

### 规则 3：默认不猜测优先级

多个 provider 同时可见时，planner 不按包名、目录名、时间戳或导入顺序猜测优先级。

必须显式选择。

## 显式选择机制

当多个 provider 都满足条件时，项目 manifest 可以显式绑定：

```von
bindings: {
    "std.port.net.request": "tencent.wechat.net.wechat_request"
}
```

这里的含义不是“运行时注入”，而是“编译期把这个 port 绑定到指定 provider”。

### 绑定字段规则

1. key 必须是稳定 port 路径
2. value 必须是当前依赖闭包中的 provider 路径
3. 若 value 指向的 provider 不存在，报错
4. 若 value 与 port 签名不兼容，报错

## 推荐的 `legion.von` 扩展

### Provider 包

```von
{
    name: "tencent.wechat.sdk.net",
    description: "腾讯维护的 WeChat 网络 SDK",
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

### 应用项目

```von
{
    name: "my-wechat-game",
    dependencies: {
        "std": "workspace",
        "tencent.wechat.sdk.net": "1.0.0"
    },
    bindings: {
        "std.port.net.request": "tencent.wechat.net.wechat_request"
    },
    build: [
        {
            target: "wasm32-unknown-browser-wasm",
            publish: ["mini-game"]
        }
    ]
}
```

## 与 target profile 的关系

target profile 可以提供“默认需要哪些能力族”的建议，但不应直接硬编码成具体 vendor 包。

应该允许：

- `browser` 目标默认需要 `net`、`console`、`timer` 能力
- `mini-game` 发布格式需要 `request`、`storage`、`login` 等额外能力

不应该直接写死：

- `browser -> sdk.browser`
- `mini-game -> tencent.wechat.sdk`

后者会把官方目标模型与特定厂商强耦合。

## Publish format 的作用

像 `wechat` 这样的宿主往往不只是 target 问题，还和发布格式相关：

- 同样是 `wasm/js` 族
- browser web app 与小程序 mini game 的宿主 API 完全不同

因此，planner 过滤 provider 时，至少要考虑：

1. `arch`
2. `abi`
3. `vendor`
4. `specification`
5. `publish format`

这也是为什么单纯按 `arch == wasm32` 分支永远不够。

## 诊断要求

planner 相关错误应该把“为什么这个 provider 不可见”说清楚：

- 未进入依赖闭包
- target 不匹配
- publish format 不匹配
- 被显式 binding 覆盖
- 多个 provider 冲突

## 迁移原则

旧系统若仍然存在 `std` 直接依赖 `std.adaptor.*` 的逻辑，应分三步迁移：

1. 先为能力建立 port
2. 再把旧 adaptor 声明成 provider
3. 最后从 `std` 中移除硬编码宿主分支

只有这样，planner 才能真正接管装配，而不是继续为历史结构擦屁股。
