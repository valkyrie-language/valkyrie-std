# 第三方 Vendor

## 为什么要支持第三方 vendor

并不是所有宿主都应由官方维护。

例如：

- 腾讯维护 `wechat`
- Cloudflare 维护 Worker 生态
- Electron 社区维护桌面桥接
- 企业内部维护私有 runtime

如果语言只能接入“官方已经内建的宿主”，那 `sdk` 体系就不是可扩展架构，而只是“标准库硬编码表”。

因此，第三方 vendor 必须是第一等公民。

## 第三方 vendor 的基本权利

第三方 vendor 应该能够：

1. 独立发布 `sdk` 包
2. 通过特性标注声明 provider
3. 通过 `legion.von` 声明适用目标
4. 被应用项目显式依赖
5. 在不修改官方 `std` 的前提下参与编译期静态绑定

## 第三方 vendor 的基本约束

第三方 vendor 不应能够：

1. 隐式覆盖官方 `std`
2. 未经项目显式依赖就进入构建闭包
3. 通过运行时注册表注入 provider
4. 在 target 不匹配时偷偷参与装配

## 推荐命名

### 包名

建议使用“组织名 + 宿主名 + 能力域”的稳定路径：

- `tencent.wechat.sdk.net`
- `tencent.wechat.sdk.storage`
- `cloudflare.worker.sdk.fetch`
- `electron.sdk.fs`

### 命名空间

命名空间应与包身份一致，避免与官方 `std` 产生命名冲突：

```v
namespace tencent.wechat.net;
namespace tencent.wechat.storage;
```

## `wechat` 的最小示例

### `sdk` 包的角色

`wechat` 包不直接定义“HTTP 是什么”，它只实现 `std` 暴露出的请求能力。

### 代码结构

```text
vendors/tencent.wechat.sdk.net
  legion.von
  source/net/request.v
```

### `legion.von`

```von
{
    name: "tencent.wechat.sdk.net",
    description: "腾讯维护的 WeChat 网络能力绑定",
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

### provider 声明

```v
namespace tencent.wechat.net;

[provides("std.port.net.request")]
micro wechat_request(req: Request) -> Response {
    let raw = to_wx_request(req)
    let handle = __wx_request(raw)
    return from_wx_response(handle)
}

[js_builtin("wx.request")]
micro __wx_request(req: i32): i32
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
    }
}
```

## 为什么 `wechat` 不应进入官方 `std`

因为它同时具有：

1. 厂商属性
2. 宿主属性
3. 发布渠道属性
4. API 生命周期由第三方控制

把这类能力放进官方 `std` 会导致：

- 官方标准库承担第三方平台兼容成本
- target profile 绑定具体厂商
- vendor API 的变更直接污染语言主仓

## 官方与第三方的关系

### 官方负责

- 维护 `std` 抽象能力
- 维护编译器对 port / provider 的静态解析
- 维护官方目标模型与诊断规则

### 第三方 vendor 负责

- 维护具体宿主 API 绑定
- 跟进厂商 API 升级
- 提供迁移说明与兼容策略

### 应用开发者负责

- 显式声明依赖
- 选择具体 binding
- 在冲突时给出明确偏好

## 冲突处理

若同一个项目同时引入：

- `sdk.browser.net`
- `tencent.wechat.sdk.net`

并且两者都提供 `std.port.net.request`，则默认报错，而不是“谁先加载谁生效”。

应用项目必须显式写：

```von
bindings: {
    "std.port.net.request": "tencent.wechat.net.wechat_request"
}
```

## 第三方 vendor 的版本策略

建议遵守以下原则：

1. provider 路径一旦公开，尽量保持稳定
2. 若厂商 API 发生破坏性升级，优先增加新 provider 路径，而不是静默改变旧语义
3. 若同一宿主存在多个大版本，可通过包名或次级命名空间区分

例如：

- `tencent.wechat.sdk.v2.net`
- `tencent.wechat.v3.net`

## 安全边界

第三方 vendor 包可以提供宿主能力，但不能绕过语言或构建系统的以下边界：

1. 不能隐式注入未声明依赖
2. 不能覆盖未显式允许的 port
3. 不能在运行时替换 provider
4. 不能通过宏或模板偷偷重写 `std` 本体

## 审核建议

官方仓库不必收录所有第三方 vendor，但可以维护“兼容生态清单”，仅记录：

- 包名
- 维护方
- 支持 target
- 提供哪些 port
- 最低编译器版本

这样既不把第三方代码强耦合进主仓，也能为生态提供发现入口。
