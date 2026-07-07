# asgard.plotter

Asgard 侧绘图 UI 壳：把 `plotter` 几何接到页面或报告。

交互只允许 **asgard auto glue**（`boot.js` + `c/*.js` 调 WASM）；禁止手写业务 JS。

## Widgets

| 组件 | 路径 | Props |
|:---|:---|:---|
| `Plot` | `source/components/plot.awsl` | `svg_html`, `width` |
| `PlotCard` | `source/components/plot-card.awsl` | `title`, `subtitle`, `footer`, `svg_html`, `variant` |
| `PlotGrid` | `source/components/plot-grid.awsl` | `columns`, `items[{title,svg_html}]` |
| `InteractiveColPlot` | `source/components/interactive-col-plot.awsl` | `title`, `series[{key,label,value_text,fill,height_pct}]` |

`InteractiveColPlot` 用 `on:click` + `<script>` micros（pin / toggle / tooltip），由 voa hydrate 编入 WASM。

## Helpers

`source/helpers.v`：

- `col_series_items(keys, labels, values, fills, unit)` — 交互柱图 series
- `plot_col_svg` / `plot_line_svg` / `plot_histogram_svg` — 静态 SVG

## Showcase

见 [`examples/test.plotter`](../../examples/test.plotter/)：`InteractiveColPlot` + 静态 `PlotCard`。
