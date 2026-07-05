namespace asgard.plotter;

using plotter;

# InteractiveColPlot series 条目（交互在 AWSL script，非手写 JS）。
structure ColSeriesItem {
    key: utf8
    label: utf8
    value_text: utf8
    fill: utf8
    height_pct: f64
}

micro format_series_value(value: f64, unit: utf8) -> utf8 {
    if unit.equals("") {
        return format("{}", value)
    }
    return format("{} {}", value, unit)
}

micro col_series_items(keys: [utf8], labels: [utf8], values: [f64], fills: [utf8], unit: utf8) -> [ColSeriesItem] {
    let mut max_value: f64 = 1.0
    let mut index: usize = 0
    while index < values.length() {
        if values[index] > max_value {
            max_value = values[index]
        }
        index = index + 1
    }

    let mut items: [ColSeriesItem] = []
    index = 0
    while index < keys.length() {
        let value: f64 = if index < values.length() { values[index] } else { 0.0 }
        let pct: f64 = (value / max_value) * 100.0
        let height: f64 = if pct < 4.0 { 4.0 } else { pct }
        let fill: utf8 = if index < fills.length() { fills[index] } else { palette_color(index) }
        let label: utf8 = if index < labels.length() { labels[index] } else { keys[index] }
        push(items, ColSeriesItem {
            key: keys[index],
            label: label,
            value_text: format_series_value(value, unit),
            fill: fill,
            height_pct: height
        })
        index = index + 1
    }
    return items
}

# 便捷：从列数据直接生成可嵌入的 SVG HTML。

micro plot_col_svg(labels: [utf8], values: [f64], title: utf8, x_lab: utf8, y_lab: utf8) -> utf8 {
    return dataframe_from_xy(labels, values)
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> scale_y_continuous()
        |> labs(title, x_lab, y_lab)
        |> theme_minimal()
        |> render_svg()
}

micro plot_line_svg(labels: [utf8], values: [f64], title: utf8) -> utf8 {
    return dataframe_from_xy(labels, values)
        |> plot()
        |> aes("x", "y")
        |> geom_line()
        |> geom_point()
        |> labs(title, "x", "y")
        |> theme_minimal()
        |> render_svg()
}

micro plot_histogram_svg(values: [f64], bins: i32, title: utf8) -> utf8 {
    let data: DataFrame = dataframe_add_numeric(empty_dataframe(), "x", values)
    return data
        |> plot()
        |> aes("x", "")
        |> geom_histogram(bins)
        |> labs(title, "value", "count")
        |> theme_minimal()
        |> render_svg()
}
