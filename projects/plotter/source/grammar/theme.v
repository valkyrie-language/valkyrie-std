namespace plotter;

# theme_id: 0=minimal, 1=void

micro theme_minimal(spec: PlotSpec) -> PlotSpec {
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
        theme_id: 0,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: true,
        show_axis: true,
        margin: spec.margin,
        facet_by: spec.facet_by
    }
}

micro theme_void(spec: PlotSpec) -> PlotSpec {
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
        theme_id: 1,
        x_continuous: spec.x_continuous,
        y_continuous: spec.y_continuous,
        x_discrete: spec.x_discrete,
        y_discrete: spec.y_discrete,
        show_grid: false,
        show_axis: false,
        margin: PlotMargin {
            top: 16.0,
            right: 16.0,
            bottom: 16.0,
            left: 16.0
        },
        facet_by: spec.facet_by
    }
}
