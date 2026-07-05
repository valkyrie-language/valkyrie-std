# 平台契约硬门禁（Platform Contract）

跨平台 UiHost / ASGARD 交付物由 **单一门禁表** 约束，防止各平台交付物 drift。实现位于 `valkyrie.rs/projects/voa/src/platform_contract/`；表驱动测试见 `tests/platform_contract.rs`。

## 默认路径与主产物

| 优先级 | `platform` | 交付形态 | 说明 |
|:---|:---|:---|:---|
| **默认** | `browser` | WASM + `boot.js` / `index.html` | `voa.config.v` 未指定时即此路径；本地开发为 **VOA → WASM → WebView/浏览器** |
| **并列主产物** | `wechat-miniprogram` | WASM + `voa-runtime.js` | 与 Web 同族 WASM AOT；UI 仍为 WXML |
| 次要 / 远期 | `android` / `ios` / 桌面 | 各平台原生制品 | 门禁表同样适用，但非默认开发路径 |

普通 `asgard build` / `pack` **不需要** `ANDROID_HOME`、`KOTLIN_HOME` 或 Android SDK。下文 Android / Compose 章节面向该平台的契约与维护者脚本，不代表默认工作流。

## 门禁 ID 表

| Gate ID | 适用范围 | 必须满足 |
|:---|:---|:---|
| **G-MAG-UI** | 全部含 UI 的制品 | 尾段含 8 字节魔数 `ASGARDUI` |
| **G-MAG-NT** | Android / iOS / 桌面 | 尾段含 8 字节魔数 `ASGARDNT`（native AOT） |
| **G-NO-LEGACY** | 全部 | 禁止 `ASGDHOST` / `ASGDUI` / `ASGDNAT` 及 `asgard/Placeholder` |
| **G-NO-ANDROID-C** | Android dist 目录 | 禁止 `android/native/` 与 `*.c` |
| **G-ABI-MOUNT** | runtime 生成源 | 含 `mount` 语义 |
| **G-ABI-PATCH** | runtime 生成源 + Android dex | `patch` / `patchFromNative` |
| **G-ABI-EVENT** | runtime 生成源 + Android dex | `on_event` / `invokeExport` |
| **G-ABI-EXPORT** | 全平台 | `resolve_call_export` → `awsl_call_*` |
| **G-JNI-SYM** | Android `.so` | `JNI_OnLoad`、`asgard_invoke_export`、`asgard_patch_native` |
| **G-ANDROID-COMPOSE** | Android `classes.dex` | 见下节 |

## 校验入口（三层 API）

| 函数 | 面向 |
|:---|:---|
| `validate_android_dist_bytes` / `validate_ios_dist_bytes` | **delivery**：pack 前制品字节 |
| `validate_android_dist_dir` | **compile / pipeline**：dist 目录布局 + dex |
| `validate_runtime_source_cip` | **模板**：各平台生成源 ABI 闭环 |
| `validate_android_apk_dex` | APK 内嵌 `classes.dex` |
| `validate_android_native_so` | Android ET_DYN `.so` |

失败格式统一为 `G-*: 原因`，可用 `format_gate_failures` 稳定断言。

## G-ANDROID-COMPOSE

`classes.dex` **本体**（不含 ASGARD 尾段）分两层：

### Bootstrap 层（始终检查）

1. **string_ids** 含 `Lcom/asgard/runtime/AsgardComposeRuntime;`、`AsgardHostBridge`、`ComponentActivity`、`androidx/compose/`
2. 含 `decodeAsgardUi`、`AsgardRoot`、`mount`、`patch`、`on_event`、`invokeExport`、`patchFromNative`

Rust stub / CI 须通过此层。

### Vendor 层（`class_defs > 50` 时追加）

SDK 编译的 `compose-shell.dex` 还须满足：

- `setContent`、`Composable` 出现在 string table
- 不含 bootstrap 专用 `stub()V` 占位

## Compose dex 来源

| 模式 | 条件 | 说明 |
|:---|:---|:---|
| **Vendor** | `vendor/android-compose/dex/compose-shell.dex` 存在 | resolve 直接加载；须通过 vendor 层门禁（若 class 数足够） |
| **Bootstrap** | 缺 shell | Rust `merge_class_sets` 自举 stub |

> 重要：**普通用户不需要**配置 `ANDROID_HOME` / `KOTLIN_HOME`。
> 只有维护者生成 `compose-shell.dex` 时，脚本才会使用 Android SDK（`d8`）与 Kotlin 编译器（`kotlinc`）。
> 维护者：`scripts/build-android-vendor-dex.ps1`（无 SDK 时写 bootstrap shell；有 SDK + libs 时 kotlinc+d8）。

## 与 AOT 原则的关系

门禁表是 [AOT 原则](aot-principles.md) 的可执行子集：R5 单一制品 → G-MAG-*；禁止 NDK/C → G-NO-ANDROID-C；JNI-in-SO → G-JNI-SYM。新增平台行为须先增 Gate ID 与测试，再改实现。

## 相关文档

- [AOT 原则](aot-principles.md)
- [Android APK](../platforms/android-apk.md)
- [Asgard UI v1 契约](asgard-ui-v1-contract.md)
