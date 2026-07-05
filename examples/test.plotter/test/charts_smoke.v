namespace test.plotter::test;

using asgard.plotter;

[test]
micro status_chart_is_svg() -> unit {
    let svg: utf8 = status_chart_svg()
    if !svg.contains("<svg") {
        panic("status chart missing svg")
    }
    if !svg.contains("<rect") {
        panic("status chart missing bars")
    }
}

[test]
micro status_series_has_items() -> unit {
    let items: [ColSeriesItem] = status_chart_series()
    if items.length() != 3 {
        panic("status series size")
    }
    if items[0].height_pct < 4.0 {
        panic("height floor")
    }
}

[test]
micro trend_chart_has_path() -> unit {
    let svg: utf8 = trend_chart_svg()
    if !svg.contains("<path") {
        panic("trend chart missing path")
    }
}
