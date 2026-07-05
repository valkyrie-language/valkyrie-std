# Asgard 平台 Canonical Target 对齐表

与 [`target-triples.md`](../../../../documentation/pages/zh-hans/developer/target-triples.md)、[`AOT 原则`](aot-principles.md) 对齐。

**原则**：每平台 **一个制品** 承载逻辑 + UI wire；禁止独立 `.bin` / `libasgard_host`。

| `voa.config.v` platform | canonical target | dist 唯一逻辑制品 | 嵌入段 |
|:---|:---|:---|:---|
| `browser` | `wasm32-unknown-browser-wasm` | `*.wasm` | manifest / 元数据段 |
| `android` | `aarch64-linux-android` | `dist/android/classes.dex` | `ASGARDNT` + asgard ui 尾段 |
| `ios` | `aarch64-apple-ios-aapcs64` | `dist/ios/AsgardHost` | 尾段 |
| `wechat-miniprogram` | `wasm32-unknown-miniprogram-wasm` | `dist/*.wasm` | asgard ui 尾段（无 `ASGARDNT`） |
| `windows` | `x86_64-pc-windows-msvc` | `dist/windows/{name}.exe` | 尾段 |
| `linux` | `x86_64-unknown-linux-gnu` | `dist/linux/{name}` | 尾段 |
| `macos` | `aarch64-apple-macos-aapcs64` | `dist/macos/{name}` | 尾段 |

`build.mode: dev` 可**额外**写出 `debug/render-ir.bin` 侧车（调试 only，非 Release 交付）。

## CI 矩阵

`valkyrie.rs/.github/workflows/rust.yml` 中 `asgard-demo-matrix` 对 demo 工程执行 `asgard build`，断言无 `ASGDHOST` 占位。
