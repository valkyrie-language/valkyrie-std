# iOS IPA（Asgard + VOA）

iOS 走 **Mach-O 字节码交付**：逻辑 V→Mach-O，RenderIR **编入可执行文件 / 应用包**。**无 WASM、无 Swift 源码**。见 [统一编译架构](../architecture/gui-compilation.md)。

## 与 Web / 微信 / Android 的差异

| | Web | 微信小程序 | Android | iOS |
|:---|:---|:---|:---|:---|
| 逻辑字节码 | **WASM** | 宿主字节码 | DEX | **Mach-O** |
| UI | DOM | WXML | Compose | SwiftUI 读 **制品内 IR** |
| `platform` | `browser` | `wechat-miniprogram` | `android` | **`ios`** |

## 流程

1. `platform: "ios"`，`target` 如 `aarch64-apple-ios-aapcs64`
2. `asgard build` → `dist/ios/`：Mach-O、`Info.plist`（**RenderIR 经 `embed_asgard_ui_section` 编入可执行文件尾部**）
3. `build.mode: dev` 时可 **额外** 有 `debug/render-ir.bin`
4. `asgard pack --target ipa`

宿主编译失败时 **报错退出**。运行时由 **`asgard.ui`**（`projects/asgard.ui`）从 Mach-O 解码 Asgard UI wire 并驱动 SwiftUI。

## Release dist（目标形态）

| 内容 | 说明 |
|:---|:---|
| Mach-O 可执行 | 逻辑 + **编入的 RenderIR** |
| `Info.plist` | Bundle 元数据 |

**无** 独立 `ui.bin`（Release）；**无** `.swift` / Xcode 源码工程。

示例：`examples/demo.ios/`。
