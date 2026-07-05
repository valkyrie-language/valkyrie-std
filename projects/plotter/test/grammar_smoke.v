namespace plotter;

[test]
micro builds_col_plot_spec() -> unit {
    let labels: [utf8] = ["nyar", "clr", "jvm"]
    let values: [f64] = [1.8, 0.4, 8.1]
    let data: DataFrame = dataframe_from_xy(labels, values)
    let spec: PlotSpec = plot(data)
    let mapped: PlotSpec = aes(spec, "x", "y")
    let with_geom: PlotSpec = geom_col(mapped)
    let with_scale: PlotSpec = scale_y_continuous(with_geom)
    let with_labs: PlotSpec = labs(with_scale, "Bench Runtime", "Target", "ms")
    let themed: PlotSpec = theme_minimal(with_labs)
    if themed.geoms.length() != 1 {
        panic("expected one geom layer")
    }
    if !themed.title.equals("Bench Runtime") {
        panic("title mismatch")
    }
}

[test]
micro render_svg_contains_root() -> unit {
    let labels: [utf8] = ["pass", "fail", "skip"]
    let values: [f64] = [12.0, 3.0, 2.0]
    let data: DataFrame = dataframe_from_xy(labels, values)
    let svg: utf8 = data
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> labs("Test Status", "status", "count")
        |> theme_minimal()
        |> render_svg()
    if !svg.contains("<svg") {
        panic("missing svg root")
    }
    if !svg.contains("</svg>") {
        panic("missing svg close")
    }
    if !svg.contains("<rect") {
        panic("missing rect marks")
    }
}

[test]
micro render_line_and_point() -> unit {
    let labels: [utf8] = ["t0", "t1", "t2", "t3"]
    let values: [f64] = [1.0, 3.0, 2.0, 5.0]
    let data: DataFrame = dataframe_from_xy(labels, values)
    let svg: utf8 = data
        |> plot()
        |> aes("x", "y")
        |> geom_line()
        |> geom_point()
        |> render_svg()
    if !svg.contains("<path") {
        panic("missing path for line")
    }
    if !svg.contains("<circle") {
        panic("missing circle for points")
    }
}

[test]
micro histogram_emits_rects() -> unit {
    let data: DataFrame = empty_dataframe()
    let with_x: DataFrame = dataframe_add_numeric(data, "x", [1.0, 1.2, 1.1, 3.0, 3.2, 5.0, 5.1, 5.5])
    let svg: utf8 = with_x
        |> plot()
        |> aes("x", "")
        |> geom_histogram(4)
        |> theme_minimal()
        |> render_svg()
    if !svg.contains("<rect") {
        panic("histogram should emit rects")
    }
}

[test]
micro plot_spec_json_contract() -> unit {
    let data: DataFrame = dataframe_from_xy(["a", "b"], [1.0, 2.0])
    let spec: PlotSpec = data
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> labs("Demo", "x", "y")
    let json: utf8 = plot_spec_to_json(spec)
    if !json.contains("\"geoms\"") {
        panic("json missing geoms")
    }
    if !json.contains("\"col\"") {
        panic("json missing col kind")
    }
    if !json.contains("\"title\":\"Demo\"") {
        panic("json missing title")
    }
}
