# Asgard 平台 Canonical Target 对齐表

与 [`target-triples.md`](../../../../documentation/pages/zh-hans/developer/target-triples.md)、[`AOT 原则`](aot-principles.md)、[`Deploy Profile`](deploy-profiles.md) 对齐。

**原则（矩阵，非一二进制）**：

- 同一业务源码可对多个 `platform` **各构建一次**，得到多份制品（CI / deploy profile 矩阵）。
- **每一个** platform 产物仍是「该平台一份逻辑 + UI wire」；禁止独立 `.bin` / `libasgard_host`。
- 部署拓扑（CDN、serverless、portable）由 **deploy profile** 选择要挂载的制品集合，不改变本表。

| `asgard.config.v` platform | canonical target | dist 唯一逻辑制品 | 嵌入段 |
|:---|:---|:---|:---|
| `browser` | `wasm32-unknown-browser-wasm` | `*.wasm` | manifest / 元数据段 |
| `android` | `aarch64-linux-android` | `dist/android/classes.dex` | `ASGARDNT` + asgard ui 尾段 |
| `ios` | `aarch64-apple-ios-aapcs64` | `dist/ios/AsgardHost` | 尾段 |
| `wechat-miniprogram` | `wasm32-unknown-miniprogram-wasm` | `dist/*.wasm` | asgard ui 尾段（无 `ASGARDNT`） |
| `windows` | `x86_64-pc-windows-msvc` | `dist/windows/{name}.exe` | 尾段 |
| `linux` | `x86_64-unknown-linux-gnu` | `dist/linux/{name}` | 尾段 |
| `macos` | `aarch64-apple-macos-aapcs64` | `dist/macos/{name}` | 尾段 |

`build.mode: dev` 可**额外**写出 `debug/render-ir.bin` 侧车（调试 only，非 Release 交付）。

Atlas 服务制品（`atlas.config.von`）**不在本表**；与 Asgard 制品通过 deploy profile 并列。

## CI 矩阵

`valkyrie.rs/.github/workflows/rust.yml` 中 `asgard-demo-matrix` 对 demo 工程执行 `asgard build`，断言无 `ASGDHOST` 占位。这是「多 platform × 多 demo」矩阵，不是单一二进制。
