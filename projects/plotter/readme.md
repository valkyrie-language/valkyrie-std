# plotter

Valkyrie 图形语法库：ggplot2 心智、不可变 `PlotSpec`、管道 `|>`、SVG 优先出图。

C# `Sonic.Plotter` 仅为实验参考，本库不移植其 API。

## 快速开始

```v
let svg = dataframe_from_xy(["nyar", "clr"], [1.8, 0.4])
    |> plot()
    |> aes("x", "y")
    |> geom_col()
    |> labs("Bench", "Target", "ms")
    |> theme_minimal()
    |> render_svg()
```

## 模块

| 路径 | 内容 |
|:---|:---|
| `source/data/` | DataFrame / Column |
| `source/grammar/` | plot / aes / geom / scale / coord / theme / labs |
| `source/scene/` | Mark / PlotScene |
| `source/render/` | `render_svg` |
| `source/serialize.v` | PlotSpec JSON/von 契约 |

## 文档

- [ggplot2 对照](documentation/pages/zh-hans/ggplot2.md)
- [外部接入契约](documentation/pages/zh-hans/contract.md)

## UI 壳

见同 workspace 的 `asgard.plotter`（`Plot` / `PlotCard` / `PlotGrid`）。
