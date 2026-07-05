# plotter 与 ggplot2 对照

Valkyrie `plotter` 借鉴 ggplot2 的图形语法心智，但用管道 `|>` 与不可变 `PlotSpec` 表达图层叠置。

| ggplot2 | plotter | 说明 |
|:---|:---|:---|
| `ggplot(data)` | `plot(data)` / `data \|> plot()` | 创建规格 |
| `aes(x, y, fill=…)` | `aes(spec, x, y)` / `aes_fill` / `aes_full` | 列名字符串绑定 |
| `+ geom_col()` | `\|> geom_col()` | 几何图层 |
| `+ geom_bar()` | `\|> geom_bar()` | 计数柱（当前与 col 同渲染） |
| `+ geom_point()` | `\|> geom_point()` | 散点 |
| `+ geom_line()` | `\|> geom_line()` | 折线 |
| `+ geom_histogram(bins=n)` | `\|> geom_histogram(n)` | 直方图 |
| `+ geom_hline(yintercept=)` | `\|> geom_hline(v)` | 水平参考线 |
| `+ geom_vline(xintercept=)` | `\|> geom_vline(v)` | 垂直参考线 |
| `+ scale_x_continuous()` | `\|> scale_x_continuous()` | 连续轴开关 |
| `+ scale_x_discrete()` | `\|> scale_x_discrete()` | 离散轴开关 |
| `+ labs(title, x, y)` | `\|> labs(title, x, y)` | 标题与轴标签 |
| `+ theme_minimal()` | `\|> theme_minimal()` | 网格 + 轴 |
| `theme_void()` | `\|> theme_void()` | 无轴无网格 |
| `ggsave` / 设备 | `\|> render_svg()` | 返回 SVG 字符串 |

## 最小示例

```v
let labels: [utf8] = ["nyar", "clr", "jvm"]
let values: [f64] = [1.8, 0.4, 8.1]
let svg: utf8 = dataframe_from_xy(labels, values)
    |> plot()
    |> aes("x", "y")
    |> geom_col()
    |> scale_y_continuous()
    |> labs("Bench Runtime", "Target", "ms")
    |> theme_minimal()
    |> render_svg()
```

## 接入契约

`plot_spec_to_json(spec)` / `plot_spec_to_von(spec)` 导出精简规格（宽高、aes、geom、数据列元信息），供 Rust Legion 等外部宿主填数后出图。详见同目录 `contract.md`。
