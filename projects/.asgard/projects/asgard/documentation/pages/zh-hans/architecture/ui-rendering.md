# UI 渲染策略（平台原生优先）

逻辑 **AOT 一次**；UI wire **编入平台唯一制品**；设备侧 **原生 shim** 解码（非 VM）。见 [AOT 原则](aot-principles.md)。

| 宿主 | 唯一制品 | UI 消费方式 |
|:---|:---|:---|
| **Web** | `*.wasm` | DOM glue |
| **Android** | `classes.dex` | Compose shim 读 dex 尾段 |
| **iOS** | `AsgardHost` | SwiftUI shim 读 Mach-O 尾段 |
| **微信小程序** | `*.wasm` + `voa-runtime.js` | asgard ui 尾段 + WXML setData |
| **桌面** | `{name}.exe` / ELF / Mach-O | WinUI / SwiftUI / Linux native runtime 读制品尾段 |

**禁止**：独立 `ui.bin`、`host.bin`、`libasgard_host`；**禁止** `asgard.ui` V 源码上设备。
