namespace plotter;

# PlotSpec：不可变图层规格。管道函数返回新的 spec。

# GeomKind: 0=col, 1=bar, 2=point, 3=line, 4=histogram, 5=hline, 6=vline
structure GeomLayer {
    kind: i32
    bins: i32
    intercept: f64
}

structure AesMapping {
    x: utf8
    y: utf8
    fill: utf8
    color: utf8
    size: utf8
}

structure PlotMargin {
    top: f64
    right: f64
    bottom: f64
    left: f64
}

structure PlotSpec {
    data: DataFrame
    aes: AesMapping
    geoms: [GeomLayer]
    title: utf8
    subtitle: utf8
    x_lab: utf8
    y_lab: utf8
    width: f64
    height: f64
    theme_id: i32
    x_continuous: bool
    y_continuous: bool
    x_discrete: bool
    y_discrete: bool
    show_grid: bool
    show_axis: bool
    margin: PlotMargin
    facet_by: utf8
}

micro empty_aes() -> AesMapping {
    return AesMapping {
        x: "",
        y: "",
        fill: "",
        color: "",
        size: ""
    }
}

micro default_margin() -> PlotMargin {
    return PlotMargin {
        top: 48.0,
        right: 24.0,
        bottom: 48.0,
        left: 56.0
    }
}

micro plot(data: DataFrame) -> PlotSpec {
    return PlotSpec {
        data: data,
        aes: empty_aes(),
        geoms: [],
        title: "",
        subtitle: "",
        x_lab: "",
        y_lab: "",
        width: 720.0,
        height: 360.0,
        theme_id: 0,
        x_continuous: false,
        y_continuous: true,
        x_discrete: true,
        y_discrete: false,
        show_grid: true,
        show_axis: true,
        margin: default_margin(),
        facet_by: ""
    }
}

micro with_size(spec: PlotSpec, width: f64, height: f64) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: spec.geoms,
        title: spec.title,
        subtitle: spec.subtitle,
        x_lab: spec.x_lab,
        y_lab: spec.y_lab,
        width: width,
        height: height,
        theme_id: spec.theme_id,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: spec.show_grid,
        show_axis: spec.show_axis,
        margin: spec.margin,
        facet_by: spec.facet_by
    }
}

micro clone_spec_with_aes(spec: PlotSpec, aes: AesMapping) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: aes,
        geoms: spec.geoms,
        title: spec.title,
        subtitle: spec.subtitle,
        x_lab: spec.x_lab,
        y_lab: spec.y_lab,
        width: spec.width,
        height: spec.height,
        theme_id: spec.theme_id,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: spec.show_grid,
        show_axis: spec.show_axis,
        margin: spec.margin,
        facet_by: spec.facet_by
    }
}

micro clone_spec_with_geoms(spec: PlotSpec, geoms: [GeomLayer]) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: geoms,
        title: spec.title,
        subtitle: spec.subtitle,
        x_lab: spec.x_lab,
        y_lab: spec.y_lab,
        width: spec.width,
        height: spec.height,
        theme_id: spec.theme_id,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: spec.show_grid,
        show_axis: spec.show_axis,
        margin: spec.margin,
        facet_by: spec.facet_by
    }
}

micro clone_spec_scales(spec: PlotSpec, x_continuous: bool, y_continuous: bool, x_discrete: bool, y_discrete: bool) -> PlotSpec {
    return PlotSpec {
        data: spec.data,
        aes: spec.aes,
        geoms: spec.geoms,
        title: spec.title,
        subtitle: spec.subtitle,
        x_lab: spec.x_lab,
        y_lab: spec.y_lab,
        width: spec.width,
        height: spec.height,
        theme_id: spec.theme_id,
        x_continuous: x_continuous,
        y_continuous: y_continuous,
        x_discrete: x_discrete,
        y_discrete: y_discrete,
        show_grid: spec.show_grid,
        show_axis: spec.show_axis,
        margin: spec.margin,
        facet_by: spec.facet_by
    }
}
