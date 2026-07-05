# 微信小程序（Asgard / VOA）

Asgard 的长期目标是同一套 AWSL + V 逻辑，编译到 Web / 微信小程序 / Android / iOS 等宿主。UI 策略见 **[UI 渲染策略](../architecture/ui-rendering.md)** 与 **[统一编译架构](../architecture/gui-compilation.md)**：**平台原生优先**；自渲仅在小游戏 Canvas 等场景 **有限支持**。

**要点**：逻辑 AOT 为 **`*.wasm`**，**asgard ui** wire 编入同一 `.wasm` 尾段（魔数 `ASGARDUI`，8 字节）；`voa-runtime.js` 仅为 `WXWebAssembly` 加载与 setData shim。**无** `host/*.bin`，**禁止** JS 内嵌 `__ASGARD_PRODUCT__`。见 [AOT 原则](../architecture/aot-principles.md)。

## 小游戏 vs 小程序

| | 微信小游戏 | 微信小程序 |
|:---|:---|:---|
| `publish` | `mini-game` | `mini-program` |
| SDK | `tencent.wechat.sdk` | `tencent.wechat.miniprogram.sdk` |
| `sdk-vendor.host` | `wechat` | `wechat-miniprogram` |
| UI | 小游戏 / **Canvas（自渲，有限）** | WXML / WXSS（**原生**） |
| 逻辑 | 小游戏运行时字节码 | **`*.wasm`（AOT）** |
| RenderIR | 不适用本管线 | **asgard ui 尾段编入 `.wasm`** |
| VOA | 不走 VOA UI | `platform: wechat-miniprogram` |
| 打包 | `asgard pack --target mini-game` | `asgard pack --target mini-program` |

## 配置

`voa.config.v`（`target: wasm32-unknown-miniprogram-wasm`；独立 MP prelude，shim 适配微信）：

```von
{
    name: "demo.wechat.miniprogram",
    platform: "wechat-miniprogram",
    target: "wasm32-unknown-miniprogram-wasm",
    build: {
        output: "dist"
    }
}
```

`legion.von`：

```von
{
    name: "demo.wechat.miniprogram",
    build: [
        {
            target: "wasm32-unknown-miniprogram-wasm",
            publish: ["mini-program"]
        }
    ]
}
```

## 构建流程

```text
asgard build
  → dist/{name}.wasm（逻辑 AOT + asgard ui 尾段）
  → dist/voa-runtime.js（WXWebAssembly 加载 + wire 解码 + setData）
  → dist/app.json + pages/*（WXML/WXSS/JS）
asgard pack --target mini-program
  → 补齐 project.config.json / sitemap.json；校验 .wasm 含 asgard ui
微信开发者工具打开 dist
```

`asgard build` 默认使用 `voa.config.v` 的 `target`（`wasm32-unknown-miniprogram-wasm`）。

## 响应式模型（早期）

| Web | 小程序 |
|:---|:---|
| Solid 细粒度 DOM 绑定 | 粗粒度 `setData` |
| `textContent` / `appendChild` | 静态 WXML + `Page.setData` |
| `rxBindLoop` 等优化 | 首版全量重建子树描述 |

`setData` 有异步特征；早期允许粗粒度更新，后续再做 keyed diff。

## AWSL 能力子集

首版支持：

- 静态结构 → WXML
- `{expr}` 插值
- `on:click=handler` → `bind:tap`
- `<if>` → `wx:if`
- `<loop>` → `wx:for`
- `<style>` → `.wxss`（`1px = 2rpx`）

暂不保证 / 可能降级：

- `@ref` 与 DOM 句柄
- HTML 特有标签（映射为 `view` / `text`）
- 细粒度列表 keyed diff

## 示例

见 `examples/demo.wechat.miniprogram`（单页计数器）。
