# asgard.bifrost

`asgard.bifrost` 是 Asgard 的 **跨平台自绘渲染引擎**。

## 定位

- 作为 Asgard 在“平台原生优先”之外的第二条 UI 后端
- 面向跨平台像素级一致性、自绘动画、高级绘制与统一交互模型
- 依赖 `asgard.ui` / `asgard.ui.core` 的视图树与主题契约，而不是重新发明一套 GUI 语义
- 底层直接复用 `gnosis.layout`、`gnosis.text`、`gnosis.render`、`gnosis.gpu`

## 与 Asgard 主线的关系

- `asgard`：GUI 框架与 AWSL 表面语法
- `asgard.ui`：共享 UI 契约、视图树与运行时抽象
- `asgard.bifrost`：自绘渲染后端

## 与公共图形栈的关系

`asgard.bifrost` 自己不维护第二套图形底座：

- 用 `gnosis.layout` 解决 constraints、intrinsic size、scroll viewport
- 用 `gnosis.text` 解决字体、fallback、text shaping、glyph atlas
- 用 `gnosis.render` + `gnosis.gpu` 解决绘制命令、frame submission 与 GPU resource

它自己只负责把 `asgard.ui` 视图树翻译成布局树、命中测试与 GUI 渲染命令。

## 适用场景

- 需要像素级一致性的跨平台 UI
- 不希望受平台原生控件差异影响的复杂界面
- 高动画密度、高刷新率、自定义组件比例高的应用
- 需要在桌面、移动与部分受限宿主之间共享同一套绘制模型的场景

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
