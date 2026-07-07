# Android APK（Asgard + VOA）

Android 的 **唯一逻辑制品** 是 `classes.dex`：native AOT 与 asgard ui wire **均编入 dex 尾段**（`ASGARDNT` + asgard ui）。**无** 独立 `ui.bin`、`libasgard_host.so`、**无** 外部 C/NDK 链接步骤。见 [AOT 原则](../architecture/aot-principles.md) 与 [平台契约硬门禁](../architecture/platform-contract.md)。

## 流程

1. `platform: "android"`，`target: aarch64-linux-android`
2. `asgard build` → `dist/android/classes.dex` + `AndroidManifest.xml`
3. `asgard pack --target apk`

JVM 壳（`AsgardHostBridge` / `MainActivity`）编入 `classes.dex`；`ASGARDNT` 段内 ET_DYN `.so` **自包含** `JNI_OnLoad` + `asgard_invoke_export`。运行时 `System.load` 抽出 `.so` 即可。

## Release dist

| 内容 | 说明 |
|:---|:---|
| `classes.dex` | JVM 壳 class + **尾段嵌入**（native `.so` + UI wire） |
| `AndroidManifest.xml` | 包元数据 |

**无** `lib/`、`native/*.c`、`ui.bin`、用户 Kotlin 工程。`asgard build` 结束即可 `asgard pack --target apk`。

## 硬门禁（pack 前）

| Gate | 检查 |
|:---|:---|
| G-MAG-UI / G-MAG-NT | dex 尾段魔数 |
| G-NO-LEGACY | 无占位 magic |
| G-NO-ANDROID-C | dist 无 `native/*.c` |
| G-ANDROID-COMPOSE | dex class_defs + Compose 运行时符号 |
| G-JNI-SYM | `ASGARDNT` 内 `.so` 导出 JNI 符号 |

`asgard pack` 调用 `validate_android_dist_bytes`；失败时错误含 `G-*` ID。

## Compose 后端

> 重要：**普通用户不需要**配置 `ANDROID_HOME` / `KOTLIN_HOME`。`asgard build`/`asgard pack` 不会调用任何 Android SDK / Kotlin 工具链。
> 只有“维护者要生成真机可运行的 Vendor Compose dex（`compose-shell.dex`）”才需要按下文配置。

| 模式 | 条件 | 说明 |
|:---|:---|:---|
| **Vendor** | `vendor/android-compose/dex/compose-shell.dex` 存在 | `resolve_android_compose_dex` 直接加载；SDK 编译须通过 vendor 层门禁 |
| **Bootstrap** | shell 缺失 | Rust 自举 stub（CI / 门禁）；**非**完整 Compose |

维护者生成 vendor dex：`scripts/build-android-vendor-dex.ps1`

- 无 `ANDROID_HOME`：写 bootstrap `compose-shell.dex`
- 有 SDK：写出 Kotlin 源 → `kotlinc` + `d8`（需 `vendor/android-compose/libs/*.jar`）→ `compose-shell.dex` + `build-report.json`（sha256）

## APK 最小安装性

`asgard pack` 写入：

- `classes.dex`、`AndroidManifest.xml`
- 最小 `resources.arsc`（空 resource 表，满足 aapt 结构）
- `META-INF/MANIFEST.MF` + `CERT.SF` + `CERT.RSA`（**debug 占位签名**，仅供结构验证；上架须替换为正式签名）

示例：`examples/demo.android/`。
