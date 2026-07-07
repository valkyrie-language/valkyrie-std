# UI 渲染策略（平台原生优先，Bifrost 并行）

逻辑 **AOT 一次**；UI wire **编入平台唯一制品**；设备侧 **原生 shim** 解码（非 VM）。见 [AOT 原则](aot-principles.md)。

| 宿主 | 唯一制品 | UI 消费方式 |
|:---|:---|:---|
| **Web** | `*.wasm` | DOM glue |
| **Android** | `classes.dex` | Compose shim 读 dex 尾段 |
| **iOS** | `AsgardHost` | SwiftUI shim 读 Mach-O 尾段 |
| **微信小程序** | `*.wasm` + `voa-runtime.js` | asgard ui 尾段 + WXML setData |
| **桌面** | `{name}.exe` / ELF / Mach-O | WinUI / SwiftUI / Linux native runtime 读制品尾段 |

当前策略分两条：

- **主线**：平台原生优先，由原生 shim 消费 `asgard.ui` 契约
- **并行线**：`asgard.bifrost` 自绘后端，面向跨平台像素级一致性与复杂动画场景

`asgard.bifrost` 不改变 Asgard 的 AWSL 语义层，而是作为另一条渲染后端存在；其底层应直接消费共享的 `gnosis.layout`、`gnosis.text`、`gnosis.render`、`gnosis.gpu`，而不是在 Asgard 内部重复发明一套 layout / fonts / GPU 栈。见 [Asgard Bifrost](../../../asgard.bifrost/documentation/pages/zh-hans/index.md) 与 [公共图形栈](../../../../../../documentation/pages/zh-hans/developer/graphics-stack.md)。

**禁止**：独立 `ui.bin`、`host.bin`、`libasgard_host`；**禁止** `asgard.ui` V 源码上设备。
