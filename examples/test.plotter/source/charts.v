namespace test.plotter;

using plotter;
using asgard.plotter;

# Showcase：plotter 出几何 / 静态 SVG；InteractiveColPlot 走 asgard glue 交互。

micro status_chart_series() -> [ColSeriesItem] {
    return col_series_items(
        ["pass", "fail", "skip"],
        ["pass", "fail", "skip"],
        [14.0, 2.0, 3.0],
        ["#22c55e", "#ef4444", "#f97316"],
        "tests"
    )
}

micro bench_chart_series() -> [ColSeriesItem] {
    return col_series_items(
        ["nyar", "clr", "jvm", "node"],
        ["nyar", "clr", "jvm", "node"],
        [1.8, 0.4, 8.1, 3.2],
        ["#3873ad", "#22c55e", "#ef4444", "#f97316"],
        "ms"
    )
}

micro status_chart_svg() -> utf8 {
    let labels: [utf8] = ["pass", "fail", "skip"]
    let values: [f64] = [14.0, 2.0, 3.0]
    let data: DataFrame = empty_dataframe()
    let with_x: DataFrame = dataframe_add_categorical(data, "status", labels)
    let with_y: DataFrame = dataframe_add_numeric(with_x, "count", values)
    return with_y
        |> plot()
        |> aes_fill("status", "count", "status")
        |> geom_col()
        |> scale_y_continuous()
        |> labs("Test Status", "status", "count")
        |> theme_minimal()
        |> with_size(640.0, 280.0)
        |> render_svg()
}

micro bench_chart_svg() -> utf8 {
    return plot_col_svg(
        ["nyar", "clr", "jvm", "node"],
        [1.8, 0.4, 8.1, 3.2],
        "Bench Runtime (ms)",
        "Target",
        "ms"
    )
}

micro trend_chart_svg() -> utf8 {
    return plot_line_svg(
        ["w1", "w2", "w3", "w4", "w5"],
        [42.0, 55.0, 48.0, 70.0, 66.0],
        "Coverage Trend (%)"
    )
}

micro latency_histogram_svg() -> utf8 {
    return plot_histogram_svg(
        [12.0, 15.0, 14.0, 30.0, 31.0, 29.0, 50.0, 52.0, 80.0, 82.0, 81.0],
        5,
        "Latency Histogram"
    )
}
