# Asgard 框架文档

**Asgard** 是 Valkyrie 上的 GUI 应用框架，CLI 为 **`asgard build` / `asgard dev` / `asgard pack` / `asgard plan`**（Rust 实现 crate：`voa`）。

本目录为 Asgard 文档的 **canonical 位置**（可随框架移出 valkyrie 主仓库）。

## 架构

- [GUI 统一编译架构](architecture/gui-compilation.md)
- [Deploy Profile](architecture/deploy-profiles.md)
- [UI 渲染策略](architecture/ui-rendering.md)
- [Asgard Bifrost 自绘后端](../../../asgard.bifrost/documentation/pages/zh-hans/index.md)
- 应用结构指导思想（与 Atlas 共用）：[DAP](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/dap/index.md)、[历史脉络](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/dap/history.md)、[DAP 机制](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/dap/dap.md)、[App / `XxxApplication`](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/dap/application.md)、[Host / `XxxHost`](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/dap/host.md)
- **勿混用**：Atlas 的 Store / Cache / Queue / EventBus 是后端 Wire 概念，Asgard GUI **不得**套同名指同一套类型。见 [Atlas 四件套](../../../../atlas._/projects/atlas/documentation/pages/zh-hans/architecture/store-cache-queue-eventbus.md)。

## 平台交付

- [Android APK](platforms/android-apk.md)
- [iOS IPA](platforms/ios-ipa.md)
- [微信小程序](platforms/wechat-miniprogram.md)

## 配置

- [Asgard 应用配置](configuration.md)

## 工具链（valkyrie.v 主文档）

- [VOA 编译工具](../../../../documentation/pages/zh-hans/toolchain/voa.md)
- [目标三元组与 publish](../../../../documentation/pages/zh-hans/developer/target-triples.md)
- [AWSL 语言扩展](../../../../documentation/pages/zh-hans/language/extensions/awsl-language.md)
