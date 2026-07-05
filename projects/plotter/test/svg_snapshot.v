namespace plotter;

[test]
micro svg_has_axes_and_title() -> unit {
    let data: DataFrame = dataframe_from_xy(["x1", "x2"], [10.0, 20.0])
    let svg: utf8 = data
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> labs("Coverage Features", "feature", "count")
        |> theme_minimal()
        |> with_size(640.0, 320.0)
        |> render_svg()

    if !svg.contains("Coverage Features") {
        panic("title missing in svg text")
    }
    if !svg.contains("<line") {
        panic("axes/grid lines missing")
    }
    if !svg.contains("width=\"640") {
        panic("width attribute missing")
    }
}

[test]
micro theme_void_hides_axes() -> unit {
    let data: DataFrame = dataframe_from_xy(["a"], [1.0])
    let scene_minimal: PlotScene = data
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> theme_minimal()
        |> build_scene()
    let scene_void: PlotScene = data
        |> plot()
        |> aes("x", "y")
        |> geom_col()
        |> theme_void()
        |> build_scene()
    if scene_void.marks.length() >= scene_minimal.marks.length() {
        panic("void theme should emit fewer marks")
    }
}
