# `tencent.wechat.sdk`

腾讯维护的微信小游戏宿主 `sdk`。

当前工程是理想 `sdk vendor` 体系下的骨架实现，用于承载：

- `std.net.get`
- `std.console.write_line`

这些入口在微信小游戏宿主下的 `host_provider`，以及微信小游戏专有宿主绑定：

- `tencent.wechat.sdk.storage.get_text`
- `tencent.wechat.sdk.auth.login`

## 边界

- 用户项目通常不需要显式写 `tencent.wechat.sdk`
- 默认由腾讯自己的第三方构建器按平台隐式注入
- 只有锁版本、测试版本或覆盖默认实现时才显式写出依赖
- 该 `sdk` 只负责微信小游戏能力绑定
- 微信小游戏最终工程组织、打包、预览、上传与发布交给腾讯自己的独立构建工具
- 这个构建工具不是 `legion` 插件
