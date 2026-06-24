# 第三方 SDK

## 设计目标

第三方平台要成为第一等公民，就不能只允许它们“提供一组宿主函数”，还必须允许它们：

1. 独立发布自己的 `sdk`
2. 通过 `sdk-vendor` 声明适用平台
3. 通过 `[host_provider("...")]` 提供 `std` 稳定入口
4. 由自己的第三方构建器隐式注入默认版本
5. 在需要锁版本或测试版本时，被应用项目显式写出

因此，对 `wechat`、`unity` 这类平台，第三方通常要同时提供两样东西：

1. 平台 `sdk`
2. 平台构建器

其中本页只讨论第一项，第二项见 [第三方构建器](third-party-tool.md)。对微信小程序来说，第二项通常是独立工具；对 Unity 来说，第二项通常是插件。

## 第三方 SDK 的职责

第三方 `sdk` 只负责能力绑定，不负责完整平台构建流。

它应该负责：

1. 提供宿主 API 绑定
2. 用 `[host_provider("...")]` 严格提供 `std` 入口
3. 用 `sdk-vendor` 声明 target / publish 适用范围
4. 导出平台专有 API，供用户显式调用

它不应该负责：

1. 接管项目打包与发布
2. 把平台工程组织逻辑塞回 `legion`
3. 在源语言里手写平台胶水模板
4. 绕过 planner 直接替换 `std`

## 推荐目录结构

```text
projects/
  tencent.wechat.sdk/
    legion.von
    source/
      net.v
      storage.v
      login.v
  unity.engine.sdk/
    legion.von
    source/
      net.v
      console.v
      storage.v
      application.v
```

这里故意把 `tencent.wechat.sdk` 和 `unity.engine.sdk` 都放进 `projects/`，因为这正是最容易理解的工程组织方式：

- `std` 提供稳定语义
- `tencent.wechat.sdk` 提供微信小游戏填充
- `unity.engine.sdk` 提供 Unity 填充
- 不同平台由不同构建器把默认 `sdk` 注入有效依赖闭包

## `std` 层不变

`std` 仍然只暴露稳定入口：

```v
namespace std.net;

[host_contract]
micro get(url: utf8) -> utf8
```

关键点不是新开一个 `std.host_contract.net.get`，而是直接把现有 `std.net.get` 视为可由宿主实现的稳定入口。

## `tencent.wechat.sdk`

### `legion.von`

```von
{
    name: "tencent.wechat.sdk",
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

### `source/net.v`

```v
namespace tencent.wechat.sdk.net;

[host_provider("std.net.get")]
micro get(url: utf8) -> utf8 {
    return __wechat_net_get(url)
}

micro __wechat_net_get(url: utf8): utf8
```

这里故意不写手工 `js_builtin("__valkyrie...")` 胶水。对微信小游戏这类平台，底层 JS 桥接应由腾讯自己的构建器自动生成或汇编，而不是在源语言里硬写一层来回转换。

这个 `sdk` 的含义很直接：

- 目标是 `wasm32`
- 发布形态是 `mini-game`
- `std.net.get` 被填充为微信小游戏网络请求能力
- 微信专有 API 仍然可以作为普通宿主绑定单独导出

## `unity.engine.sdk`

### `legion.von`

```von
{
    name: "unity.engine.sdk",
    dependencies: {
        "std": "workspace"
    },
    sdk-vendor: {
        kind: "third-party-sdk",
        targets: ["clr-microsoft-unknown-managed"],
        publish: ["unity-player"]
    }
}
```

### `source/net.v`

```v
namespace unity.engine.sdk.net;

[host_provider("std.net.get")]
micro get(url: utf8) -> utf8 {
    return __unity_net_get(url)
}

micro __unity_net_get(url: utf8): utf8
```

这个 `sdk` 的含义同样直接：

- 目标是 `clr`
- 发布形态是 `unity-player`
- `std.net.get` 被填充为 Unity 网络请求能力

## 应用项目通常不用显式写 `sdk`

### 微信小游戏项目

```von
{
    name: "demo.wechat.game",
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

这里最重要的点不是再写一层 `sdk` 配置，而是应用项目通常连 `tencent.wechat.sdk` 都不用显式写。腾讯自己的第三方构建器应按平台把它注入当前构建的有效依赖闭包。

### Unity 游戏项目

```von
{
    name: "demo.unity.game",
    dependencies: {
        "std": "workspace"
    },
    build: [
        {
            target: "clr-microsoft-unknown-managed",
            publish: ["unity-player"]
        }
    ]
}
```

这里同理，`unity.engine.sdk` 通常由 Unity 侧构建器或导出工具按平台自动注入。

## 什么时候才显式写出 `sdk`

第三方 `sdk` 仍然允许显式声明，只是默认不强制。通常在以下场景才写：

1. 锁定特定版本
2. 测试候选版本
3. 覆盖第三方构建器默认注入
4. 同一平台出现多个 `sdk` 实现，需要手工指定候选集

例如：

```von
dependencies: {
    "std": "workspace",
    "tencent.wechat.sdk": "1.2.3"
}
```

## 什么时候才会出现冲突

当多个 `host_provider` 同时可见时，就会出现冲突。

例如某个项目同时可见：

- `tencent.wechat.sdk`
- `std.adaptor.wasm`

并且它们都为 `std.net.get` 提供可见 `host_provider`，这时编译器不能猜谁优先，必须通过显式依赖、锁版本或调整默认注入策略来继续收窄候选闭包。

## 与 `std.adaptor.*` 的关系

这个例子也顺便说明了为什么 `std.adaptor.*` 不能直接删：

- 普通项目没有第三方 `sdk` 时，仍然需要发行版默认实现
- 微信小游戏项目可以用 `tencent.wechat.sdk`
- Unity 游戏项目可以用 `unity.engine.sdk`
- 默认 `adaptor` 和专用 `sdk` 可以共存，但冲突时必须把候选闭包继续收窄

## 一句话总结

第三方平台要想被严谨支持，不能只有一组宿主绑定函数，而必须至少提供：

- 一个负责能力绑定的第三方 `sdk`
- 一个负责注入默认 `sdk` 并继续平台构建流的第三方构建器
