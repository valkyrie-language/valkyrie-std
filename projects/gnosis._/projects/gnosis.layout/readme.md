# gnosis.layout

HUD 最小布局包，提供文本测量、widget 排列、锚点定位与 HUD 组件布局，
用于稳定显示血条 / XP 条 / cooldown widget 与浮字位置。

## 设计目标

- 最小布局面：MeasureResult / Arranger / AnchorLayout / HudLayout
- 不依赖 GPU / 渲染层，仅基于像素度量做纯布局计算
- 支持数字、短标签、波次标题的文本测量
- 支持血条 / XP 条 / cooldown widget 的测量与排列

## 文件布局

| 文件 | 职责 |
|------|------|
| `source/measure.v` | FontMetrics / MeasureResult / measure_text / MeasureWidget trait |
| `source/arrange.v` | Rect / Constraint / Arranger：按约束框排版 widget |
| `source/anchor_layout.v` | Anchor 枚举 / AnchorLayout：按锚点定位 widget |
| `source/hud_layout.v` | HudLayout / HudSlot：组合 bar / widget 布局 |

## 能力清单

- measure_text 按等宽度量计算文本宽高
- MeasureWidget trait 统一 widget 自测接口
- Arranger 在约束矩形内排列多个 widget（横向 / 纵向，居中对齐）
- AnchorLayout 按 9 种锚点将 widget 定位到容器内
- HudLayout 组合血条 / XP 条 / cooldown widget 的测量与排列

## 上游依赖

- 仅 core / std，不依赖 GPU / 渲染层

## 不在范围内

- 复杂排版（换行 / 富文本 / bidi）
- 动画与过渡
- 输入命中测试
