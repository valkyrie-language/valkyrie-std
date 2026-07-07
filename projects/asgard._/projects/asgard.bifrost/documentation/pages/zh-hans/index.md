# Asgard Bifrost

`asgard.bifrost` 是 Asgard 的跨平台自绘渲染引擎，负责提供原生控件方案之外的统一自绘后端。

## 目标

- 提供像素级一致的跨平台渲染结果
- 摆脱平台原生控件与 WebView 差异带来的 UI 不一致
- 为复杂动画、自定义组件、高刷新率交互提供稳定后端
- 与 `asgard.ui` 共享视图树、主题、事件与布局契约
- 与 `gnosis` 共享 GPU / text / layout / render 底座

## 在 Asgard 中的位置

- `asgard`：框架层，定义 AWSL / widget / 交付模型
- `asgard.ui`：共享 UI 契约与运行时抽象
- `asgard.bifrost`：自绘渲染后端

## 依赖的共享图形栈

- `gnosis.layout`：布局约束、测量协议、scroll viewport
- `gnosis.text`：字体发现、fallback、text shaping、glyph atlas
- `gnosis.render`：draw list、frame graph、batched draw
- `gnosis.gpu`：device、queue、buffer、texture、pipeline、sync

相关总文档见：[公共图形栈](../../../../../../documentation/pages/zh-hans/developer/graphics-stack.md)

## 设计原则

- 不直接复刻现成框架的 API 表面
- 只吸收成熟方案里在自绘渲染、声明式 UI 和运行时组织上的优秀设计
- 保持 Asgard 现有“原生优先”主线不变，把 Bifrost 作为并行后端
- 不让自绘后端反向污染 AWSL 语义层
