# PlotSpec 外部接入契约

供 `legion` 报告或其他宿主生成声明式图规格后，调用 Valkyrie `plotter`（或临时 fallback）渲染 SVG。

## JSON 形状（`plot_spec_to_json`）

```json
{
  "width": 720,
  "height": 360,
  "title": "Bench Runtime",
  "subtitle": "",
  "x_lab": "Target",
  "y_lab": "ms",
  "theme_id": 0,
  "aes": { "x": "target", "y": "runtime_ms", "fill": "project", "color": "", "size": "" },
  "scales": {
    "x_continuous": false,
    "y_continuous": true,
    "x_discrete": true,
    "y_discrete": false
  },
  "geoms": [
    { "kind": "col", "bins": 0, "intercept": 0.0 }
  ],
  "data": {
    "row_count": 3,
    "columns": [
      { "name": "target", "is_numeric": false, "length": 3 },
      { "name": "runtime_ms", "is_numeric": true, "length": 3 }
    ]
  }
}
```

## geom.kind 枚举

| kind | 含义 |
|:---|:---|
| `col` / `bar` | 柱形 |
| `point` | 散点 |
| `line` | 折线 |
| `histogram` | 直方图（使用 `bins`） |
| `hline` / `vline` | 参考线（使用 `intercept`） |

## theme_id

| id | 含义 |
|:---|:---|
| `0` | minimal（网格 + 坐标轴） |
| `1` | void（无网格无坐标轴） |

## 宿主推荐流程

1. 把报告统计整理成列（labels + numbers）
2. 填 `aes` / `geoms` / `labs`
3. 调 Valkyrie/`nyar` 执行 `render_svg`，或本地实现同 schema 的轻量 SVG fallback
4. 将 SVG 字符串注入 `asgard.plotter` 的 `Plot` / `PlotCard`，或 Legion 报告模板槽位

完整单元格数据当前由 Valkyrie 侧 `DataFrame` 持有；外部 JSON 契约首期只携带列元信息。需要跨进程全量数据时，可另附 `series` 数组扩展字段：

```json
"series": [
  { "name": "target", "labels": ["nyar", "clr"] },
  { "name": "runtime_ms", "numbers": [1.8, 0.4] }
]
```
