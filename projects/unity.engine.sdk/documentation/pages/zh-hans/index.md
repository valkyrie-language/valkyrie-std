# `unity.engine.sdk`

Unity 游戏宿主 `sdk`。

当前工程是理想 `sdk vendor` 体系下的骨架实现，用于承载：

- `std.net.get`
- `std.console.write_line`

这些真实 `std` 入口在 Unity 宿主下的 `fill`，以及 Unity 专有宿主绑定：

- `unity.engine.sdk.storage.get_text`
- `unity.engine.sdk.application.system_language`
