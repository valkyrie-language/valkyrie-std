# AOT 原则：禁止 VM on VM

V 是**多平台 AOT 编译语言**。Asgard 交付的应用逻辑必须保持**原生速度、原生 ABI 兼容**；不允许用「再套一层虚拟机」来跑用户代码。

**默认交付路径**：`platform: browser`（`wasm32-unknown-browser-wasm`）→ WASM 模块 + 引导页；开发时经 WebView 或浏览器加载。并列主产物为 `wechat-miniprogram`。Android / iOS / 桌面为扩展平台，见 [平台契约](platform-contract.md)。

## 硬规则

| # | 规则 | 说明 |
|:---:|:---|:---|
| R1 | **用户逻辑只 AOT 一次** | AWSL `<script>` / `.v` → 宿主**原生**或**浏览器 WASM 模块** |
| R2 | **禁止 VM on VM** | 用户逻辑不得落在「VM 里的 VM」上（例：V→JVM `.class`→ART 跑业务逻辑） |
| R3 | **UI 不是 VM** | Asgard UI wire 是**序列化视图树**；设备侧仅**原生 shim 解码 + 映射控件** |
| R4 | **`asgard.ui` 不进设备** | `projects/asgard.ui` 为**契约与金样例**；真机只跑预编译 shim |
| R5 | **每 platform 一份制品（矩阵）** | 逻辑 + UI wire + 元数据 **全部编入该 platform 交付物**；多平台 = 多制品 + deploy profile 选拓扑。**禁止**「一个二进制跑全平台」。**禁止**独立 `ui.bin`、`host.bin`、`host/*.bin`、`libasgard_host` 等侧车 |
| R6 | **Web / 小程序 WASM** | `browser` 与 `wechat-miniprogram` 走 WASM（沙箱内 AOT 模块）；小程序 UI 仍为 WXML + setData |

## 各平台「该平台唯一制品」

「唯一」指 **单个 platform 构建结果内** 不拆侧车，不是「全仓库只出一个二进制」。

| platform | Release 逻辑+元数据载体 | 禁止的侧车 |
|:---|:---|:---|
| `browser` | `*.wasm`（+ 引导用 `boot.js` / `index.html`） | 独立 `ui.bin` |
| `android` | `classes.dex` 尾段（`ASGARDNT` + asgard ui） | `lib/*.so`、`ui.bin`、`native/*.c` |
| `ios` | `AsgardHost` Mach-O 尾段 | `host.bin`、`ui.bin` |
| 桌面 | `{name}.exe` / ELF / Mach-O 尾段 | 独立 `ui.bin` |
| `wechat-miniprogram` | `*.wasm`（逻辑 + asgard ui 尾段）；`voa-runtime.js` 仅为加载 shim | `host/*.bin`、JS 内嵌产品 |

```text
同一业务源码
       │
       ├─ platform=browser  →  browser 制品
       ├─ platform=android  →  android 制品
       └─ …（矩阵；deploy profile 选用子集）
              │
              ▼
        该 platform 制品（尾段嵌入逻辑 + UI）
              ├─ ASGARDNT（native AOT，若适用）
              └─ asgard ui（`ASGARDUI`）
              │
              ▼
        原生 shim 解码 UI + FFI 回调 AOT 导出
```

## 禁止 vs 允许

| 禁止 | 允许 |
|:---|:---|
| 独立 `host/foo.bin` | 小程序逻辑+UI 在 `*.wasm`；`voa-runtime.js` 薄加载 |
| `libasgard_host.so` 等第二逻辑库 | Android 仅 `classes.dex` 尾段嵌入 |
| dist 交付 `.c` / `.h` 或要求 NDK 链接 | `ASGARDNT` 内 ET_DYN 自包含 JNI 胶水 |
| V 业务逻辑 → DEX → ART | native AOT 尾段 + JVM **壳**（无用户逻辑） |
| shim 内执行业务语义 | 事件 → `invokeExport` → AOT |
| JS 内嵌 `__ASGARD_PRODUCT__` 大数组 | `WXWebAssembly.instantiate` 加载 `.wasm` |

## 相关文档

- [统一编译架构](gui-compilation.md)
- [平台 target 表](platform-targets.md)
- [Deploy Profile](deploy-profiles.md)
- [Asgard UI v1 契约](asgard-ui-v1-contract.md)
- [**平台契约硬门禁**](platform-contract.md)（G-MAG-* / G-ANDROID-COMPOSE 等）
