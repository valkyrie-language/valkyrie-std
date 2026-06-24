# `unity.engine.sdk`

Unity 游戏宿主 `sdk` 骨架工程。

## 目标

- 为少量 `std` 的稳定入口提供 Unity 宿主侧 `fill`
- 通过 `sdk-vendor` 描述宿主适用范围
- 为 Unity 专有能力提供直接宿主绑定

## 当前范围

`fill`：

- `std.net.get`
- `std.console.write_line`

直接宿主绑定：

- `unity.engine.sdk.storage.get_text`
- `unity.engine.sdk.application.system_language`

## 说明

该工程是理想 `sdk vendor` 架构下的目标形态骨架，当前主要用于固定目录、命名、清单与宿主绑定边界。
