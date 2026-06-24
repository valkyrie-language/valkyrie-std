# `tencent.wechat.sdk`

腾讯微信小游戏宿主 `sdk` 骨架工程。

## 目标

- 为少量 `std` 的稳定入口提供微信小游戏侧 `fill`
- 通过 `sdk-vendor` 描述宿主适用范围
- 在微信小游戏目标下支持无感自动装配
- 为微信小游戏专有能力提供直接宿主绑定

## 当前范围

`fill`：

- `std.net.get`
- `std.console.write_line`

直接宿主绑定：

- `tencent.wechat.sdk.storage.get_text`
- `tencent.wechat.sdk.auth.login`

## 说明

该工程是理想 `sdk vendor` 架构下的目标形态骨架，当前主要用于固定目录、命名、清单与宿主绑定边界。

## 构建职责

- 用户项目通常不需要显式写 `tencent.wechat.sdk`
- 默认由腾讯自己的第三方构建器按平台隐式注入
- 只有锁版本、测试版本或覆盖默认实现时才显式写出依赖
- `legion` 只负责通用编译和中间产物输出
- 微信小游戏最终构建由腾讯自己的独立构建工具接管
- 该工具不是 `legion` 插件，只是共享 `nyar` 的基础 build 体系
